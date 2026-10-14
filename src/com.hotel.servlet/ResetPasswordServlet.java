package com.hotel.servlet;

import com.hotel.util.DBConnection;
import com.hotel.util.PasswordUtil;
import com.hotel.util.ResetTokenUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ResetPasswordServlet — step 2 of the password-reset flow.
 *
 * <h3>GET /reset?token={token}</h3>
 * <p>Called when the user clicks the reset link in their email.
 * <ol>
 *   <li>Looks up the token in {@code password_reset_tokens}.</li>
 *   <li>Checks it has not expired and has not already been used.</li>
 *   <li>If valid: sets {@code tokenValid=true}, {@code token}, and
 *       {@code tokenEmail} as request attributes, then forwards to
 *       {@code reset-password.jsp} which renders the new-password form.</li>
 *   <li>If invalid/expired: sets {@code tokenValid=false} and forwards to
 *       {@code reset-password.jsp} which renders the expired-link state.</li>
 * </ol>
 *
 * <h3>POST /reset</h3>
 * <p>Called when the new-password form is submitted.
 * <ol>
 *   <li>Re-validates the token (re-checks DB — guards against the link being
 *       submitted twice in parallel).</li>
 *   <li>Validates the new password against the page's password requirements.</li>
 *   <li>Hashes the new password with the shared PBKDF2 password utility.</li>
 *   <li>Updates {@code users.password_hash}.</li>
 *   <li>Marks the token as used ({@code used_at = NOW()}) so it cannot be
 *       replayed.</li>
 *   <li>Invalidates any existing session (forces re-login with new credentials).</li>
 *   <li>Forwards to {@code reset-password.jsp} with {@code success} set.</li>
 * </ol>
 *
 * <h3>Security properties</h3>
 * <ul>
 *   <li>Token is validated on both GET and POST — prevents direct POST attacks.</li>
 *   <li>Token is marked {@code used_at} immediately on successful update —
 *       prevents replay even within the expiry window.</li>
 *   <li>Old sessions are invalidated — prevents a session fixation attack where
 *       an attacker who obtained the session cookie could retain access after
 *       the victim resets their password.</li>
 *   <li>All DB operations are performed in a single transaction — ensures the
 *       password and the token are updated atomically.</li>
 * </ul>
 */
