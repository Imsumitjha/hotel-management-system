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
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.time.format.DateTimeFormatter;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * BookingServlet — handles all booking-related requests.
 *
 * <p>URL patterns:
 * <ul>
 *   <li>{@code GET  /BookingServlet}  — availability check (from quick-book bar)
 *   <li>{@code POST /BookingServlet}  — submit new reservation (from booking.jsp)
 * </ul>
 *
 * <p>Admin actions sent via {@code action} parameter:
 * <ul>
 *   <li>{@code confirm} — mark a pending booking as Confirmed
 *   <li>{@code cancel}  — mark a booking as Cancelled
 *   <li>{@code delete}  — hard-delete a booking (admin only)
 * </ul>
 */
@WebServlet("/booking")
public class BookingServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(BookingServlet.class.getName());

    /** GST rate applied to room charges */
    private static final BigDecimal TAX_RATE = new BigDecimal("0.12");

    // ── SQL ───────────────────────────────────────────────────────────────────

    /** Find a room by its type name */
    private static final String SQL_FIND_ROOM_BY_TYPE =
            "SELECT r.id,r.room_number,r.rate_per_night FROM rooms r " +
                    "WHERE r.room_type=? AND r.status<>'Maintenance' " +
                    "AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.room_id=r.id " +
                    "AND b.status IN ('Confirmed','Pending','Checked-In') " +
                    "AND NOT (b.checkout_date<=? OR b.checkin_date>=?)) " +
                    "ORDER BY r.id LIMIT 1 FOR UPDATE";

    /** Overlap check: any confirmed/pending booking for this room in the date range? */
    private static final String SQL_OVERLAP =
            "SELECT COUNT(*) FROM bookings " +
                    "WHERE room_id = ? " +
                    "  AND status IN ('Confirmed','Pending','Checked-In') " +
                    "  AND NOT (checkout_date <= ? OR checkin_date >= ?)";

    /** Insert a new booking */
    private static final String SQL_INSERT_BOOKING =
            "INSERT INTO bookings " +
                    "  (booking_ref, user_id, room_id, " +
                    "   guest_first, guest_last, guest_email, guest_phone, " +
                    "   checkin_date, checkout_date, adults, children, nights, " +
                    "   rate_per_night, subtotal, tax_amount, total_amount, " +
                    "   special_requests, status) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'Pending')";

    /** Admin: update booking status */
    private static final String SQL_UPDATE_STATUS =
            "UPDATE bookings SET status=? WHERE booking_ref=?";

    /** Admin: free up room when booking is cancelled */
    private static final String CSRF_ATTRIBUTE = "csrfToken";

    // ── GET — availability / pre-fill ─────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = sanitise(req.getParameter("action"));

        if ("admin-list".equals(action)) {
            loadAdminBookings(req, resp);
            return;
        }
        if ("export".equals(action)) {
            HttpSession session = req.getSession(false);
            if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN);
                return;
            }
            if (!"csv".equalsIgnoreCase(sanitise(req.getParameter("format")))) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            exportBookings(resp);
            return;
        }
        if (!action.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Booking changes require POST.");
            return;
        }

        // Otherwise: pass checkin, checkout, guests through to booking.jsp
        String checkin  = sanitise(req.getParameter("checkin"));
        String checkout = sanitise(req.getParameter("checkout"));
        String room     = sanitise(req.getParameter("room"));

        req.setAttribute("preCheckin",  checkin);
        req.setAttribute("preCheckout", checkout);
        req.setAttribute("preRoom",     room);
        req.setAttribute("csrfToken", ensureCsrfToken(req.getSession(true)));

        req.getRequestDispatcher("/booking.jsp").forward(req, resp);
    }

    private void loadAdminBookings(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
            return;
        }
        request.setAttribute("bookingCsrfToken", ensureCsrfToken(session));
        String actionStatus = sanitise(request.getParameter("status"));
        if ("refundRecorded".equals(actionStatus))
            request.setAttribute("bookingActionSuccess", "Refund reference recorded and booking cancelled.");
        else if ("actionFailed".equals(actionStatus))
            request.setAttribute("bookingActionError", "The booking action could not be completed. Verify the refund reference and booking state.");
        List<Map<String, Object>> rows = new ArrayList<>();
        Map<String, Integer> counts = new HashMap<>();
        String sql = "SELECT b.booking_ref,b.guest_first,b.guest_last,b.checkin_date,b.checkout_date," +
                "b.nights,b.adults,b.children,b.total_amount,b.status,r.room_type,r.room_number," +
                "(SELECT p.payment_status FROM payments p WHERE p.booking_id=b.id ORDER BY p.id DESC LIMIT 1) AS payment_status," +
                "(SELECT p.razorpay_payment_id FROM payments p WHERE p.booking_id=b.id ORDER BY p.id DESC LIMIT 1) AS payment_id," +
                "(SELECT p.payment_method FROM payments p WHERE p.booking_id=b.id ORDER BY p.id DESC LIMIT 1) AS payment_method," +
                "(SELECT p.refund_reference FROM payments p WHERE p.booking_id=b.id ORDER BY p.id DESC LIMIT 1) AS refund_reference " +
                "FROM bookings b JOIN rooms r ON r.id=b.room_id ORDER BY b.created_at DESC,b.id DESC";
        DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);
        NumberFormat moneyFormat = NumberFormat.getNumberInstance(new Locale("en", "IN"));
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                Map<String, Object> row = new HashMap<>();
                String status = result.getString("status");
                String payment = result.getString("payment_status");
                if (payment == null) payment = "none";
                else if ("created".equalsIgnoreCase(payment) || "attempted".equalsIgnoreCase(payment)) payment = "pending";
                java.sql.Date checkin = result.getDate("checkin_date");
                java.sql.Date checkout = result.getDate("checkout_date");
                row.put("ref", result.getString("booking_ref"));
                row.put("guest", (result.getString("guest_first") + " " + result.getString("guest_last")).trim());
                row.put("room", result.getString("room_type") + " · " + result.getString("room_number"));
                row.put("checkin", dateFormat.format(checkin.toLocalDate()));
                row.put("checkout", dateFormat.format(checkout.toLocalDate()));
                row.put("checkinIso", checkin.toString());
                row.put("nights", result.getInt("nights"));
                row.put("guests", result.getInt("adults") + " Adults" +
                        (result.getInt("children") == 0 ? "" : ", " + result.getInt("children") + " Children"));
                row.put("amount", "₹" + moneyFormat.format(result.getBigDecimal("total_amount")));
                row.put("status", status);
                row.put("payment", payment);
                row.put("paymentId", result.getString("payment_id") == null ? "—" : result.getString("payment_id"));
                row.put("paymentMethod", result.getString("payment_method") == null ? "—" : result.getString("payment_method"));
                row.put("canCancel", "Pending".equals(status) && !"captured".equalsIgnoreCase(payment));
                row.put("canRefund", "captured".equalsIgnoreCase(payment)
                        && ("Confirmed".equals(status) || "Pending".equals(status))
                        && checkin.toLocalDate().isAfter(LocalDate.now()));
                row.put("refundReference", result.getString("refund_reference"));
                rows.add(row);
                counts.merge(status, 1, Integer::sum);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load admin bookings", e);
            request.setAttribute("bookingLoadError", "Bookings could not be loaded. Please try again.");
        }
        request.setAttribute("adminBookings", rows);
        request.setAttribute("bookingCounts", counts);
        request.getRequestDispatcher("/admin/manage-booking.jsp").forward(request, response);
    }

    // ── POST — create booking ─────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String action = sanitise(req.getParameter("action"));
        if ("confirm".equals(action) || "cancel".equals(action) || "refund-cancel".equals(action)) {
            HttpSession admin = req.getSession(false);
            if (admin == null || !"admin".equals(admin.getAttribute("userRole"))
                    || !validCsrf(admin, req.getParameter("_csrf"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid session or form token.");
                return;
            }
            handleAdminAction(req, resp, action);
            return;
        }
        HttpSession guestSession = req.getSession(false);
        if ("guest-cancel".equals(action)) {
            if (guestSession == null || !"guest".equals(guestSession.getAttribute("userRole"))
                    || !(guestSession.getAttribute("userId") instanceof Integer)
                    || !validCsrf(guestSession, req.getParameter("_csrf"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid session or form token.");
                return;
            }
            handleGuestCancel(req, resp, (Integer) guestSession.getAttribute("userId"));
            return;
        }
        if (guestSession == null || !validCsrf(guestSession, req.getParameter("_csrf"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
            return;
        }

        // 1. Read form fields (names match booking.jsp)
        String roomType     = sanitise(req.getParameter("roomType"));
        String checkinStr   = sanitise(req.getParameter("checkin"));
        String checkoutStr  = sanitise(req.getParameter("checkout"));
        String adultsStr    = sanitise(req.getParameter("adults"));
        String childrenStr  = sanitise(req.getParameter("children"));
        String guestFirst   = sanitise(req.getParameter("guestFirst"));
        String guestLast    = sanitise(req.getParameter("guestLast"));
        String guestEmail   = sanitise(req.getParameter("guestEmail")).toLowerCase();
        String guestPhone   = sanitise(req.getParameter("guestPhone"));
        String specialReqs  = sanitise(req.getParameter("specialReq"));

        // 2. Validate required fields
        String validErr = validateBookingFields(
                roomType, checkinStr, checkoutStr, guestFirst, guestLast, guestEmail);
        if (validErr != null) {
            req.setAttribute("error", validErr);
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
            return;
        }

        // 3. Parse dates
        LocalDate checkin, checkout;
        try {
            checkin  = LocalDate.parse(checkinStr);
            checkout = LocalDate.parse(checkoutStr);
        } catch (DateTimeParseException e) {
            req.setAttribute("error", "Invalid date format. Please use the date picker.");
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
            return;
        }

        if (!checkout.isAfter(checkin)) {
            req.setAttribute("error", "Check-out date must be after check-in date.");
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
            return;
        }

        if (checkin.isBefore(LocalDate.now())) {
            req.setAttribute("error", "Check-in date cannot be in the past.");
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
            return;
        }

        long nights   = ChronoUnit.DAYS.between(checkin, checkout);
        int  adults   = parseIntSafe(adultsStr,   1);
        int  children = parseIntSafe(childrenStr, 0);
        if (adults < 1 || adults > 8 || children < 0 || children > 6 || nights > 30) {
            req.setAttribute("error", "Guest count or stay length is outside the allowed range.");
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
            return;
        }

        // 4. DB transaction
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // 4a. Find an available room of the requested type
            int    roomId;
            String roomNumber;
            BigDecimal ratePerNight;

            try (PreparedStatement ps = conn.prepareStatement(SQL_FIND_ROOM_BY_TYPE)) {
                ps.setString(1, toRoomTypeName(roomType));
                ps.setDate(2, Date.valueOf(checkin));
                ps.setDate(3, Date.valueOf(checkout));
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) {
                    conn.rollback();
                    req.setAttribute("error",
                            "Sorry, no " + toRoomTypeName(roomType) +
                                    " rooms are currently available for your dates. " +
                                    "Please choose a different room type or dates.");
                    req.getRequestDispatcher("/booking.jsp").forward(req, resp);
                    return;
                }
                roomId      = rs.getInt("id");
                roomNumber  = rs.getString("room_number");
                ratePerNight = rs.getBigDecimal("rate_per_night");
            }

            // 4b. Double-check date overlap for this specific room
            try (PreparedStatement ps = conn.prepareStatement(SQL_OVERLAP)) {
                ps.setInt(1, roomId);
                ps.setDate(2, Date.valueOf(checkin));
                ps.setDate(3, Date.valueOf(checkout));
                ResultSet rs = ps.executeQuery();
                rs.next();
                if (rs.getInt(1) > 0) {
                    conn.rollback();
                    req.setAttribute("error",
                            "That room is already booked for the selected dates. " +
                                    "Please try different dates.");
                    req.getRequestDispatcher("/booking.jsp").forward(req, resp);
                    return;
                }
            }

            // 4c. Calculate amounts
            BigDecimal subtotal    = ratePerNight.multiply(BigDecimal.valueOf(nights));
            BigDecimal taxAmount   = subtotal.multiply(TAX_RATE)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal totalAmount = subtotal.add(taxAmount);

            String bookingRef = "GH-" + UUID.randomUUID().toString().replace("-", "")
                    .substring(0, 16).toUpperCase(Locale.ROOT);

            // 4e. Resolve user_id from session (null if not logged in)
            HttpSession session = req.getSession(false);
            Integer userId = session != null && session.getAttribute("userId") instanceof Integer
                    ? (Integer) session.getAttribute("userId") : null;

            // 4f. Insert booking
            int bookingId;
            try (PreparedStatement ps = conn.prepareStatement(
                    SQL_INSERT_BOOKING, Statement.RETURN_GENERATED_KEYS)) {

                ps.setString(1,  bookingRef);
                if (userId != null) ps.setInt(2, userId);
                else                ps.setNull(2, Types.INTEGER);
                ps.setInt   (3,  roomId);
                ps.setString(4,  guestFirst);
                ps.setString(5,  guestLast);
                ps.setString(6,  guestEmail);
                ps.setString(7,  guestPhone.isEmpty() ? null : guestPhone);
                ps.setDate  (8,  Date.valueOf(checkin));
                ps.setDate  (9,  Date.valueOf(checkout));
                ps.setInt   (10, adults);
                ps.setInt   (11, children);
                ps.setLong  (12, nights);
                ps.setBigDecimal(13, ratePerNight);
                ps.setBigDecimal(14, subtotal);
                ps.setBigDecimal(15, taxAmount);
                ps.setBigDecimal(16, totalAmount);
                ps.setString(17, specialReqs.isEmpty() ? null : specialReqs);

                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) throw new SQLException("Booking ID was not returned.");
                    bookingId = keys.getInt(1);
                }
            }

            conn.commit();
            LOG.info("Booking created — ref=" + bookingRef
                    + " room=" + roomNumber
                    + " guest=" + guestFirst + " " + guestLast);

            if (session == null) session = req.getSession(true);
            session.setAttribute("pendingBookingId", bookingId);
            session.setAttribute("pendingBookingRef", bookingRef);
            session.setAttribute("pendingRoomType", toRoomTypeName(roomType));
            session.setAttribute("pendingRoomNumber", roomNumber);
            session.setAttribute("pendingCheckin", checkin.toString());
            session.setAttribute("pendingCheckout", checkout.toString());
            session.setAttribute("pendingNights", nights);
            session.setAttribute("pendingTotal", totalAmount);
            session.setAttribute("pendingGuestName", guestFirst + " " + guestLast);
            session.setAttribute("pendingGuestEmail", guestEmail);
            session.setAttribute("pendingGuestPhone", guestPhone);
            resp.sendRedirect(req.getContextPath() + "/payment.jsp");

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "BookingServlet DB error", e);
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { /* ignore */ }
            }
            req.setAttribute("error",
                    "A server error occurred while processing your booking. Please try again.");
            req.getRequestDispatcher("/booking.jsp").forward(req, resp);
        } finally {
            DBConnection.close(conn);
        }
    }

    // ── Admin action handler ──────────────────────────────────────────────────

    private void handleAdminAction(HttpServletRequest req, HttpServletResponse resp, String action)
            throws IOException {
        String ref = sanitise(req.getParameter("ref"));
        String result = "updated";
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int bookingId;
                String status;
                boolean paid;
                java.sql.Date checkinDate;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT b.id,b.status,b.checkin_date,EXISTS(SELECT 1 FROM payments p WHERE p.booking_id=b.id " +
                        "AND p.payment_status='captured') AS paid FROM bookings b WHERE b.booking_ref=? FOR UPDATE")) {
                    ps.setString(1, ref);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new SQLException("Booking not found.");
                        bookingId = rs.getInt("id");
                        status = rs.getString("status");
                        paid = rs.getBoolean("paid");
                        checkinDate = rs.getDate("checkin_date");
                    }
                }
                if ("confirm".equals(action)) {
                    if (!paid || !"Pending".equals(status)) throw new SQLException("Only paid pending bookings can be confirmed.");
                    updateBookingStatus(conn, "Confirmed", ref);
                } else if ("cancel".equals(action)) {
                    if (paid) throw new SQLException("A captured payment must be refunded before cancellation.");
                    if (!"Pending".equals(status)) throw new SQLException("Only unpaid pending bookings can be cancelled here.");
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE payments SET payment_status='failed',failure_reason='Booking cancelled by hotel',updated_at=NOW() " +
                            "WHERE booking_id=? AND payment_status='created'")) {
                        ps.setInt(1, bookingId);
                        ps.executeUpdate();
                    }
                    updateBookingStatus(conn, "Cancelled", ref);
                } else if ("refund-cancel".equals(action)) {
                    String refundReference = sanitise(req.getParameter("refundReference"));
                    if (!refundReference.matches("rfnd_[A-Za-z0-9]+"))
                        throw new SQLException("Enter the completed Razorpay refund ID.");
                    if (!paid || !("Confirmed".equals(status) || "Pending".equals(status))
                            || !checkinDate.toLocalDate().isAfter(LocalDate.now()))
                        throw new SQLException("Only future bookings with a captured payment can be cancelled with a refund.");
                    int paymentId;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "SELECT id FROM payments WHERE booking_id=? AND payment_status='captured' " +
                                    "ORDER BY id DESC LIMIT 1 FOR UPDATE")) {
                        ps.setInt(1, bookingId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new SQLException("Captured payment was not found.");
                            paymentId = rs.getInt(1);
                        }
                    }
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE payments SET payment_status='refunded',refund_reference=?,refund_processed_at=NOW(),updated_at=NOW() " +
                                    "WHERE id=? AND payment_status='captured'")) {
                        ps.setString(1, refundReference);
                        ps.setInt(2, paymentId);
                        if (ps.executeUpdate() != 1) throw new SQLException("Payment refund was already recorded or changed.");
                    }
                    updateBookingStatus(conn, "Cancelled", ref);
                    result = "refundRecorded";
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Admin booking action failed for " + ref, e);
            result = "actionFailed";
        }
        resp.sendRedirect(req.getContextPath() + "/booking?action=admin-list&status=" + result);
    }

    private void updateBookingStatus(Connection conn, String newStatus, String ref)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_STATUS)) {
            ps.setString(1, newStatus);
            ps.setString(2, ref);
            if (ps.executeUpdate() != 1) throw new SQLException("Booking status was not updated.");
        }
    }

    private void handleGuestCancel(HttpServletRequest req, HttpServletResponse resp, int userId)
            throws IOException {
        String ref = sanitise(req.getParameter("ref"));
        String status = "cancelled";
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int bookingId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT id FROM bookings WHERE booking_ref=? AND user_id=? AND status='Pending' " +
                                "AND checkin_date>CURRENT_DATE AND NOT EXISTS " +
                                "(SELECT 1 FROM payments p WHERE p.booking_id=bookings.id AND p.payment_status='captured') FOR UPDATE")) {
                    ps.setString(1, ref);
                    ps.setInt(2, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) throw new SQLException("Booking is not eligible for cancellation.");
                        bookingId = rs.getInt(1);
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE payments SET payment_status='failed',failure_reason='Cancelled by guest',updated_at=NOW() " +
                                "WHERE booking_id=? AND payment_status='created'")) {
                    ps.setInt(1, bookingId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE bookings SET status='Cancelled' WHERE id=? AND status='Pending'")) {
                    ps.setInt(1, bookingId);
                    if (ps.executeUpdate() != 1) throw new SQLException("Booking was not cancelled.");
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                status = "cancelFailed";
                LOG.log(Level.WARNING, "Guest booking cancellation failed", e);
            }
        } catch (SQLException e) {
            status = "cancelFailed";
            LOG.log(Level.SEVERE, "Could not cancel guest booking", e);
        }
        resp.sendRedirect(req.getContextPath() + "/user-dashboard?status=" + status);
    }

    private void exportBookings(HttpServletResponse response) throws IOException {
        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=bookings.csv");
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement ps = connection.prepareStatement(
                     "SELECT b.booking_ref,b.guest_first,b.guest_last,b.guest_email,b.checkin_date,b.checkout_date," +
                             "b.total_amount,b.status FROM bookings b ORDER BY b.created_at DESC");
             ResultSet rs = ps.executeQuery();
             java.io.PrintWriter out = response.getWriter()) {
            out.println("Reference,Guest,Email,Check-in,Check-out,Total,Status");
            while (rs.next()) {
                csv(out, rs.getString("booking_ref"));
                csv(out, rs.getString("guest_first") + " " + rs.getString("guest_last"));
                csv(out, rs.getString("guest_email"));
                csv(out, rs.getDate("checkin_date").toString());
                csv(out, rs.getDate("checkout_date").toString());
                csv(out, rs.getBigDecimal("total_amount").toPlainString());
                csv(out, rs.getString("status"), true);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not export bookings", e);
            if (!response.isCommitted()) response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private static void csv(java.io.PrintWriter out, String value) { csv(out, value, false); }
    private static void csv(java.io.PrintWriter out, String value, boolean last) {
        String safe = value == null ? "" : value;
        if (safe.matches("^[\\s]*[=+@\\-].*")) safe = "'" + safe;
        out.print('"');
        out.print(safe.replace("\"", "\"\""));
        out.print(last ? "\r\n" : ",");
    }

    private static String ensureCsrfToken(HttpSession session) {
        Object value = session.getAttribute(CSRF_ATTRIBUTE);
        if (value instanceof String && !((String) value).isEmpty()) return (String) value;
        String token = UUID.randomUUID().toString();
        session.setAttribute(CSRF_ATTRIBUTE, token);
        return token;
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        Object expected = session.getAttribute(CSRF_ATTRIBUTE);
        return expected instanceof String && supplied != null &&
                java.security.MessageDigest.isEqual(((String) expected).getBytes(java.nio.charset.StandardCharsets.UTF_8),
                        supplied.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Maps the URL-friendly room param (e.g. "junior-suite") to the
     * ENUM value stored in the DB (e.g. "Junior Suite").
     */
    private static String toRoomTypeName(String param) {
        if (param == null) return "";
        switch (param.toLowerCase().trim()) {
            case "deluxe":          return "Deluxe Room";
            case "twin":            return "Twin Room";
            case "family":         return "Family Suite";
            case "junior-suite":   return "Junior Suite";
            case "executive":      return "Executive Suite";
            case "presidential":   return "Presidential Suite";
            default:               return param; // already a full name from the form
        }
    }

    private String validateBookingFields(String roomType, String checkin,
                                         String checkout, String firstName,
                                         String lastName,  String email) {
        if (isEmpty(roomType))   return "Please select a room type.";
        if (isEmpty(checkin))    return "Check-in date is required.";
        if (isEmpty(checkout))   return "Check-out date is required.";
        if (isEmpty(firstName))  return "Guest first name is required.";
        if (isEmpty(lastName))   return "Guest last name is required.";
        if (isEmpty(email))      return "Guest email is required.";
        return null;
    }

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(s); } catch (Exception e) { return fallback; }
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}
