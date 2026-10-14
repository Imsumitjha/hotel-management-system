package com.hotel.servlet;

import com.hotel.util.DBConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * ReviewServlet — full CRUD for guest room reviews and ratings.
 *
 * <h3>Database prerequisites</h3>
 * Add the following table to {@code hotel.sql} before running:
 * <pre>
 * CREATE TABLE IF NOT EXISTS reviews (
 *     id            INT            NOT NULL AUTO_INCREMENT,
 *     booking_id    INT            NOT NULL,          -- one review per booking
 *     room_id       INT            NOT NULL,
 *     user_id       INT            NOT NULL,
 *     rating        TINYINT        NOT NULL,          -- 1–5
 *     title         VARCHAR(120),
 *     body          TEXT           NOT NULL,
 *     status        ENUM('Pending','Approved','Rejected')
 *                   NOT NULL DEFAULT 'Pending',
 *     admin_note    VARCHAR(255),                     -- moderation note
 *     created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 *     updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
 *                   ON UPDATE CURRENT_TIMESTAMP,
 *
 *     PRIMARY KEY (id),
 *     UNIQUE  KEY uk_review_booking (booking_id),    -- one review per booking
 *     INDEX       idx_review_room   (room_id),
 *     INDEX       idx_review_user   (user_id),
 *     INDEX       idx_review_status (status),
 *
 *     CONSTRAINT fk_review_booking FOREIGN KEY (booking_id)
 *         REFERENCES bookings (id) ON DELETE CASCADE,
 *     CONSTRAINT fk_review_room FOREIGN KEY (room_id)
 *         REFERENCES rooms    (id) ON DELETE CASCADE,
 *     CONSTRAINT fk_review_user FOREIGN KEY (user_id)
 *         REFERENCES users    (id) ON DELETE CASCADE
 * ) ENGINE=InnoDB;
 * </pre>
 *
 * <h3>URL: {@code /review}</h3>
 *
 * <h3>GET actions (via {@code action} parameter)</h3>
 * <table border="1">
 *   <tr><th>action</th><th>Who</th><th>Description</th></tr>
 *   <tr><td>list</td><td>All</td>
 *       <td>Approved reviews for a room ({@code roomId} required) → room-details.jsp</td></tr>
 *   <tr><td>all</td><td>Admin</td>
 *       <td>All reviews (all statuses) → admin manage-reviews page</td></tr>
 *   <tr><td>delete</td><td>Admin</td><td>Not allowed; mutations require POST</td></tr>
 *   <tr><td>moderate</td><td>Admin</td><td>Not allowed; mutations require POST</td></tr>
 * </table>
 *
 * <h3>POST actions</h3>
 * <table border="1">
 *   <tr><th>action</th><th>Who</th><th>Description</th></tr>
 *   <tr><td>submit</td><td>Logged-in guest</td>
 *       <td>Create a new review for a completed booking</td></tr>
 *   <tr><td>edit</td><td>Review author</td>
 *       <td>Update the own review's rating, title, and body</td></tr>
 * </table>
 */