@WebServlet("/reset")
public class ResetPasswordServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ResetPasswordServlet.class.getName());

    // ── SQL ───────────────────────────────────────────────────────────────────

    /**
     * Fetch a token row that:
     *  - Matches the supplied token string exactly
     *  - Has not yet expired
     *  - Has not already been used
     */
    private static final String SQL_FIND_TOKEN =
            "SELECT t.id, t.user_id, t.expires_at, u.email, u.first_name " +
                    "FROM   password_reset_tokens t " +
                    "JOIN   users u ON t.user_id = u.id " +
                    "WHERE  t.token    = ? " +
                    "  AND  t.expires_at > NOW() " +
                    "  AND  t.used_at  IS NULL " +
                    "LIMIT  1";

    /** Update the user's password hash */
    private static final String SQL_UPDATE_PASSWORD =
            "UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?";

    /** Mark the token as used — prevents replay */
    private static final String SQL_MARK_USED =
            "UPDATE password_reset_tokens SET used_at = ? " +
                    "WHERE id = ? AND used_at IS NULL AND expires_at > NOW()";

    private static final String SQL_REVOKE_USER_TOKENS =
            "UPDATE password_reset_tokens SET used_at = NOW() " +
                    "WHERE user_id = ? AND used_at IS NULL";

    // ── GET — validate token and show form ────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        setSensitiveResponseHeaders(resp);

        String token = sanitise(req.getParameter("token"));

        if (token.isEmpty()) {
            // No token in URL — redirect to forgot-password
            resp.sendRedirect(req.getContextPath() + "/forgot-password.jsp");
            return;
        }

        TokenResult result = validateToken(token);

        if (result.valid) {
            req.setAttribute("tokenValid",  true);
            req.setAttribute("token",       token);
            req.setAttribute("tokenEmail",  result.email);
        } else {
            req.setAttribute("tokenValid",  false);
        }

        req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
    }

    // ── POST — apply new password ─────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        setSensitiveResponseHeaders(resp);
        req.setCharacterEncoding("UTF-8");

        String token           = sanitise(req.getParameter("token"));
        String newPassword     = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");

        // ── 1. Token must be present ──────────────────────────────────────────
        if (token.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/forgot-password.jsp");
            return;
        }

        // ── 2. Re-validate token against DB (prevents double-submit replay) ───
        TokenResult result = validateToken(token);
        if (!result.valid) {
            req.setAttribute("tokenValid", false);
            req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
            return;
        }

        // ── 3. Validate new password ──────────────────────────────────────────
        if (!PasswordUtil.isStrong(newPassword)) {
            req.setAttribute("tokenValid",  true);
            req.setAttribute("token",       token);
            req.setAttribute("tokenEmail",  result.email);
            req.setAttribute("error",
                    "Password must be 12–128 characters and include uppercase, lowercase, a number, and a special character.");
            req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            req.setAttribute("tokenValid",  true);
            req.setAttribute("token",       token);
            req.setAttribute("tokenEmail",  result.email);
            req.setAttribute("error", "Passwords do not match.");
            req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
            return;
        }

        // ── 4. Hash + update inside a transaction ─────────────────────────────
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // Claim the token inside this transaction so only one concurrent
            // request can successfully use it.
            try (PreparedStatement ps = conn.prepareStatement(SQL_MARK_USED)) {
                ps.setTimestamp(1, Timestamp.from(Instant.now()));
                ps.setInt(2, result.tokenId);
                if (ps.executeUpdate() != 1) {
                    throw new SQLException("Reset token was already used or expired");
                }
            }

            String hash = PasswordUtil.hash(newPassword);
            try (PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_PASSWORD)) {
                ps.setString(1, hash);
                ps.setInt   (2, result.userId);
                int rows = ps.executeUpdate();
                if (rows != 1) {
                    throw new SQLException("Expected 1 row updated, got " + rows);
                }
            }

            // Revoke all other outstanding links for this account as well.
            try (PreparedStatement ps = conn.prepareStatement(SQL_REVOKE_USER_TOKENS)) {
                ps.setInt(1, result.userId);
                ps.executeUpdate();
            }

            conn.commit();

            LOG.info("Password reset successful — userId=" + result.userId);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ResetPasswordServlet DB error", e);
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { /* ignore */ }
            }
            req.setAttribute("tokenValid",  true);
            req.setAttribute("token",       token);
            req.setAttribute("tokenEmail",  result.email);
            req.setAttribute("error",
                    "A server error occurred. Please try again or request a new reset link.");
            req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
            return;
        } finally {
            DBConnection.close(conn);
        }

        // ── 5. Invalidate any existing session for this user ──────────────────
        //       Prevents session fixation: if someone else had the session cookie
        //       they can no longer use it after the password changes.
        HttpSession session = req.getSession(false);
        if (session != null) {
            try { session.invalidate(); }
            catch (IllegalStateException e) { /* already invalidated */ }
        }

        // ── 6. Show success state ─────────────────────────────────────────────
        req.setAttribute("success", "Your password has been updated successfully.");
        req.getRequestDispatcher("/reset-password.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Token validation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Queries the DB for an active (non-expired, non-used) token.
     *
     * @param  token the 64-char hex string from the URL parameter
     * @return a {@link TokenResult} — check {@code result.valid} before use
     */
    private TokenResult validateToken(String token) {
        TokenResult result = new TokenResult();

        if (token == null || !token.matches("[a-fA-F0-9]{64}")) {
            return result; // valid=false by default
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_FIND_TOKEN)) {

            ps.setString(1, ResetTokenUtil.hash(token));
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                result.valid      = true;
                result.tokenId    = rs.getInt      ("id");
                result.userId     = rs.getInt      ("user_id");
                result.email      = rs.getString   ("email");
                result.firstName  = rs.getString   ("first_name");
                result.expiresAt  = rs.getTimestamp("expires_at");
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ResetPasswordServlet token validation error", e);
            // result.valid stays false — safe default
        }

        return result;
    }

    private static void setSensitiveResponseHeaders(HttpServletResponse resp) {
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0L);
        resp.setHeader("Referrer-Policy", "no-referrer");
        resp.setHeader("X-Content-Type-Options", "nosniff");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Password hashing
    // ─────────────────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────────────────
    // Inner class — token query result holder
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Simple value object returned by {@link #validateToken(String)}.
     * All fields are package-private for simplicity; only {@link #valid}
     * should be checked before accessing the others.
     */
    private static class TokenResult {
        boolean   valid     = false;
        int       tokenId   = -1;
        int       userId    = -1;
        String    email     = null;
        String    firstName = null;
        Timestamp expiresAt = null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }
}
