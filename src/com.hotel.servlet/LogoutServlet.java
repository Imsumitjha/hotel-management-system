package com.hotel.servlet;

import com.hotel.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * LogoutServlet — safely ends a user session for both guests and administrators.
 *
 * <h3>URL patterns</h3>
 * <ul>
 *   <li>{@code GET  /LogoutServlet}  — one-click logout link (e.g. sidebar "Sign Out")
 *   <li>{@code POST /LogoutServlet}  — form-based logout with optional CSRF token check
 * </ul>
 *
 * <h3>What this servlet does</h3>
 * <ol>
 *   <li>Reads role + userId from the current session <em>before</em> invalidating it,
 *       so the audit log entry and post-logout redirect destination are both correct.</li>
 *   <li>Writes a row to {@code audit_log} (if the table exists) recording who logged out,
 *       from which IP, and at what time.  The INSERT is best-effort — a failure here
 *       must never prevent the session from being destroyed.</li>
 *   <li>Calls {@link HttpSession#invalidate()} to destroy the session.</li>
 *   <li>Expires any "remember-me" cookie that may have been set at login.</li>
 *   <li>Sets {@code Cache-Control: no-store} so the browser cannot navigate back
 *       to a protected page using the Back button after logout.</li>
 *   <li>Redirects to the appropriate login page based on the role that was active.</li>
 * </ol>
 *
 * <h3>CSRF note</h3>
 * For POST requests, a CSRF token stored in the session under {@code csrfToken} is
 * validated against the {@code _csrf} form field.  A mismatch is logged as a warning
 * but the session is <em>still invalidated</em> — logging out is never the wrong thing
 * to do.  The mismatch is surfaced to the caller via a query-string flag so the UI can
 * show an appropriate message.
 *
 * <h3>Already-logged-out behaviour</h3>
 * If there is no active session (e.g. the user double-clicks the logout link) the
 * servlet simply redirects to the public home page without throwing an exception.
 */
@WebServlet(urlPatterns = {"/logout", "/LogoutServlet"})
public class LogoutServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(LogoutServlet.class.getName());

    /** Name of the remember-me cookie to expire on logout. */
    private static final String REMEMBER_ME_COOKIE = "gh_remember";

    /**
     * Best-effort audit INSERT.  The table DDL is:
     * <pre>
     * CREATE TABLE IF NOT EXISTS audit_log (
     *     id         INT          NOT NULL AUTO_INCREMENT,
     *     user_id    INT,
     *     user_email VARCHAR(150),
     *     action     VARCHAR(50)  NOT NULL,
     *     ip_address VARCHAR(45),
     *     user_agent VARCHAR(255),
     *     created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
     *     PRIMARY KEY (id),
     *     INDEX idx_audit_user   (user_id),
     *     INDEX idx_audit_action (action)
     * ) ENGINE=InnoDB;
     * </pre>
     */
    private static final String SQL_AUDIT_LOGOUT =
            "INSERT INTO audit_log (user_id, user_email, action, ip_address, user_agent, created_at) " +
                    "VALUES (?, ?, 'LOGOUT', ?, ?, ?)";

    // ── GET ── simple link-based logout ──────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processLogout(req, resp, false);
    }

    // ── POST ── form-based logout (with optional CSRF check) ─────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processLogout(req, resp, true);
    }

    // ── Core logout logic ────────────────────────────────────────────────────

    /**
     * Central logout handler shared by GET and POST.
     *
     * @param req          the current request
     * @param resp         the current response
     * @param verifyCsrf   {@code true} when called from POST — triggers CSRF check
     */
    private void processLogout(HttpServletRequest req,
                               HttpServletResponse resp,
                               boolean verifyCsrf)
            throws IOException {

        // ── 1. Prevent caching of any page the user navigates to after logout ──
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        resp.setHeader("Pragma",        "no-cache");
        resp.setDateHeader("Expires",   0);

        // ── 2. Read session (may be null if already expired / double-logout) ──
        HttpSession session = req.getSession(false);

        if (session == null) {
            // No active session — nothing to destroy; go home quietly
            LOG.fine("LogoutServlet called with no active session from IP: "
                    + getClientIp(req));
            resp.sendRedirect(req.getContextPath() + "/logout.jsp");
            return;
        }

        // ── 3. Capture session attributes BEFORE invalidating ─────────────────
        Integer userId    = (Integer) session.getAttribute("userId");
        String  userEmail = (String)  session.getAttribute("userEmail");
        String  userRole  = (String)  session.getAttribute("userRole");
        String  userName  = (String)  session.getAttribute("userName");

        // ── 4. CSRF token validation (POST path only) ─────────────────────────
        boolean csrfMismatch = false;
        if (verifyCsrf) {
            String sessionToken = (String) session.getAttribute("csrfToken");
            String formToken    = sanitise(req.getParameter("_csrf"));
            if (sessionToken != null && !sessionToken.equals(formToken)) {
                LOG.warning("CSRF mismatch on logout — userId=" + userId
                        + " IP=" + getClientIp(req)
                        + ". Proceeding with logout anyway.");
                csrfMismatch = true;
            }
        }

        // ── 5. Write audit log (best-effort — never block logout) ─────────────
        writeAuditLog(userId, userEmail, getClientIp(req), req.getHeader("User-Agent"));

        // ── 6. Invalidate the session ─────────────────────────────────────────
        try {
            session.invalidate();
            LOG.info("Session invalidated — user=" + userEmail
                    + " role=" + userRole
                    + " IP=" + getClientIp(req));
        } catch (IllegalStateException e) {
            // Session was already invalidated (concurrent request race) — safe to ignore
            LOG.fine("Session already invalidated: " + e.getMessage());
        }

        // ── 7. Expire the remember-me cookie ─────────────────────────────────
        expireCookie(resp, REMEMBER_ME_COOKIE, req.getContextPath());

        // ── 8. Determine redirect target ─────────────────────────────────────
        String redirectPath = buildRedirectPath(req, userRole, csrfMismatch);
        resp.sendRedirect(redirectPath);
    }

    // ── Audit log ─────────────────────────────────────────────────────────────

    /**
     * Writes a LOGOUT entry to {@code audit_log}.  Runs best-effort —
     * any {@link SQLException} is logged at WARNING level and swallowed
     * so it can never disrupt the logout flow.
     */
    private void writeAuditLog(Integer userId,
                               String  userEmail,
                               String  ipAddress,
                               String  userAgent) {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            try (PreparedStatement ps = conn.prepareStatement(SQL_AUDIT_LOGOUT)) {
                if (userId != null) {
                    ps.setInt(1, userId);
                } else {
                    ps.setNull(1, java.sql.Types.INTEGER);
                }
                ps.setString   (2, userEmail);
                ps.setString   (3, ipAddress);
                ps.setString   (4, userAgent != null
                        ? userAgent.substring(0, Math.min(userAgent.length(), 255))
                        : null);
                ps.setTimestamp(5, Timestamp.from(Instant.now()));
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            // Audit failure must never prevent logout
            LOG.log(Level.WARNING,
                    "Could not write logout audit entry for userId=" + userId
                            + ". The audit_log table may not yet exist — run hotel.sql first.", e);
        } finally {
            DBConnection.close(conn);
        }
    }

    // ── Cookie expiry ─────────────────────────────────────────────────────────

    /**
     * Sends a Set-Cookie header that overwrites the named cookie with an
     * empty value and {@code Max-Age=0}, causing the browser to delete it.
     */
    private void expireCookie(HttpServletResponse resp,
                              String cookieName,
                              String path) {
        Cookie expired = new Cookie(cookieName, "");
        expired.setMaxAge(0);
        expired.setPath(path.isEmpty() ? "/" : path);
        expired.setHttpOnly(true);
        // expired.setSecure(true); // uncomment when running under HTTPS
        resp.addCookie(expired);
    }

    // ── Redirect path ─────────────────────────────────────────────────────────

    /**
     * Determines the post-logout redirect URL.
     *
     * <ul>
     *   <li>Admins  → {@code /admin/admin-login.jsp?logout=true}
     *   <li>Guests  → {@code /login.jsp?logout=true}
     *   <li>Unknown → {@code /index.jsp}
     * </ul>
     *
     * A {@code csrf=1} query parameter is appended when a CSRF mismatch was
     * detected so the login page can optionally display a security notice.
     */
    private String buildRedirectPath(HttpServletRequest req,
                                     String userRole,
                                     boolean csrfMismatch) {
        String base = req.getContextPath();
        String csrfParam = csrfMismatch ? "?csrf=1" : "";
        return base + "/logout.jsp" + csrfParam;
    }

    // ── IP resolution ─────────────────────────────────────────────────────────

    /**
     * Extracts the real client IP, honouring common reverse-proxy headers
     * ({@code X-Forwarded-For}, {@code X-Real-IP}) before falling back to
     * {@link HttpServletRequest#getRemoteAddr()}.
     *
     * <p>Only the <em>first</em> value in {@code X-Forwarded-For} is used
     * (the originating client); intermediate proxies append their own IPs.
     */
    private static String getClientIp(HttpServletRequest req) {
        String xff = req.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isEmpty()) {
            return xff.split(",")[0].trim();
        }
        String xri = req.getHeader("X-Real-IP");
        if (xri != null && !xri.isEmpty()) {
            return xri.trim();
        }
        return req.getRemoteAddr();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }
}
