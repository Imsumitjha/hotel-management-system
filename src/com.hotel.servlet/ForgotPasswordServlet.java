package com.hotel.servlet;

import com.hotel.util.DBConnection;
import com.hotel.util.ResetTokenUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ForgotPasswordServlet — step 1 of the password-reset flow.
 *
 * <h3>GET /ForgotPasswordServlet</h3>
 * Redirects to {@code forgot-password.jsp}.
 *
 * <h3>POST /ForgotPasswordServlet</h3>
 * <ol>
 *   <li>Validates the submitted email address.</li>
 *   <li>Looks up the user in the {@code users} table.</li>
 *   <li>If found, generates a cryptographically secure 64-character hex token
 *       using {@link SecureRandom}, saves it to {@code password_reset_tokens}
 *       with a 60-minute expiry, and sends the reset email.</li>
 *   <li>Whether or not the email exists, the response is identical —
 *       this prevents user-enumeration attacks.</li>
 *   <li>Forwards back to {@code forgot-password.jsp} with a
 *       {@code success} attribute containing the (masked) email address.</li>
 * </ol>
 *
 * <h3>Email sending</h3>
 * <p>This servlet uses the JavaMail API ({@code javax.mail}).
 * Add {@code javax.mail-1.6.x.jar} (or {@code jakarta.mail}) to
 * {@code WEB-INF/lib} and configure SMTP environment variables in the server.
 * For Gmail SMTP you must also enable "App Passwords" in your Google account.
 *
 * <h3>Database prerequisite</h3>
 * The {@code password_reset_tokens} table must exist — run the DDL added to
 * {@code hotel.sql}:
 * <pre>
 * CREATE TABLE password_reset_tokens (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id    INT         NOT NULL,
 *     token      VARCHAR(64) NOT NULL UNIQUE,
 *     expires_at TIMESTAMP   NOT NULL,
 *     used_at    TIMESTAMP   NULL DEFAULT NULL,
 *     created_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
 *     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
 * );
 * </pre>
 */
