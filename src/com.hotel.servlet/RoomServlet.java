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
import java.sql.*;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/**
 * RoomServlet — CRUD operations for hotel rooms.
 *
 * <p>All write operations (add, edit, delete, status) require an active
 * admin session. Read operations (list, availability) are open.
 *
 * <p>URL: {@code /RoomServlet}
 *
 * <p>Actions via request parameter {@code action}:
 * <table border="1">
 *   <tr><th>Method</th><th>action</th><th>Description</th></tr>
 *   <tr><td>GET</td><td>list</td><td>All rooms → manage-rooms.jsp</td></tr>
 *   <tr><td>GET</td><td>available</td><td>Available rooms for dates (JSON)</td></tr>
 *   <tr><td>GET</td><td>delete</td><td>Delete room by id (admin)</td></tr>
 *   <tr><td>GET</td><td>status</td><td>Toggle room status (admin)</td></tr>
 *   <tr><td>POST</td><td>add</td><td>Insert new room</td></tr>
 *   <tr><td>POST</td><td>edit</td><td>Update existing room</td></tr>
 * </table>
 */
@WebServlet(urlPatterns = {"/room", "/RoomServlet"})
public class RoomServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(RoomServlet.class.getName());
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String CSRF_ATTRIBUTE = "roomCsrfToken";

    // ── SQL constants ─────────────────────────────────────────────────────────

    private static final String SQL_ALL_ROOMS =
            "SELECT id, room_number, room_type, floor, capacity, " +
                    "       rate_per_night, description, status " +
                    "FROM rooms ORDER BY CAST(room_number AS UNSIGNED), room_number";

    private static final String SQL_AVAILABLE_ROOMS =
            "SELECT r.id, r.room_number, r.room_type, r.floor, r.capacity, r.rate_per_night " +
            "FROM rooms r " +
            "WHERE r.status <> 'Maintenance' " +
            "  AND NOT EXISTS ( " +
            "      SELECT 1 FROM bookings b WHERE b.room_id = r.id " +
            "        AND b.status IN ('Confirmed','Pending','Checked-In') " +
            "        AND NOT (b.checkout_date <= ? OR b.checkin_date >= ?) " +
            "  ) " +
            "ORDER BY r.rate_per_night";

    private static final String SQL_FIND_BY_ID =
            "SELECT * FROM rooms WHERE id = ? LIMIT 1";

    private static final String SQL_INSERT_ROOM =
            "INSERT INTO rooms (room_number, room_type, floor, capacity, " +
                    "                   rate_per_night, description, status) " +
                    "VALUES (?,?,?,?,?,?,?)";

    private static final String SQL_UPDATE_ROOM =
            "UPDATE rooms SET room_number=?, room_type=?, floor=?, capacity=?, " +
                    "                 rate_per_night=?, description=?, status=? " +
                    "WHERE id=?";

    private static final String SQL_DELETE_ROOM =
            "DELETE FROM rooms WHERE id=?";

    private static final String SQL_UPDATE_STATUS =
            "UPDATE rooms SET status=? WHERE id=?";

    private static final String SQL_CHECK_NUMBER_UNIQUE =
            "SELECT id FROM rooms WHERE room_number=? AND id<>? LIMIT 1";

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = sanitise(req.getParameter("action"));

        switch (action) {

            case "available":
                handleAvailable(req, resp);
                break;

            case "public-list":
                handlePublicList(req, resp);
                break;

            case "detail":
                handlePublicDetail(req, resp);
                break;

            case "admin-list":
                if (!requireAdmin(req, resp)) return;
                handleAdminList(req, resp);
                break;

            case "delete":
            case "status":
                resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Room changes require POST.");
                break;

            case "list":
                if (!requireAdmin(req, resp)) return;
                handleAdminList(req, resp);
                req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
                break;

            default:
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                break;
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!requireAdmin(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession(false);
        String expectedToken = session == null ? null : (String) session.getAttribute(CSRF_ATTRIBUTE);
        String suppliedToken = req.getParameter("csrfToken");
        if (expectedToken == null || suppliedToken == null ||
                !MessageDigest.isEqual(expectedToken.getBytes(java.nio.charset.StandardCharsets.UTF_8),
                        suppliedToken.getBytes(java.nio.charset.StandardCharsets.UTF_8))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
            return;
        }

        String action = sanitise(req.getParameter("action"));

        switch (action) {
            case "edit":
                handleEdit(req, resp);
                break;
            case "add":
                handleAdd(req, resp);
                break;
            case "delete":
                handleDelete(req, resp);
                break;
            case "status":
                handleStatusToggle(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown room action.");
        }
    }

    // ── Handlers ──────────────────────────────────────────────────────────────

    /** Load all rooms and forward to the admin manage-rooms page */
    private void handleList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        List<Map<String, Object>> rooms = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_ALL_ROOMS);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                rooms.add(mapRoom(rs));
            }
            req.setAttribute("rooms", rooms);
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet list error", e);
            req.setAttribute("error", "Failed to load rooms.");
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
        }
    }

    /** Supplies live room inventory and counts to the admin room page. */
    private void handleAdminList(HttpServletRequest req, HttpServletResponse resp) {
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute(CSRF_ATTRIBUTE) == null) {
            byte[] tokenBytes = new byte[32];
            RANDOM.nextBytes(tokenBytes);
            session.setAttribute(CSRF_ATTRIBUTE, Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes));
        }
        if (session != null) req.setAttribute("roomCsrfToken", session.getAttribute(CSRF_ATTRIBUTE));
        List<Map<String, Object>> rooms = new ArrayList<>();
        int available = 0;
        int occupied = 0;
        int maintenance = 0;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_ALL_ROOMS);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> room = mapRoom(rs);
                rooms.add(room);
                String status = String.valueOf(room.get("status"));
                if ("Available".equals(status)) available++;
                else if ("Occupied".equals(status)) occupied++;
                else if ("Maintenance".equals(status)) maintenance++;
            }
            req.setAttribute("rooms", rooms);
            req.setAttribute("availableCount", available);
            req.setAttribute("occupiedCount", occupied);
            req.setAttribute("maintenanceCount", maintenance);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet admin list error", e);
            req.setAttribute("rooms", rooms);
            req.setAttribute("roomAdminError", true);
        }
    }

    /** Public catalogue: show every room that is not under maintenance. */
    private void handlePublicList(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        List<Map<String, Object>> rooms = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, room_number, room_type, floor, capacity, rate_per_night, description, status " +
                             "FROM rooms WHERE status <> 'Maintenance' " +
                             "ORDER BY room_type, CAST(room_number AS UNSIGNED), room_number");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) rooms.add(mapRoom(rs));
            req.setAttribute("publicRooms", rooms);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet public list error", e);
            req.setAttribute("roomLoadError", true);
        }
    }

    /** Load an available room by its database id (preferred) or room type. */
    private void handlePublicDetail(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String idValue = sanitise(req.getParameter("id"));
        String type = sanitise(req.getParameter("type"));
        String sql = idValue.matches("\\d+")
                ? "SELECT id, room_number, room_type, floor, capacity, rate_per_night, description, status " +
                  "FROM rooms WHERE id = ? AND status <> 'Maintenance' LIMIT 1"
                : "SELECT id, room_number, room_type, floor, capacity, rate_per_night, description, status " +
                  "FROM rooms WHERE room_type = ? AND status <> 'Maintenance' " +
                  "ORDER BY CAST(room_number AS UNSIGNED), room_number LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, idValue.matches("\\d+") ? idValue : type);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) req.setAttribute("publicRoom", mapRoom(rs));
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet room detail error", e);
            req.setAttribute("roomLoadError", true);
        }
    }

    /**
     * Returns available rooms as a JSON array for a given date range.
     * Called from the quick-book bar via AJAX.
     *
     * <p>Params: {@code checkin} (yyyy-MM-dd), {@code checkout} (yyyy-MM-dd)
     */
    private void handleAvailable(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String checkin  = sanitise(req.getParameter("checkin"));
        String checkout = sanitise(req.getParameter("checkout"));

        LocalDate checkinDate;
        LocalDate checkoutDate;
        try {
            checkinDate = LocalDate.parse(checkin);
            checkoutDate = LocalDate.parse(checkout);
        } catch (DateTimeParseException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Dates must use yyyy-MM-dd format.");
            return;
        }
        if (!checkoutDate.isAfter(checkinDate) || checkinDate.isBefore(LocalDate.now())) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Choose a valid future stay date range.");
            return;
        }

        StringBuilder json = new StringBuilder("[");
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_AVAILABLE_ROOMS)) {

            ps.setString(1, checkin);
            ps.setString(2, checkout);
            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{")
                            .append("\"id\":").append(rs.getInt("id")).append(",")
                            .append("\"roomNumber\":\"").append(esc(rs.getString("room_number"))).append("\",")
                            .append("\"roomType\":\"").append(esc(rs.getString("room_type"))).append("\",")
                            .append("\"floor\":\"").append(esc(rs.getString("floor"))).append("\",")
                            .append("\"capacity\":\"").append(esc(rs.getString("capacity"))).append("\",")
                            .append("\"rate\":").append(rs.getBigDecimal("rate_per_night"))
                            .append("}");
                    first = false;
                }
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet available error", e);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Room availability is temporarily unavailable.");
            return;
        }

        json.append("]");
        sendJson(resp, json.toString());
    }

    /** Add a new room — called from the admin modal form */
    private void handleAdd(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        String   roomNumber  = sanitise(req.getParameter("roomNumber")).toUpperCase();
        String   roomType    = sanitise(req.getParameter("roomType"));
        String   floor       = sanitise(req.getParameter("floor"));
        String   capacity    = sanitise(req.getParameter("capacity"));
        String   rateStr     = sanitise(req.getParameter("rate"));
        String   description = sanitise(req.getParameter("description"));
        String   status      = sanitise(req.getParameter("status"));

        // Basic validation
        String err = validateRoom(roomNumber, roomType, floor, rateStr, status, 0);
        if (err != null) {
            req.setAttribute("error", err);
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
            return;
        }

        BigDecimal rate = new BigDecimal(rateStr);

        try (Connection conn = DBConnection.getConnection()) {

            // Unique room number check
            if (roomNumberExists(conn, roomNumber, 0)) {
                req.setAttribute("error",
                        "Room number '" + roomNumber + "' already exists.");
                req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(SQL_INSERT_ROOM)) {
                ps.setString    (1, roomNumber);
                ps.setString    (2, roomType);
                ps.setString    (3, floor.isEmpty() ? null : floor);
                ps.setString    (4, capacity.isEmpty() ? "2 Adults" : capacity);
                ps.setBigDecimal(5, rate);
                ps.setString    (6, description.isEmpty() ? null : description);
                ps.setString    (7, status.isEmpty() ? "Available" : status);
                ps.executeUpdate();
            }

            LOG.info("Room added — number=" + roomNumber + " type=" + roomType);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet add error", e);
            req.setAttribute("error", "Failed to add room. Please check the room details and try again.");
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?success=added");
    }

    /** Edit an existing room — called from the admin modal form */
    private void handleEdit(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        int      id          = parseIntSafe(req.getParameter("id"), 0);
        String   roomNumber  = sanitise(req.getParameter("roomNumber")).toUpperCase();
        String   roomType    = sanitise(req.getParameter("roomType"));
        String   floor       = sanitise(req.getParameter("floor"));
        String   capacity    = sanitise(req.getParameter("capacity"));
        String   rateStr     = sanitise(req.getParameter("rate"));
        String   description = sanitise(req.getParameter("description"));
        String   status      = sanitise(req.getParameter("status"));

        if (id <= 0) {
            req.setAttribute("error", "Invalid room ID.");
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
            return;
        }

        String err = validateRoom(roomNumber, roomType, floor, rateStr, status, id);
        if (err != null) {
            req.setAttribute("error", err);
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
            return;
        }

        BigDecimal rate = new BigDecimal(rateStr);

        try (Connection conn = DBConnection.getConnection()) {

            if (roomNumberExists(conn, roomNumber, id)) {
                req.setAttribute("error",
                        "Room number '" + roomNumber + "' is already used by another room.");
                req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_ROOM)) {
                ps.setString    (1, roomNumber);
                ps.setString    (2, roomType);
                ps.setString    (3, floor.isEmpty() ? null : floor);
                ps.setString    (4, capacity.isEmpty() ? "2 Adults" : capacity);
                ps.setBigDecimal(5, rate);
                ps.setString    (6, description.isEmpty() ? null : description);
                ps.setString    (7, status.isEmpty() ? "Available" : status);
                ps.setInt       (8, id);
                if (ps.executeUpdate() == 0) {
                    req.setAttribute("error", "Room not found.");
                    req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
                    return;
                }
            }

            LOG.info("Room updated — id=" + id + " number=" + roomNumber);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet edit error", e);
            req.setAttribute("error", "Failed to update room. Please check the room details and try again.");
            req.getRequestDispatcher("/admin/manage-rooms.jsp").forward(req, resp);
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?success=updated");
    }

    /** Hard-delete a room (only if no active bookings) */
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int id = parseIntSafe(req.getParameter("id"), 0);
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_DELETE_ROOM)) {

            ps.setInt(1, id);
            if (ps.executeUpdate() == 0) {
                resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?error=not_found");
                return;
            }
            LOG.info("Room deleted — id=" + id);

        } catch (SQLIntegrityConstraintViolationException e) {
            // FK violation — room has bookings
            LOG.warning("Cannot delete room id=" + id + " (has bookings).");
            resp.sendRedirect(req.getContextPath() +
                    "/admin/manage-rooms.jsp?error=has_bookings");
            return;

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet delete error", e);
            resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?error=delete_failed");
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?success=deleted");
    }

    /** Cycle room status: Available → Maintenance → Available */
    private void handleStatusToggle(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int    id     = parseIntSafe(req.getParameter("id"), 0);
        String status = sanitise(req.getParameter("status"));

        if (id <= 0 || !("Available".equals(status) || "Maintenance".equals(status))) {
            resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp");
            return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_STATUS)) {

            ps.setString(1, status);
            ps.setInt   (2, id);
            if (ps.executeUpdate() == 0) {
                resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?error=not_found");
                return;
            }
            LOG.info("Room status updated — id=" + id + " status=" + status);

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RoomServlet status error", e);
            resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp?error=status_failed");
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/manage-rooms.jsp");
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Map<String, Object> mapRoom(ResultSet rs) throws SQLException {
        Map<String, Object> m = new HashMap<>();
        m.put("id",           rs.getInt("id"));
        m.put("roomNumber",   rs.getString("room_number"));
        m.put("roomType",     rs.getString("room_type"));
        m.put("floor",        rs.getString("floor"));
        m.put("capacity",     rs.getString("capacity"));
        m.put("rate",         rs.getBigDecimal("rate_per_night"));
        m.put("description",  rs.getString("description"));
        m.put("status",       rs.getString("status"));
        return m;
    }

    private boolean roomNumberExists(Connection conn, String number, int excludeId)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_CHECK_NUMBER_UNIQUE)) {
            ps.setString(1, number);
            ps.setInt   (2, excludeId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        }
    }

    private String validateRoom(String number, String type, String floor, String rate, String status, int id) {
        if (isEmpty(number)) return "Room number is required.";
        if (number.length() > 10 || !number.matches("[A-Z0-9-]+")) return "Room number must contain only letters, numbers, or hyphens (up to 10 characters).";
        if (isEmpty(type))   return "Room type is required.";
        if (!java.util.Arrays.asList("Deluxe Room", "Twin Room", "Family Suite", "Junior Suite", "Executive Suite", "Presidential Suite").contains(type)) return "Choose a valid room type.";
        if (isEmpty(floor) || floor.length() > 20) return "Floor is required and must be 20 characters or fewer.";
        if (isEmpty(status)) status = "Available";
        if (!java.util.Arrays.asList("Available", "Occupied", "Maintenance").contains(status)) return "Choose a valid room status.";
        if (isEmpty(rate))   return "Rate per night is required.";
        try {
            BigDecimal r = new BigDecimal(rate);
            if (r.compareTo(BigDecimal.ZERO) <= 0 || r.precision() > 10 || r.scale() > 2) return "Rate must be a positive amount with at most two decimal places.";
        } catch (NumberFormatException e) {
            return "Rate per night must be a valid number.";
        }
        return null;
    }

    /** Guard: redirect to admin login if no valid admin session. */
    private boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            resp.sendRedirect(req.getContextPath() + "/admin/admin-login.jsp");
            return false;
        }
        return true;
    }

    private void sendJson(HttpServletResponse resp, String json) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().write(json);
    }

    /** Minimal JSON string escaping — for simple field values. */
    private static String esc(String s) {
        if (s == null) return "";
        StringBuilder out = new StringBuilder(s.length() + 8);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\': out.append("\\\\"); break;
                case '"': out.append("\\\""); break;
                case '\b': out.append("\\b"); break;
                case '\f': out.append("\\f"); break;
                case '\n': out.append("\\n"); break;
                case '\r': out.append("\\r"); break;
                case '\t': out.append("\\t"); break;
                default:
                    if (c < 0x20) out.append(String.format("\\u%04x", (int) c));
                    else out.append(c);
            }
        }
        return out.toString();
    }

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(sanitise(s)); }
        catch (NumberFormatException e) { return fallback; }
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}
