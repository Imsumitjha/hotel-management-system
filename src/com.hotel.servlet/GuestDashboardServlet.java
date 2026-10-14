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
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.text.NumberFormat;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Loads the signed-in guest's booking dashboard from the database. */
@WebServlet("/user-dashboard")
public class GuestDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(GuestDashboardServlet.class.getName());
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !(session.getAttribute("userId") instanceof Integer)
                || !"guest".equals(session.getAttribute("userRole"))) {
            if (session != null && "admin".equals(session.getAttribute("userRole"))) {
                response.sendRedirect(request.getContextPath() + "/admin");
            } else {
                request.getSession(true).setAttribute("redirectAfterLogin", request.getContextPath() + "/user-dashboard");
                response.sendRedirect(request.getContextPath() + "/login.jsp");
            }
            return;
        }
        int userId = (Integer) session.getAttribute("userId");
        String csrf = (String) session.getAttribute("csrfToken");
        if (csrf == null) {
            csrf = java.util.UUID.randomUUID().toString();
            session.setAttribute("csrfToken", csrf);
        }
        request.setAttribute("csrfToken", csrf);

        List<Map<String, Object>> bookings = new ArrayList<>();
        Map<String, Object> upcoming = null;
        int upcomingCount = 0;
        long nightsStayed = 0;
        BigDecimal totalSpent = BigDecimal.ZERO;
        int totalBookings = 0;
        String memberSince = "";
        String sql = "SELECT b.booking_ref,b.checkin_date,b.checkout_date,b.nights,b.adults,b.children," +
                "b.total_amount,b.status,r.room_type,r.room_number,r.floor," +
                "EXISTS(SELECT 1 FROM payments p WHERE p.booking_id=b.id AND p.payment_status='captured') AS has_captured_payment " +
                "FROM bookings b JOIN rooms r ON r.id=b.room_id WHERE b.user_id=? " +
                "ORDER BY b.created_at DESC,b.id DESC";
        try (Connection connection = DBConnection.getConnection()) {
            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT first_name,last_name,email,created_at FROM users WHERE id=? AND role='guest'")) {
                statement.setInt(1, userId);
                try (ResultSet row = statement.executeQuery()) {
                    if (!row.next()) {
                        session.invalidate();
                        response.sendRedirect(request.getContextPath() + "/login.jsp");
                        return;
                    }
                    request.setAttribute("dashboardFirstName", row.getString("first_name"));
                    request.setAttribute("dashboardName", row.getString("first_name") + " " + row.getString("last_name"));
                    request.setAttribute("dashboardEmail", row.getString("email"));
                    java.sql.Timestamp joined = row.getTimestamp("created_at");
                    memberSince = joined == null ? "" : joined.toLocalDateTime().toLocalDate().format(DATE);
                }
            }
            try (PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, userId);
                try (ResultSet row = statement.executeQuery()) {
                    while (row.next()) {
                        Map<String, Object> item = new HashMap<>();
                        String status = row.getString("status");
                        LocalDate checkin = row.getDate("checkin_date").toLocalDate();
                        LocalDate checkout = row.getDate("checkout_date").toLocalDate();
                        BigDecimal amount = row.getBigDecimal("total_amount");
                        boolean captured = row.getBoolean("has_captured_payment");
                        item.put("ref", row.getString("booking_ref"));
                        item.put("room", row.getString("room_type"));
                        item.put("roomNumber", row.getString("room_number"));
                        item.put("floor", row.getString("floor"));
                        item.put("checkin", DATE.format(checkin));
                        item.put("checkout", DATE.format(checkout));
                        item.put("checkinIso", checkin.toString());
                        item.put("nights", row.getInt("nights"));
                        item.put("guests", row.getInt("adults") + " Adult" + (row.getInt("adults") == 1 ? "" : "s") +
                                (row.getInt("children") > 0 ? ", " + row.getInt("children") + " Children" : ""));
                        item.put("total", "₹" + NumberFormat.getNumberInstance(new Locale("en", "IN")).format(amount));
                        item.put("status", status);
                        item.put("filterStatus", "Pending".equals(status) ? "pending" : "Cancelled".equals(status) ? "cancelled" : "confirmed");
                        item.put("statusClass", "Pending".equals(status) ? "pending" : "Cancelled".equals(status) ? "cancelled" : "confirmed");
                        item.put("paymentStatus", captured ? "captured" : "unpaid");
                        boolean canCancel = "Pending".equals(status) && checkin.isAfter(LocalDate.now())
                                && !captured;
                        item.put("canCancel", canCancel);
                        bookings.add(item);
                        totalBookings++;
                        if (checkin.isAfter(LocalDate.now()) &&
                                ("Pending".equals(status) || "Confirmed".equals(status) || "Checked-In".equals(status))) {
                            upcomingCount++;
                            if (upcoming == null) upcoming = item;
                        }
                        if ("Checked-Out".equals(status)) nightsStayed += row.getInt("nights");
                        if (captured && amount != null) totalSpent = totalSpent.add(amount);
                    }
                }
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load guest dashboard for userId=" + userId, e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load your dashboard.");
            return;
        }
        request.setAttribute("dashboardBookings", bookings);
        request.setAttribute("upcomingBooking", upcoming);
        request.setAttribute("upcomingCount", upcomingCount);
        request.setAttribute("totalBookings", totalBookings);
        request.setAttribute("nightsStayed", nightsStayed);
        request.setAttribute("totalSpent", "₹" + NumberFormat.getNumberInstance(new Locale("en", "IN")).format(totalSpent));
        request.setAttribute("memberSince", memberSince);
        request.getRequestDispatcher("/user-dashboard.jsp").forward(request, response);
    }
}