@WebServlet("/forgot")
public class ForgotPasswordServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ForgotPasswordServlet.class.getName());

    // ── SMTP configuration — update these before deploying ────────────────────
    private static final String SMTP_HOST_ENV = "HOTEL_SMTP_HOST";
    private static final String SMTP_PORT_ENV = "HOTEL_SMTP_PORT";
    private static final String SMTP_USER_ENV = "HOTEL_SMTP_USER";
    private static final String SMTP_PASSWORD_ENV = "HOTEL_SMTP_PASSWORD";
    private static final String SMTP_FROM_ENV = "HOTEL_SMTP_FROM";
    private static final String SMTP_FROM_NAME_ENV = "HOTEL_SMTP_FROM_NAME";
    private static final String PUBLIC_BASE_URL_ENV = "HOTEL_PUBLIC_BASE_URL";
    private static final String DEFAULT_SMTP_HOST = "smtp.gmail.com";
    private static final int DEFAULT_SMTP_PORT = 587;
    private static final String DEFAULT_FROM_NAME = "Grand Horizon Hotel";

    // ── Token settings ────────────────────────────────────────────────────────
    /** How long a reset token remains valid, in minutes. */
    private static final int    TOKEN_EXPIRY_MINUTES = 60;

    /** Number of random bytes → 64 hex characters. */
    private static final int    TOKEN_BYTES = 32;
    private static final int    RESET_LIMIT_PER_HOUR = 5;
    private static final long   RESET_LIMIT_WINDOW_MS = 60L * 60L * 1000L;
    private static final ConcurrentHashMap<String, RateWindow> RESET_LIMITS = new ConcurrentHashMap<>();

    // ── Email validation ──────────────────────────────────────────────────────
    private static final Pattern EMAIL_RE =
            Pattern.compile("^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$");

    // ── SQL ───────────────────────────────────────────────────────────────────

    private static final String SQL_FIND_USER =
            "SELECT id, first_name, email FROM users WHERE email = ? LIMIT 1";

    private static final String SQL_DELETE_EXPIRED_TOKENS =
            "DELETE FROM password_reset_tokens WHERE user_id = ? AND (expires_at <= NOW() OR used_at IS NOT NULL)";

    private static final String SQL_DELETE_TOKEN =
            "DELETE FROM password_reset_tokens WHERE token = ?";

    private static final String SQL_INSERT_TOKEN =
            "INSERT INTO password_reset_tokens (user_id, token, expires_at) " +
                    "VALUES (?, ?, ?)";

    // ── GET ───────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect(req.getContextPath() + "/forgot-password.jsp");
    }

    // ── POST ──────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String email = sanitise(req.getParameter("email")).toLowerCase(java.util.Locale.ROOT);

        // ── 1. Validate email format ──────────────────────────────────────────
        if (email.isEmpty() || !EMAIL_RE.matcher(email).matches()) {
            req.setAttribute("error", "Please enter a valid email address.");
            req.setAttribute("prefillEmail", email);
            req.getRequestDispatcher("/forgot-password.jsp").forward(req, resp);
            return;
        }

        if (isRateLimited(req.getRemoteAddr(), email)) {
            req.setAttribute("success", email);
            req.getRequestDispatcher("/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── 2. Look up user — but always show the same success response ───────
        //       (prevents enumeration: attacker cannot tell if the email exists)
        try (Connection conn = DBConnection.getConnection()) {

            int    userId    = -1;
            String firstName = null;

            try (PreparedStatement ps = conn.prepareStatement(SQL_FIND_USER)) {
                ps.setString(1, email);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    userId    = rs.getInt("id");
                    firstName = rs.getString("first_name");
                }
            }

            // ── 3. If user exists, generate token and send email ──────────────
            if (userId > 0) {

                // 3a. Generate a 64-char hex token via SecureRandom
                String token = generateToken();

                // Remove only expired tokens; an SMTP outage must not invalidate
                // a previously delivered, still-valid link.
                try (PreparedStatement ps = conn.prepareStatement(SQL_DELETE_EXPIRED_TOKENS)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // 3c. Persist the new token with its expiry
                Timestamp expiresAt = Timestamp.from(
                        Instant.now().plus(TOKEN_EXPIRY_MINUTES, ChronoUnit.MINUTES));

                String tokenHash = ResetTokenUtil.hash(token);
                try (PreparedStatement ps = conn.prepareStatement(SQL_INSERT_TOKEN)) {
                    ps.setInt      (1, userId);
                    ps.setString   (2, tokenHash);
                    ps.setTimestamp(3, expiresAt);
                    ps.executeUpdate();
                }

                LOG.info("Password reset token created — userId=" + userId);

                // 3e. Send the email (best-effort — failure must not reveal
                //     whether the address exists)
                try {
                    String resetUrl = buildResetUrl(token);
                    sendResetEmail(email, firstName, resetUrl);
                    LOG.info("Reset email sent to userId=" + userId);
                } catch (Exception e) {
                    // Log the error but do NOT surface it to the user
                    LOG.log(Level.SEVERE,
                            "Failed to send reset email to userId=" + userId, e);
                    try (PreparedStatement ps = conn.prepareStatement(SQL_DELETE_TOKEN)) {
                        ps.setString(1, tokenHash);
                        ps.executeUpdate();
                    } catch (SQLException cleanupError) {
                        LOG.log(Level.WARNING, "Could not invalidate undelivered reset token for userId=" + userId,
                                cleanupError);
                    }
                }
            } else {
                // User not found — log at FINE so we don't leak info
                LOG.fine("Password reset requested for unknown email: " + email);
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ForgotPasswordServlet DB error", e);
            // Still show success to avoid revealing error details
        }

        // ── 4. Always forward to success state — same for found & not found ───
        req.setAttribute("success", email);   // JSP uses this as the displayed email
        req.getRequestDispatcher("/forgot-password.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Token generation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Generates a cryptographically secure, URL-safe token.
     *
     * <p>Uses {@link SecureRandom} (the strongest available provider) to fill
     * {@value TOKEN_BYTES} random bytes, then encodes them as a lowercase
     * hexadecimal string — giving 64 characters and ~256 bits of entropy.
     *
     * @return a 64-character lowercase hex token string
     */
    private static String generateToken() {
        SecureRandom rng   = new SecureRandom();
        byte[]       bytes = new byte[TOKEN_BYTES];
        rng.nextBytes(bytes);
        StringBuilder sb = new StringBuilder(TOKEN_BYTES * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // URL builder
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Constructs the full reset URL that will be embedded in the email.
     *
     * <p>Example: {@code https://grandhorizon.in/reset?token=abc123...}
     */
    private static String buildResetUrl(String token) {
        String configured = System.getenv(PUBLIC_BASE_URL_ENV);
        if (configured == null || configured.trim().isEmpty()) {
            throw new IllegalStateException("Required environment variable is not set: " + PUBLIC_BASE_URL_ENV);
        }
        String base = configured.trim().replaceAll("/+$", "");
        try {
            URI uri = new URI(base);
            boolean localHttp = "http".equalsIgnoreCase(uri.getScheme())
                    && ("localhost".equalsIgnoreCase(uri.getHost()) || "127.0.0.1".equals(uri.getHost()));
            if ((!"https".equalsIgnoreCase(uri.getScheme()) && !localHttp)
                    || uri.getHost() == null || uri.getUserInfo() != null
                    || uri.getQuery() != null || uri.getFragment() != null) {
                throw new IllegalStateException(PUBLIC_BASE_URL_ENV + " must be an HTTPS site URL.");
            }
        } catch (URISyntaxException e) {
            throw new IllegalStateException(PUBLIC_BASE_URL_ENV + " is invalid.", e);
        }
        return base + "/reset?token=" + token;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Email sending
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Sends the HTML password-reset email using the JavaMail API.
     *
     * <p><strong>Setup required:</strong>
     * <ol>
     *   <li>Add {@code javax.mail-1.6.2.jar} to {@code WEB-INF/lib}.</li>
     *   <li>Set {@code HOTEL_SMTP_USER} and {@code HOTEL_SMTP_PASSWORD} in the
     *       hosting environment. The host defaults to Gmail on port 587; set
     *       {@code HOTEL_SMTP_HOST} and {@code HOTEL_SMTP_PORT} for another provider.</li>
     * </ol>
     *
     * @param toEmail   recipient email address
     * @param firstName recipient's first name, used in the greeting
     * @param resetUrl  the full token URL to embed in the email
     * @throws Exception if the message cannot be delivered
     */
    private void sendResetEmail(String toEmail,
                                String firstName,
                                String resetUrl) throws Exception {

        final String smtpUser = requiredEnvironmentValue(SMTP_USER_ENV, true);
        final String smtpPassword = requiredEnvironmentValue(SMTP_PASSWORD_ENV, false);
        final String smtpHost = optionalEnvironmentValue(SMTP_HOST_ENV, DEFAULT_SMTP_HOST);
        final String smtpPort = optionalEnvironmentValue(SMTP_PORT_ENV,
                String.valueOf(DEFAULT_SMTP_PORT));
        final int parsedPort;
        try {
            parsedPort = Integer.parseInt(smtpPort);
            if (parsedPort < 1 || parsedPort > 65535) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            throw new IllegalStateException("HOTEL_SMTP_PORT must be between 1 and 65535.");
        }
        final String fromAddress = optionalEnvironmentValue(SMTP_FROM_ENV, smtpUser);
        final String fromName = optionalEnvironmentValue(SMTP_FROM_NAME_ENV, DEFAULT_FROM_NAME);

        // JavaMail properties
        java.util.Properties props = new java.util.Properties();
        props.put("mail.smtp.auth",            "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.starttls.required", "true");
        props.put("mail.smtp.host",            smtpHost);
        props.put("mail.smtp.port",            String.valueOf(parsedPort));
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout",           "10000");
        props.put("mail.smtp.writetimeout",      "10000");

        // Authenticating session
        javax.mail.Session mailSession = javax.mail.Session.getInstance(props,
                new javax.mail.Authenticator() {
                    @Override
                    protected javax.mail.PasswordAuthentication getPasswordAuthentication() {
                        return new javax.mail.PasswordAuthentication(smtpUser, smtpPassword);
                    }
                });

        // Build the message
        javax.mail.Message msg = new javax.mail.internet.MimeMessage(mailSession);
        msg.setFrom(new javax.mail.internet.InternetAddress(fromAddress, fromName));
        msg.setRecipients(javax.mail.Message.RecipientType.TO,
                javax.mail.internet.InternetAddress.parse(toEmail));
        msg.setSubject("Reset your Grand Horizon password");
        msg.setSentDate(new java.util.Date());
        msg.setContent(buildEmailHtml(firstName, resetUrl), "text/html; charset=UTF-8");

        // Send
        javax.mail.Transport.send(msg);
    }

    private static String requiredEnvironmentValue(String name, boolean trim) {
        String value = System.getenv(name);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalStateException("Required email environment variable is not set: " + name);
        }
        return trim ? value.trim() : value;
    }

    private static String optionalEnvironmentValue(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? defaultValue : value.trim();
    }

    /**
     * Returns a styled HTML email body.
     * No external images — works reliably in all major email clients.
     */
    private static String buildEmailHtml(String firstName, String resetUrl) {
        String name = escapeHtml((firstName != null && !firstName.isEmpty()) ? firstName : "Valued Guest");
        return "<!DOCTYPE html>" +
                "<html lang='en'><head><meta charset='UTF-8'>" +
                "<meta name='viewport' content='width=device-width,initial-scale=1'>" +
                "<title>Reset your password</title></head>" +
                "<body style='margin:0;padding:0;background:#0a0a0f;font-family:Georgia,serif;'>" +
                "<table width='100%' cellpadding='0' cellspacing='0' border='0'" +
                " style='background:#0a0a0f;padding:40px 20px;'>" +
                "<tr><td align='center'>" +

                // Card
                "<table width='560' cellpadding='0' cellspacing='0' border='0'" +
                " style='background:#1c2230;border:1px solid #2a3347;" +
                "        border-radius:8px;overflow:hidden;'>" +

                // Header bar
                "<tr><td style='background:#0d1117;padding:28px 40px;" +
                "                border-bottom:1px solid #2a3347;text-align:center;'>" +
                "<p style='margin:0;font-size:22px;color:#e2c97e;letter-spacing:2px;'>" +
                "Grand Horizon</p>" +
                "<p style='margin:4px 0 0;font-size:10px;letter-spacing:4px;" +
                "          text-transform:uppercase;color:#6b6455;'>Luxury Hotel &amp; Suites</p>" +
                "</td></tr>" +

                // Separator line
                "<tr><td style='height:2px;background:linear-gradient(" +
                "90deg,transparent,#c8aa64,transparent);'></td></tr>" +

                // Body
                "<tr><td style='padding:40px 40px 32px;'>" +
                "<p style='margin:0 0 8px;font-size:11px;letter-spacing:3px;" +
                "          text-transform:uppercase;color:#c8aa64;'>Password Reset</p>" +
                "<h1 style='margin:0 0 20px;font-size:26px;font-weight:300;" +
                "           color:#f0ead8;line-height:1.3;'>Hello, " + name + "</h1>" +
                "<p style='margin:0 0 16px;font-size:15px;color:#b0a890;line-height:1.8;'>" +
                "We received a request to reset the password for your Grand Horizon " +
                "account. Click the button below to create a new password.</p>" +
                "<p style='margin:0 0 24px;font-size:14px;color:#6b6455;line-height:1.7;'>" +
                "This link will expire in <strong style='color:#f0ead8;'>60 minutes</strong>. " +
                "If you did not request a password reset, you can safely ignore this email " +
                "&mdash; your password will not change.</p>" +

                // CTA button
                "<table width='100%' cellpadding='0' cellspacing='0' border='0'" +
                " style='margin:0 0 32px;'>" +
                "<tr><td align='center'>" +
                "<a href='" + resetUrl + "'" +
                " style='display:inline-block;background:#c8aa64;color:#0a0a0f;" +
                "        text-decoration:none;padding:14px 40px;border-radius:4px;" +
                "        font-family:Arial,sans-serif;font-size:13px;" +
                "        font-weight:600;letter-spacing:2px;text-transform:uppercase;'>" +
                "Reset My Password</a>" +
                "</td></tr></table>" +

                // Fallback URL
                "<p style='margin:0 0 8px;font-size:12px;color:#6b6455;'>Or copy this link:</p>" +
                "<p style='margin:0;font-size:11px;color:#a08840;" +
                "          word-break:break-all;background:#141820;" +
                "          border:1px solid #2a3347;border-radius:4px;" +
                "          padding:10px 14px;'>" + resetUrl + "</p>" +
                "</td></tr>" +

                // Footer
                "<tr><td style='padding:20px 40px;border-top:1px solid #2a3347;" +
                "                background:#141820;text-align:center;'>" +
                "<p style='margin:0;font-size:11px;color:#6b6455;line-height:1.8;'>" +
                "Grand Horizon Hotel &mdash; 12, Palace Road, Amritsar, Punjab 143001<br>" +
                "If you need help, contact us at " +
                "<a href='mailto:stay@grandhorizon.in'" +
                " style='color:#a08840;'>stay@grandhorizon.in</a>" +
                "</p></td></tr>" +

                "</table>" + // end card
                "</td></tr></table>" + // end wrapper
                "</body></html>";
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static boolean isRateLimited(String ipAddress, String email) {
        long now = System.currentTimeMillis();
        String ipKey = "ip:" + ResetTokenUtil.hash(ipAddress == null ? "unknown" : ipAddress);
        String emailKey = "email:" + ResetTokenUtil.hash(email);
        boolean blocked = RESET_LIMITS.computeIfAbsent(ipKey, key -> new RateWindow())
                .tryAcquire(now, RESET_LIMIT_PER_HOUR, RESET_LIMIT_WINDOW_MS);
        blocked |= RESET_LIMITS.computeIfAbsent(emailKey, key -> new RateWindow())
                .tryAcquire(now, RESET_LIMIT_PER_HOUR, RESET_LIMIT_WINDOW_MS);
        if (RESET_LIMITS.size() > 10000) {
            RESET_LIMITS.entrySet().removeIf(entry -> now - entry.getValue().lastSeen > RESET_LIMIT_WINDOW_MS);
        }
        return blocked || RESET_LIMITS.size() > 10000;
    }

    private static String escapeHtml(String value) {
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    private static final class RateWindow {
        private long startedAt = 0L;
        private volatile long lastSeen = 0L;
        private int count = 0;

        private synchronized boolean tryAcquire(long now, int limit, long duration) {
            if (now - startedAt >= duration) {
                startedAt = now;
                count = 0;
            }
            lastSeen = now;
            if (count >= limit) return true;
            count++;
            return false;
        }
    }
}
