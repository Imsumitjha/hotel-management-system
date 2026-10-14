package com.hotel.servlet;

import com.hotel.util.DBConnection;

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
import java.sql.Statement;
import java.sql.Timestamp;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * ContactServlet — handles all operations on the {@code contact_messages} table.
 *
 * <h3>URL: {@code /contact}</h3>
 *
 * <h3>POST — public form submission (contact.jsp)</h3>
 * <p>Accepts the five fields from the contact form, runs server-side
 * validation, applies a per-IP rate limit, persists the message, and
 * redirects back to {@code contact.jsp} with a {@code success} or
 * {@code error} flash attribute.
 *
 * <h3>GET actions (admin only)</h3>
 * <table border="1">
 *   <tr><th>action</th><th>Description</th></tr>
 *   <tr><td>list&nbsp;(default)</td>
 *       <td>All messages, newest first → admin/manage-messages.jsp</td></tr>
 *   <tr><td>read</td>
 *       <td>Mark a message as read ({@code id} required)</td></tr>
 *   <tr><td>unread</td>
 *       <td>Mark a message as unread ({@code id} required)</td></tr>
 *   <tr><td>delete</td>
 *       <td>Hard-delete a message ({@code id} required)</td></tr>
 *   <tr><td>unreadCount</td>
 *       <td>Returns the unread count as plain text — for AJAX badge polling</td></tr>
 * </table>
 *
 * <h3>Spam / rate-limiting</h3>
 * <p>At most {@value #RATE_LIMIT_MAX} messages from the same IP address are
 * accepted within a {@value #RATE_LIMIT_WINDOW_MINUTES}-minute sliding window.
 * The check is a lightweight COUNT query against {@code contact_messages};
 * no external cache is required.
 */
@WebServlet("/contact")
public class ContactServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ContactServlet.class.getName());
    private static final String CSRF_ATTRIBUTE = "csrfToken";

    // ── Validation limits ─────────────────────────────────────────────────────
    private static final int    MAX_NAME_LEN    = 120;
    private static final int    MAX_EMAIL_LEN   = 150;
    private static final int    MAX_PHONE_LEN   = 20;
    private static final int    MAX_SUBJECT_LEN = 100;
    private static final int    MAX_MESSAGE_LEN = 3000;
    private static final int    MIN_MESSAGE_LEN = 10;

    /** Allowed subject values — guards against unexpected injected subjects. */
    private static final java.util.Set<String> VALID_SUBJECTS = new java.util.HashSet<>(
            java.util.Arrays.asList(
                    "General Inquiry", "Room Reservation", "Special Occasions",
                    "Corporate Events", "Feedback", "Other"
            )
    );

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$");

    // ── Rate-limit settings ───────────────────────────────────────────────────
    /** Maximum submissions allowed from one IP within the time window. */
    private static final int RATE_LIMIT_MAX = 3;

    /** Length of the sliding time window in minutes. */
    private static final int RATE_LIMIT_WINDOW_MINUTES = 60;

    // ── SQL ───────────────────────────────────────────────────────────────────

    private static final String SQL_INSERT =
            "INSERT INTO contact_messages (name, email, phone, subject, message, ip_address, is_read, created_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, 0, ?)";

    private static final String SQL_LIST_ALL =
            "SELECT id, name, email, phone, subject, message, is_read, created_at " +
                    "FROM   contact_messages " +
                    "ORDER  BY is_read ASC, created_at DESC";   // unread first, then newest

    private static final String SQL_COUNT_UNREAD =
            "SELECT COUNT(*) FROM contact_messages WHERE is_read = 0";

    private static final String SQL_SET_READ_FLAG =
            "UPDATE contact_messages SET is_read = ? WHERE id = ?";

    private static final String SQL_DELETE =
            "DELETE FROM contact_messages WHERE id = ?";

    /** Rate-limit check: count recent submissions from the same IP */
    private static final String SQL_RATE_CHECK_IP =
            "SELECT COUNT(*) FROM contact_messages " +
                    "WHERE  ip_address = ? AND created_at >= ?";

    // ── GET ───────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = sanitise(req.getParameter("action"));

        // unreadCount is a lightweight AJAX endpoint — no admin check needed
        // (the count itself reveals nothing sensitive)
        if ("unreadCount".equals(action)) {
            if (!isAdmin(req)) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            handleUnreadCount(req, resp);
            return;
        }

        // All other GET actions require an admin session
        if (!isAdmin(req)) {
            resp.sendRedirect(req.getContextPath() + "/admin/admin-login.jsp");
            return;
        }
        req.setAttribute(CSRF_ATTRIBUTE, ensureCsrfToken(req.getSession(false)));

        switch (action) {
            case "read":
            case "unread":
            case "delete":
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                        "Contact message changes require POST.");
                break;
            case "list":
            default:
                handleList(req, resp);
                break;
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String action = sanitise(req.getParameter("action"));
        if ("read".equals(action) || "unread".equals(action) || "delete".equals(action)) {
            HttpSession adminSession = req.getSession(false);
            if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            if (!validCsrf(adminSession, req.getParameter("_csrf"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
                return;
            }
            if ("read".equals(action)) handleSetRead(req, resp, true);
            else if ("unread".equals(action)) handleSetRead(req, resp, false);
            else handleDelete(req, resp);
            return;
        }
        if (!action.isEmpty() && !"submit".equals(action)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown contact action.");
            return;
        }
        HttpSession publicSession = req.getSession(false);
        if (publicSession == null || !validCsrf(publicSession, req.getParameter("_csrf"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
            return;
        }

        // ── 1. Read and sanitise form fields ──────────────────────────────────
        String name    = sanitise(req.getParameter("name"));
        String email   = sanitise(req.getParameter("email")).toLowerCase();
        String phone   = sanitise(req.getParameter("phone"));
        String subject = sanitise(req.getParameter("subject"));
        String message = sanitise(req.getParameter("message"));
        String ip      = getClientIp(req);

        // ── 2. Server-side validation ─────────────────────────────────────────
        String validErr = validate(name, email, message, subject);
        if (validErr != null) {
            req.setAttribute("error", validErr);
            req.getRequestDispatcher("/contact.jsp").forward(req, resp);
            return;
        }

        // ── 3. Truncate to column limits (belt-and-braces) ────────────────────
        name    = cap(name,    MAX_NAME_LEN);
        email   = cap(email,   MAX_EMAIL_LEN);
        phone   = cap(phone,   MAX_PHONE_LEN);
        subject = cap(subject, MAX_SUBJECT_LEN);
        message = cap(message, MAX_MESSAGE_LEN);

        // ── 4. Rate-limit check ───────────────────────────────────────────────
        if (isRateLimited(ip)) {
            req.setAttribute("error",
                    "You have sent several messages recently. "
                            + "Please wait a while before sending another, "
                            + "or call us directly at +91 12345 67890.");
            req.getRequestDispatcher("/contact.jsp").forward(req, resp);
            return;
        }

        // ── 5. Persist to DB ──────────────────────────────────────────────────
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     SQL_INSERT, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString   (1, name);
            ps.setString   (2, email);
            ps.setString   (3, phone.isEmpty() ? null : phone);
            ps.setString   (4, subject.isEmpty() ? "General Inquiry" : subject);
            ps.setString   (5, message);
            ps.setString   (6, ip);
            ps.setTimestamp(7, Timestamp.from(Instant.now()));
            ps.executeUpdate();

            ResultSet keys  = ps.getGeneratedKeys();
            int       newId = keys.next() ? keys.getInt(1) : -1;

            LOG.info("Contact message saved — id=" + newId
                    + " from=" + email
                    + " subject=\"" + subject + "\""
                    + " ip=" + ip);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ContactServlet DB error for email=" + email, e);
            req.setAttribute("error",
                    "We could not send your message due to a server error. "
                            + "Please try again or call us directly.");
            req.getRequestDispatcher("/contact.jsp").forward(req, resp);
            return;
        }

        HttpSession session = req.getSession(true);

        // ── 7. Redirect back with success message ─────────────────────────────
        // Use PRG (Post-Redirect-Get) to prevent double-submission on refresh
        session.setAttribute("contactSuccess",
                "Thank you, " + firstName(name) + "! "
                        + "Your message has been received. "
                        + "Our concierge team will reply to " + email + " within 4 business hours.");
        resp.sendRedirect(req.getContextPath() + "/contact.jsp");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET handlers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Loads all contact messages (unread first) and forwards to the admin
     * messages page.  Also attaches the unread count as {@code unreadCount}.
     */
    private void handleList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        List<Map<String, Object>> messages = new ArrayList<>();
        int unreadCount = 0;

        try (Connection conn = DBConnection.getConnection()) {

            // Unread count for topbar badge
            try (PreparedStatement ps = conn.prepareStatement(SQL_COUNT_UNREAD);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) unreadCount = rs.getInt(1);
            }

            // Full message list
            try (PreparedStatement ps = conn.prepareStatement(SQL_LIST_ALL);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id",        rs.getInt("id"));
                    row.put("name",      rs.getString("name"));
                    row.put("email",     rs.getString("email"));
                    row.put("phone",     rs.getString("phone"));
                    row.put("subject",   rs.getString("subject"));
                    row.put("message",   rs.getString("message"));
                    row.put("isRead",    rs.getBoolean("is_read"));
                    row.put("createdAt", rs.getTimestamp("created_at"));
                    messages.add(row);
                }
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ContactServlet list error", e);
        }

        req.setAttribute("contactMessages", messages);
        req.setAttribute("unreadCount",     unreadCount);
        req.getRequestDispatcher("/admin/manage-messages.jsp").forward(req, resp);
    }

    /**
     * Marks a single message as read ({@code flag=true}) or unread ({@code flag=false}).
     * Redirects back to the admin list on completion.
     *
     * @param flag {@code true} → is_read = 1, {@code false} → is_read = 0
     */
    private void handleSetRead(HttpServletRequest req,
                               HttpServletResponse resp,
                               boolean flag) throws IOException {

        int id = parseIntSafe(req.getParameter("id"), 0);
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/contact?action=list");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_SET_READ_FLAG)) {

            ps.setInt(1, flag ? 1 : 0);
            ps.setInt(2, id);
            ps.executeUpdate();
            LOG.fine("Contact message id=" + id + " marked " + (flag ? "read" : "unread"));

        } catch (SQLException e) {
            LOG.log(Level.WARNING, "ContactServlet setRead error for id=" + id, e);
        }

        resp.sendRedirect(req.getContextPath() + "/contact?action=list");
    }

    /**
     * Hard-deletes a contact message by {@code id}.
     * Redirects to the admin list with a {@code deleted=1} query parameter.
     */
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int id = parseIntSafe(req.getParameter("id"), 0);
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/contact?action=list");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_DELETE)) {

            ps.setInt(1, id);
            int rows = ps.executeUpdate();
            LOG.info("Contact message deleted — id=" + id + " (rows=" + rows + ")");

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ContactServlet delete error for id=" + id, e);
        }

        resp.sendRedirect(req.getContextPath()
                + "/contact?action=list&deleted=1");
    }

    /**
     * Returns the current unread message count as a plain-text integer.
     * Designed for lightweight AJAX polling from the admin sidebar badge.
     *
     * <p>Example JS usage:
     * <pre>
     *   fetch('/context/contact?action=unreadCount')
     *     .then(r => r.text())
     *     .then(n => badge.textContent = n);
     * </pre>
     */
    private void handleUnreadCount(HttpServletRequest req,
                                   HttpServletResponse resp) throws IOException {
        int count = 0;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_COUNT_UNREAD);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) count = rs.getInt(1);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "ContactServlet unreadCount error", e);
        }

        resp.setContentType("text/plain");
        resp.setCharacterEncoding("UTF-8");
        resp.getWriter().write(String.valueOf(count));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Rate limiting
    // ─────────────────────────────────────────────────────────────────────────

    /** Database-backed per-address sliding-window throttle. */
    private boolean isRateLimited(String ip) {

        Timestamp windowStart = Timestamp.from(
                Instant.now().minus(RATE_LIMIT_WINDOW_MINUTES, ChronoUnit.MINUTES));

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_RATE_CHECK_IP)) {

            ps.setString   (1, ip);
            ps.setTimestamp(2, windowStart);
            ResultSet rs = ps.executeQuery();

            if (rs.next() && rs.getInt(1) >= RATE_LIMIT_MAX) {
                LOG.warning("Rate limit hit (DB) — IP=" + ip
                        + " count=" + rs.getInt(1));
                return true;
            }

        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Contact rate-limit check failed; rejecting submission", e);
            return true;
        }

        return false;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Validation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Validates the four required-ish form fields.
     *
     * @return an error message, or {@code null} if all fields pass
     */
    private String validate(String name, String email,
                            String message, String subject) {

        if (isEmpty(name))
            return "Please enter your full name.";

        if (name.length() > MAX_NAME_LEN)
            return "Name must be " + MAX_NAME_LEN + " characters or fewer.";

        if (isEmpty(email))
            return "Please enter your email address.";

        if (!EMAIL_PATTERN.matcher(email).matches())
            return "Please enter a valid email address.";

        if (email.length() > MAX_EMAIL_LEN)
            return "Email address is too long.";

        if (isEmpty(message))
            return "Please enter a message.";

        if (message.length() < MIN_MESSAGE_LEN)
            return "Your message must be at least " + MIN_MESSAGE_LEN + " characters.";

        if (message.length() > MAX_MESSAGE_LEN)
            return "Your message must be " + MAX_MESSAGE_LEN + " characters or fewer.";

        // Subject is optional but must be one of the allowed values if provided
        if (!subject.isEmpty() && !VALID_SUBJECTS.contains(subject))
            return "Please select a valid subject.";

        return null; // all good
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /** @return {@code true} if the current session belongs to an admin */
    private static boolean isAdmin(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s != null && "admin".equals(s.getAttribute("userRole"));
    }

    /** Uses the socket peer address; forwarded headers require a trusted proxy. */
    private static String getClientIp(HttpServletRequest req) {
        return req.getRemoteAddr();
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        String expected = (String) session.getAttribute(CSRF_ATTRIBUTE);
        return expected != null && supplied != null
                && MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }

    private static String ensureCsrfToken(HttpSession session) {
        String token = (String) session.getAttribute(CSRF_ATTRIBUTE);
        if (token == null) {
            token = java.util.UUID.randomUUID().toString();
            session.setAttribute(CSRF_ATTRIBUTE, token);
        }
        return token;
    }

    /**
     * Extracts the first token of a full name for use in the success message
     * (e.g. "Arjun Sharma" → "Arjun").
     */
    private static String firstName(String fullName) {
        if (fullName == null || fullName.isEmpty()) return "there";
        int space = fullName.indexOf(' ');
        return space > 0 ? fullName.substring(0, space) : fullName;
    }

    /** Truncates {@code s} to at most {@code max} characters. */
    private static String cap(String s, int max) {
        return (s != null && s.length() > max) ? s.substring(0, max) : s;
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(sanitise(s)); }
        catch (NumberFormatException e) { return fallback; }
    }
}
