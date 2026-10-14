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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Admin dashboard controller and compatibility route for the old /admin URL. */
@WebServlet("/admin")
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(AdminServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if ("logout".equalsIgnoreCase(request.getParameter("action"))) {
            response.sendRedirect(request.getContextPath() + "/logout");
            return;
        }
        if (session == null || !"admin".equalsIgnoreCase(
                String.valueOf(session.getAttribute("userRole")))) {
            response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
            return;
        }

        request.setAttribute("adminDashboardLoaded", Boolean.TRUE);
        Map<String, Object> stats = new HashMap<>();
        List<Map<String, Object>> recentBookings = new ArrayList<>();
        List<Map<String, Object>> dashboardRooms = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection()) {
            stats.put("bookingCount", scalar(conn, "SELECT COUNT(*) FROM bookings"));
            stats.put("pendingCount", scalar(conn,
                    "SELECT COUNT(*) FROM bookings WHERE status = 'Pending'"));
            stats.put("roomCount", scalar(conn, "SELECT COUNT(*) FROM rooms"));
            stats.put("availableRooms", scalar(conn,
                    "SELECT COUNT(*) FROM rooms WHERE status = 'Available'"));
            stats.put("capturedRevenue", decimal(conn,
                    "SELECT COALESCE(SUM(amount_paise), 0) / 100.0 FROM payments WHERE payment_status = 'captured'"));
            stats.put("userCount", scalar(conn,
                    "SELECT COUNT(*) FROM users WHERE role = 'guest'"));
            stats.put("suspendedUsers", scalar(conn,
                    "SELECT COUNT(*) FROM users WHERE role = 'guest' AND is_suspended = 1"));

            String recentSql = "SELECT b.booking_ref, b.guest_first, b.guest_last, r.room_type, " +
                    "b.checkin_date, b.checkout_date, b.total_amount, b.status, " +
                    "COALESCE((SELECT p.payment_status FROM payments p WHERE p.booking_id = b.id " +
                    "ORDER BY p.created_at DESC, p.id DESC LIMIT 1), 'unpaid') AS payment_status " +
                    "FROM bookings b JOIN rooms r ON r.id = b.room_id " +
                    "ORDER BY b.created_at DESC, b.id DESC LIMIT 8";
            try (PreparedStatement ps = conn.prepareStatement(recentSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("bookingRef", rs.getString("booking_ref"));
                    row.put("guest", (rs.getString("guest_first") + " " + rs.getString("guest_last")).trim());
                    row.put("roomType", rs.getString("room_type"));
                    row.put("checkin", rs.getDate("checkin_date"));
                    row.put("checkout", rs.getDate("checkout_date"));
                    row.put("total", rs.getBigDecimal("total_amount"));
                    row.put("status", rs.getString("status"));
                    row.put("paymentStatus", rs.getString("payment_status"));
                    recentBookings.add(row);
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT room_number, room_type, status FROM rooms ORDER BY room_number LIMIT 8");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("number", rs.getString("room_number"));
                    row.put("type", rs.getString("room_type"));
                    row.put("status", rs.getString("status"));
                    dashboardRooms.add(row);
                }
            }
            request.setAttribute("adminStats", stats);
            request.setAttribute("recentBookings", recentBookings);
            request.setAttribute("dashboardRooms", dashboardRooms);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load admin dashboard", e);
            request.setAttribute("adminDashboardError", Boolean.TRUE);
            request.setAttribute("adminStats", stats);
            request.setAttribute("recentBookings", recentBookings);
            request.setAttribute("dashboardRooms", dashboardRooms);
        }
        request.getRequestDispatcher("/admin/dashboard.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/adminlogin").forward(request, response);
    }

    private int scalar(Connection conn, String sql) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    private BigDecimal decimal(Connection conn, String sql) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            BigDecimal value = rs.next() ? rs.getBigDecimal(1) : null;
            return value == null ? BigDecimal.ZERO : value;
        }
    }
}