@WebServlet("/review")
public class ReviewServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ReviewServlet.class.getName());

    // ── Constants ─────────────────────────────────────────────────────────────

    private static final int MIN_RATING   = 1;
    private static final int MAX_RATING   = 5;
    private static final int MAX_TITLE    = 120;
    private static final int MAX_BODY     = 2000;
    private static final int MIN_BODY_LEN = 20;

    // ── SQL ───────────────────────────────────────────────────────────────────

    /** Approved reviews for a specific room, newest first */
    private static final String SQL_LIST_BY_ROOM =
            "SELECT r.id, r.rating, r.title, r.body, r.created_at, r.updated_at, " +
                    "       u.first_name, u.last_name, " +
                    "       ro.room_number, ro.room_type " +
                    "FROM   reviews r " +
                    "JOIN   users   u  ON r.user_id  = u.id " +
                    "JOIN   rooms   ro ON r.room_id  = ro.id " +
                    "WHERE  r.room_id = ? AND r.status = 'Approved' " +
                    "ORDER  BY r.created_at DESC";

    /** All reviews for admin panel (all statuses), newest first */
    private static final String SQL_LIST_ALL =
            "SELECT r.id, r.rating, r.title, r.body, r.status, r.admin_note, " +
                    "       r.created_at, r.updated_at, " +
                    "       u.first_name, u.last_name, u.email, " +
                    "       ro.room_number, ro.room_type, " +
                    "       b.booking_ref " +
                    "FROM   reviews r " +
                    "JOIN   users   u  ON r.user_id   = u.id " +
                    "JOIN   rooms   ro ON r.room_id   = ro.id " +
                    "JOIN   bookings b ON r.booking_id = b.id " +
                    "ORDER  BY r.created_at DESC";

    private static final String SQL_PENDING_COUNT =
            "SELECT COUNT(*) FROM reviews WHERE status = 'Pending'";

    /** Average rating and review count for a room — used on room-details.jsp */
    private static final String SQL_ROOM_RATING =
            "SELECT AVG(rating) AS avg_rating, COUNT(*) AS review_count " +
                    "FROM   reviews " +
                    "WHERE  room_id = ? AND status = 'Approved'";

    /** Guard: find a completed booking owned by this user for this room */
    private static final String SQL_VERIFY_BOOKING =
            "SELECT id FROM bookings " +
                    "WHERE  id = ? AND user_id = ? AND room_id = ? " +
                    "  AND  status IN ('Confirmed','Checked-Out') " +
                    "LIMIT  1";

    /** Guard: ensure no duplicate review for the same booking */
    private static final String SQL_CHECK_DUPLICATE =
            "SELECT id FROM reviews WHERE booking_id = ? LIMIT 1";

    /** Insert new review */
    private static final String SQL_INSERT =
            "INSERT INTO reviews (booking_id, room_id, user_id, rating, title, body, status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, 'Pending')";

    /** Update own review (resets status to Pending for re-moderation) */
    private static final String SQL_UPDATE =
            "UPDATE reviews " +
                    "SET    rating = ?, title = ?, body = ?, status = 'Pending', updated_at = NOW() " +
                    "WHERE  id = ? AND user_id = ?";

    /** Admin: approve or reject */
    private static final String SQL_MODERATE =
            "UPDATE reviews SET status = ?, admin_note = ?, updated_at = NOW() WHERE id = ?";

    /** Hard-delete (admin only) */
    private static final String SQL_DELETE =
            "DELETE FROM reviews WHERE id = ?";

    /** Fetch one review by id (ownership check) */
    private static final String SQL_FIND_BY_ID =
            "SELECT id, user_id, room_id, booking_id, rating, title, body, status " +
                    "FROM   reviews WHERE id = ? LIMIT 1";

    // ── GET ───────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = sanitise(req.getParameter("action"));

        switch (action) {
            case "all":
                if (!requireAdmin(req, resp)) return;
                handleListAll(req, resp);
                break;
            case "delete":
            case "moderate":
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                        "Review changes require POST.");
                break;
            case "list":
            default:
                handleListByRoom(req, resp);
                break;
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = sanitise(req.getParameter("action"));

        switch (action) {
            case "delete":
            case "moderate":
                if (!requireAdmin(req, resp)) return;
                if (!validCsrf(req.getSession(false), req.getParameter("_csrf"))) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
                    return;
                }
                if ("delete".equals(action)) handleDelete(req, resp);
                else handleModerate(req, resp);
                break;
            case "edit":
                if (!requireGuest(req, resp)) return;
                if (!validCsrf(req.getSession(false), req.getParameter("_csrf"))) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
                    return;
                }
                handleEdit(req, resp);
                break;
            case "submit":
                if (!requireGuest(req, resp)) return;
                if (!validCsrf(req.getSession(false), req.getParameter("_csrf"))) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token.");
                    return;
                }
                handleSubmit(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown review action.");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET handlers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Loads approved reviews for one room and attaches them — along with the
     * aggregated rating data — as request attributes, then forwards to
     * {@code room-details.jsp}.
     *
     * <p>Request param: {@code roomId} (integer)
     */
    private void handleListByRoom(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int roomId = parseIntSafe(req.getParameter("roomId"), 0);
        if (roomId <= 0) {
            resp.sendRedirect(req.getContextPath() + "/rooms.jsp");
            return;
        }

        List<Map<String, Object>> reviews = new ArrayList<>();
        double avgRating    = 0.0;
        int    reviewCount  = 0;
        int[]  ratingDist   = new int[6]; // index 1–5

        try (Connection conn = DBConnection.getConnection()) {

            // Fetch approved reviews
            try (PreparedStatement ps = conn.prepareStatement(SQL_LIST_BY_ROOM)) {
                ps.setInt(1, roomId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id",         rs.getInt("id"));
                    row.put("rating",     rs.getInt("rating"));
                    row.put("title",      rs.getString("title"));
                    row.put("body",       rs.getString("body"));
                    row.put("createdAt",  rs.getTimestamp("created_at"));
                    row.put("updatedAt",  rs.getTimestamp("updated_at"));
                    row.put("guestName",
                            rs.getString("first_name") + " " + rs.getString("last_name").charAt(0) + ".");
                    row.put("roomNumber", rs.getString("room_number"));
                    row.put("roomType",   rs.getString("room_type"));
                    reviews.add(row);

                    int r = rs.getInt("rating");
                    if (r >= 1 && r <= 5) ratingDist[r]++;
                }
            }

            // Aggregated rating
            try (PreparedStatement ps = conn.prepareStatement(SQL_ROOM_RATING)) {
                ps.setInt(1, roomId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    BigDecimal avg = rs.getBigDecimal("avg_rating");
                    if (avg != null) {
                        avgRating = avg.setScale(1, RoundingMode.HALF_UP).doubleValue();
                    }
                    reviewCount = rs.getInt("review_count");
                }
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet list error for roomId=" + roomId, e);
        }

        req.setAttribute("reviews",      reviews);
        req.setAttribute("avgRating",    avgRating);
        req.setAttribute("reviewCount",  reviewCount);
        req.setAttribute("ratingDist",   ratingDist);
        req.setAttribute("roomId",       roomId);

        req.getRequestDispatcher("/room-details.jsp").forward(req, resp);
    }

    /**
     * Loads all reviews across all statuses for the admin moderation panel.
     * Forwards to the admin moderation page with review rows and a CSRF token.
     *
     * <p>Optionally filter by {@code status} request param:
     * Pending | Approved | Rejected
     */
    private void handleListAll(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String statusFilter = sanitise(req.getParameter("status")); // may be empty
        if (!statusFilter.isEmpty() && !"Pending".equals(statusFilter)
                && !"Approved".equals(statusFilter) && !"Rejected".equals(statusFilter)) {
            statusFilter = "";
        }
        List<Map<String, Object>> reviews = new ArrayList<>();
        long pendingCount = 0;

        try (Connection conn  = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     statusFilter.isEmpty() ? SQL_LIST_ALL : SQL_LIST_ALL.replace("ORDER  BY", "WHERE r.status = ? ORDER BY"))) {

            if (!statusFilter.isEmpty()) ps.setString(1, statusFilter);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id",          rs.getInt("id"));
                row.put("rating",      rs.getInt("rating"));
                row.put("title",       rs.getString("title"));
                row.put("body",        rs.getString("body"));
                row.put("status",      rs.getString("status"));
                row.put("adminNote",   rs.getString("admin_note"));
                row.put("createdAt",   rs.getTimestamp("created_at"));
                row.put("guestName",
                        rs.getString("first_name") + " " + rs.getString("last_name"));
                row.put("guestEmail",  rs.getString("email"));
                row.put("roomNumber",  rs.getString("room_number"));
                row.put("roomType",    rs.getString("room_type"));
                row.put("bookingRef",  rs.getString("booking_ref"));
                reviews.add(row);
            }

            try (PreparedStatement count = conn.prepareStatement(SQL_PENDING_COUNT);
                 ResultSet countRow = count.executeQuery()) {
                if (countRow.next()) pendingCount = countRow.getLong(1);
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet listAll error", e);
            req.setAttribute("reviewLoadError", "Reviews could not be loaded. Please try again later.");
        }

        req.setAttribute("reviews",      reviews);
        req.setAttribute("pendingCount", pendingCount);
        req.setAttribute("statusFilter", statusFilter);
        req.setAttribute("reviewCsrfToken", ensureCsrfToken(req.getSession(true)));

        req.getRequestDispatcher("/admin/manage-reviews.jsp").forward(req, resp);
    }

    /**
     * Hard-deletes a review by id (admin only).
     * Request param: {@code id}
     */
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int id = parseIntSafe(req.getParameter("id"), 0);
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/review?action=all");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_DELETE)) {

            ps.setInt(1, id);
            int rows = ps.executeUpdate();
            LOG.info("Review deleted — id=" + id + " (rows affected=" + rows + ")");

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet delete error for id=" + id, e);
        }

        resp.sendRedirect(req.getContextPath() + "/review?action=all&deleted=1");
    }

    /**
     * Admin moderation — approve or reject a review.
     *
     * <p>Request params: {@code id}, {@code status} (Approved | Rejected),
     * optional {@code adminNote}
     */
    private void handleModerate(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int    id        = parseIntSafe(req.getParameter("id"), 0);
        String newStatus = sanitise(req.getParameter("status"));
        String adminNote = sanitise(req.getParameter("adminNote"));

        if (id <= 0 || (!newStatus.equals("Approved") && !newStatus.equals("Rejected"))) {
            LOG.warning("Invalid moderate params — id=" + id + " status=" + newStatus);
            resp.sendRedirect(req.getContextPath() + "/review?action=all");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_MODERATE)) {

            ps.setString(1, newStatus);
            ps.setString(2, adminNote.isEmpty() ? null : adminNote);
            ps.setInt   (3, id);
            ps.executeUpdate();

            LOG.info("Review moderated — id=" + id + " newStatus=" + newStatus);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet moderate error for id=" + id, e);
        }

        resp.sendRedirect(req.getContextPath()
                + "/review?action=all&moderated=1&status=" + newStatus.toLowerCase());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST handlers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Creates a new guest review.
     *
     * <p>Business rules enforced:
     * <ul>
     *   <li>User must be logged in.</li>
     *   <li>The {@code bookingId} must belong to this user, reference the
     *       correct {@code roomId}, and have status Confirmed or Checked-Out.</li>
     *   <li>Exactly one review is permitted per booking (UNIQUE constraint
     *       enforced both here in Java and at the DB level).</li>
     *   <li>Rating must be 1–5; body must be ≥ 20 characters; title is optional.</li>
     * </ul>
     *
     * <p>On success: review is inserted with status {@code Pending} (awaiting
     * admin approval) and the user is redirected to their dashboard with a
     * success flash message.
     */
    private void handleSubmit(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        int userId = (Integer) session.getAttribute("userId");

        // Read form fields
        int    bookingId = parseIntSafe(req.getParameter("bookingId"), 0);
        int    roomId    = parseIntSafe(req.getParameter("roomId"),    0);
        int    rating    = parseIntSafe(req.getParameter("rating"),    0);
        String title     = sanitise(req.getParameter("title"));
        String body      = sanitise(req.getParameter("body"));

        // Validate
        String validErr = validateReview(bookingId, roomId, rating, body);
        if (validErr != null) {
            req.setAttribute("error", validErr);
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;
        }

        // Truncate title/body to DB column limits
        if (title.length() > MAX_TITLE)  title = title.substring(0, MAX_TITLE);
        if (body.length()  > MAX_BODY)   body  = body.substring(0, MAX_BODY);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // 1. Verify the booking belongs to this user and is for this room
            try (PreparedStatement ps = conn.prepareStatement(SQL_VERIFY_BOOKING)) {
                ps.setInt(1, bookingId);
                ps.setInt(2, userId);
                ps.setInt(3, roomId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) {
                    conn.rollback();
                    req.setAttribute("error",
                            "We could not verify your booking. "
                                    + "Only completed stays can be reviewed.");
                    req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
                    return;
                }
            }

            // 2. Duplicate check
            try (PreparedStatement ps = conn.prepareStatement(SQL_CHECK_DUPLICATE)) {
                ps.setInt(1, bookingId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    conn.rollback();
                    req.setAttribute("error",
                            "You have already submitted a review for this booking.");
                    req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
                    return;
                }
            }

            // 3. Insert
            try (PreparedStatement ps = conn.prepareStatement(
                    SQL_INSERT, Statement.RETURN_GENERATED_KEYS)) {

                ps.setInt   (1, bookingId);
                ps.setInt   (2, roomId);
                ps.setInt   (3, userId);
                ps.setInt   (4, rating);
                ps.setString(5, title.isEmpty() ? null : title);
                ps.setString(6, body);
                ps.executeUpdate();

                ResultSet keys = ps.getGeneratedKeys();
                int newId = keys.next() ? keys.getInt(1) : -1;
                LOG.info("Review submitted — id=" + newId
                        + " userId=" + userId
                        + " roomId=" + roomId
                        + " rating=" + rating);
            }

            conn.commit();

        } catch (SQLIntegrityConstraintViolationException e) {
            // Race on the UNIQUE booking constraint — treat as duplicate
            LOG.warning("Duplicate review for bookingId=" + bookingId
                    + " userId=" + userId);
            req.setAttribute("error",
                    "A review for this booking already exists.");
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet submit error", e);
            req.setAttribute("error",
                    "A server error occurred while submitting your review. Please try again.");
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;
        }

        // Success redirect
        HttpSession s = req.getSession(false);
        if (s != null) s.setAttribute("flashSuccess",
                "Thank you for your review! It will appear once approved by our team.");
        resp.sendRedirect(req.getContextPath() + "/user-dashboard.jsp");
    }

    /**
     * Edits the caller's own review.
     *
     * <p>Ownership is enforced in SQL via the {@code AND user_id = ?} clause —
     * a guest cannot modify another user's review even with a crafted request.
     * Editing resets status to {@code Pending} so the review is re-moderated.
     *
     * <p>Request params: {@code id} (review id), {@code rating}, {@code title},
     * {@code body}
     */
    private void handleEdit(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        int userId = (Integer) session.getAttribute("userId");

        int    reviewId = parseIntSafe(req.getParameter("id"),     0);
        int    rating   = parseIntSafe(req.getParameter("rating"), 0);
        String title    = sanitise(req.getParameter("title"));
        String body     = sanitise(req.getParameter("body"));

        if (reviewId <= 0) {
            resp.sendRedirect(req.getContextPath() + "/user-dashboard.jsp");
            return;
        }

        // Validate content
        if (rating < MIN_RATING || rating > MAX_RATING) {
            req.setAttribute("error", "Rating must be between 1 and 5.");
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;
        }
        if (body.length() < MIN_BODY_LEN) {
            req.setAttribute("error",
                    "Review must be at least " + MIN_BODY_LEN + " characters.");
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;
        }

        if (title.length() > MAX_TITLE) title = title.substring(0, MAX_TITLE);
        if (body.length()  > MAX_BODY)  body  = body.substring(0, MAX_BODY);

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_UPDATE)) {

            ps.setInt   (1, rating);
            ps.setString(2, title.isEmpty() ? null : title);
            ps.setString(3, body);
            ps.setInt   (4, reviewId);
            ps.setInt   (5, userId); // ownership guard

            int rows = ps.executeUpdate();
            if (rows == 0) {
                // Either wrong id or the row belongs to someone else
                LOG.warning("Edit failed — reviewId=" + reviewId
                        + " userId=" + userId + " — no rows updated.");
                req.setAttribute("error",
                        "Review not found or you do not have permission to edit it.");
                req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
                return;
            }

            LOG.info("Review edited — id=" + reviewId + " userId=" + userId);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "ReviewServlet edit error for id=" + reviewId, e);
            req.setAttribute("error", "A server error occurred. Please try again.");
            req.getRequestDispatcher("/user-dashboard.jsp").forward(req, resp);
            return;
        }

        HttpSession s = req.getSession(false);
        if (s != null) s.setAttribute("flashSuccess",
                "Your review has been updated and is pending re-approval.");
        resp.sendRedirect(req.getContextPath() + "/user-dashboard.jsp");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Validation
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Validates the fields common to submit and edit.
     *
     * @return an error message string, or {@code null} if valid
     */
    private String validateReview(int bookingId, int roomId,
                                  int rating, String body) {
        if (bookingId <= 0) return "A valid booking is required to leave a review.";
        if (roomId    <= 0) return "Room information is missing. Please try again.";
        if (rating < MIN_RATING || rating > MAX_RATING)
            return "Please select a rating between 1 and 5 stars.";
        if (body == null || body.length() < MIN_BODY_LEN)
            return "Your review must be at least " + MIN_BODY_LEN + " characters.";
        if (body.length() > MAX_BODY)
            return "Your review exceeds the maximum length of " + MAX_BODY + " characters.";
        return null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Access guards
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Ensures the caller is an admin; redirects to admin login otherwise.
     * Callers must stop when this method returns {@code false}.
     */
    private boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            resp.sendRedirect(req.getContextPath() + "/admin/admin-login.jsp");
            return false;
        }
        return true;
    }

    /**
     * Ensures the caller is a logged-in user (any role); redirects to login
     * with {@code redirectAfterLogin} set otherwise.
     */
    private boolean requireGuest(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            req.getSession(true).setAttribute("redirectAfterLogin",
                    req.getContextPath() + "/user-dashboard.jsp");
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return false;
        }
        return true;
    }

    private static String ensureCsrfToken(HttpSession session) {
        synchronized (session) {
            String token = (String) session.getAttribute("csrfToken");
            if (token == null || token.isEmpty()) {
                token = java.util.UUID.randomUUID().toString();
                session.setAttribute("csrfToken", token);
            }
            return token;
        }
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        if (session == null || supplied == null) return false;
        String expected = (String) session.getAttribute("csrfToken");
        return expected != null && MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(sanitise(s)); }
        catch (NumberFormatException e) { return fallback; }
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }
}
