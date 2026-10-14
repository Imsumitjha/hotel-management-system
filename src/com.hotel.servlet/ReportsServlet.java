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
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Database-backed admin reports. Revenue is shown as capture, refund, and net activity. */
@WebServlet("/admin/reports")
public class ReportsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ReportsServlet.class.getName());
    private static final int MAX_RANGE_DAYS = 366;
    private static final String BUSINESS_ZONE_ENV = "HOTEL_TIME_ZONE";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
            return;
        }

        ZoneId businessZone;
        try {
            businessZone = ZoneId.of(System.getenv().getOrDefault(BUSINESS_ZONE_ENV, "Asia/Kolkata"));
        } catch (RuntimeException invalidZone) {
            LOG.log(Level.SEVERE, "Invalid HOTEL_TIME_ZONE configuration", invalidZone);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "The reporting time zone is not configured correctly.");
            return;
        }
        LocalDate today = LocalDate.now(businessZone);
        LocalDate from = parseDate(request.getParameter("from"), today.minusDays(29));
        LocalDate to = parseDate(request.getParameter("to"), today);
        if (from == null || to == null || to.isBefore(from)
                || from.isBefore(to.minusDays(MAX_RANGE_DAYS - 1L))) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Choose a valid date range of no more than 366 days.");
            return;
        }

        List<Map<String, Object>> daily;
        List<Map<String, Object>> roomRevenue;
        Map<String, Long> bookingStatuses;
        try (Connection connection = DBConnection.getConnection()) {
            connection.setReadOnly(true);
            connection.setTransactionIsolation(Connection.TRANSACTION_REPEATABLE_READ);
            connection.setAutoCommit(false);
            daily = loadDailyActivity(connection, from, to);
            roomRevenue = loadRoomActivity(connection, from, to);
            bookingStatuses = loadBookingStatuses(connection, from, to);
            connection.commit();
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load admin reports", e);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                    "Reports are temporarily unavailable.");
            return;
        }

        BigDecimal grossCaptures = sum(daily, "captures");
        BigDecimal refunds = sum(daily, "refunds");
        BigDecimal net = grossCaptures.subtract(refunds);
        long captureCount = count(daily, "captureCount");
        long refundCount = count(daily, "refundCount");
        long bookingCount = bookingStatuses.values().stream().mapToLong(Long::longValue).sum();

        if ("csv".equalsIgnoreCase(request.getParameter("export"))) {
            exportCsv(response, from, to, daily, roomRevenue, bookingStatuses);
            return;
        }
        request.setAttribute("from", from.toString());
        request.setAttribute("to", to.toString());
        request.setAttribute("businessZone", businessZone.getId());
        request.setAttribute("dailyRevenue", daily);
        request.setAttribute("roomRevenue", roomRevenue);
        request.setAttribute("bookingStatuses", bookingStatuses);
        request.setAttribute("grossCaptures", grossCaptures);
        request.setAttribute("refundTotal", refunds);
        request.setAttribute("netRevenue", net);
        request.setAttribute("captureCount", captureCount);
        request.setAttribute("refundCount", refundCount);
        request.setAttribute("bookingCount", bookingCount);
        request.getRequestDispatcher("/admin/reports.jsp").forward(request, response);
    }

    private static LocalDate parseDate(String value, LocalDate fallback) {
        if (value == null || value.isEmpty()) return fallback;
        try { return LocalDate.parse(value); }
        catch (DateTimeParseException invalid) { return null; }
    }

    private List<Map<String, Object>> loadDailyActivity(Connection connection, LocalDate from, LocalDate to)
            throws SQLException {
        Map<LocalDate, Totals> totals = new TreeMap<>();
        String capturesSql = "SELECT DATE(captured_at) AS event_day, COUNT(*) AS event_count, " +
                "COALESCE(SUM(amount_paise),0) AS amount FROM payments " +
                "WHERE currency='INR' AND captured_at IS NOT NULL AND captured_at >= ? " +
                "AND captured_at < DATE_ADD(?, INTERVAL 1 DAY) GROUP BY DATE(captured_at) ORDER BY event_day";
        try (PreparedStatement statement = connection.prepareStatement(capturesSql)) {
            setDateRange(statement, from, to);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    LocalDate day = result.getDate("event_day").toLocalDate();
                    Totals row = totals.computeIfAbsent(day, ignored -> new Totals());
                    row.addCaptures(result.getLong("event_count"), paise(result.getLong("amount")));
                }
            }
        }
        String refundsSql = "SELECT DATE(refund_processed_at) AS event_day, COUNT(*) AS event_count, " +
                "COALESCE(SUM(amount_paise),0) AS amount FROM payments " +
                "WHERE currency='INR' AND payment_status='refunded' AND refund_processed_at IS NOT NULL " +
                "AND refund_processed_at >= ? AND refund_processed_at < DATE_ADD(?, INTERVAL 1 DAY) " +
                "GROUP BY DATE(refund_processed_at) ORDER BY event_day";
        try (PreparedStatement statement = connection.prepareStatement(refundsSql)) {
            setDateRange(statement, from, to);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    LocalDate day = result.getDate("event_day").toLocalDate();
                    Totals row = totals.computeIfAbsent(day, ignored -> new Totals());
                    row.addRefunds(result.getLong("event_count"), paise(result.getLong("amount")));
                }
            }
        }
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Map.Entry<LocalDate, Totals> entry : totals.entrySet()) {
            rows.add(toMap("day", entry.getKey().toString(), entry.getValue()));
        }
        return rows;
    }

    private List<Map<String, Object>> loadRoomActivity(Connection connection, LocalDate from, LocalDate to)
            throws SQLException {
        Map<String, Totals> totals = new LinkedHashMap<>();
        String capturesSql = "SELECT r.room_type, COUNT(*) AS event_count, COALESCE(SUM(p.amount_paise),0) AS amount " +
                "FROM payments p JOIN bookings b ON b.id=p.booking_id JOIN rooms r ON r.id=b.room_id " +
                "WHERE p.currency='INR' AND p.captured_at IS NOT NULL AND p.captured_at >= ? " +
                "AND p.captured_at < DATE_ADD(?, INTERVAL 1 DAY) GROUP BY r.room_type";
        try (PreparedStatement statement = connection.prepareStatement(capturesSql)) {
            setDateRange(statement, from, to);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) totals.computeIfAbsent(result.getString("room_type"), ignored -> new Totals())
                        .addCaptures(result.getLong("event_count"), paise(result.getLong("amount")));
            }
        }
        String refundsSql = "SELECT r.room_type, COUNT(*) AS event_count, COALESCE(SUM(p.amount_paise),0) AS amount " +
                "FROM payments p JOIN bookings b ON b.id=p.booking_id JOIN rooms r ON r.id=b.room_id " +
                "WHERE p.currency='INR' AND p.payment_status='refunded' AND p.refund_processed_at IS NOT NULL " +
                "AND p.refund_processed_at >= ? AND p.refund_processed_at < DATE_ADD(?, INTERVAL 1 DAY) " +
                "GROUP BY r.room_type";
        try (PreparedStatement statement = connection.prepareStatement(refundsSql)) {
            setDateRange(statement, from, to);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) totals.computeIfAbsent(result.getString("room_type"), ignored -> new Totals())
                        .addRefunds(result.getLong("event_count"), paise(result.getLong("amount")));
            }
        }
        List<Map<String, Object>> rows = new ArrayList<>();
        totals.forEach((roomType, value) -> rows.add(toMap("roomType", roomType, value)));
        rows.sort((left, right) -> ((BigDecimal) right.get("net")).compareTo((BigDecimal) left.get("net")));
        return rows;
    }

    private Map<String, Long> loadBookingStatuses(Connection connection, LocalDate from, LocalDate to)
            throws SQLException {
        String sql = "SELECT status, COUNT(*) AS booking_count FROM bookings " +
                "WHERE created_at >= ? AND created_at < DATE_ADD(?, INTERVAL 1 DAY) GROUP BY status ORDER BY status";
        Map<String, Long> counts = new LinkedHashMap<>();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            setDateRange(statement, from, to);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) counts.put(result.getString("status"), result.getLong("booking_count"));
            }
        }
        return counts;
    }

    private static void setDateRange(PreparedStatement statement, LocalDate from, LocalDate to) throws SQLException {
        statement.setDate(1, Date.valueOf(from));
        statement.setDate(2, Date.valueOf(to));
    }

    private static BigDecimal paise(long value) {
        return BigDecimal.valueOf(value, 2);
    }

    private static Map<String, Object> toMap(String key, Object keyValue, Totals totals) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put(key, keyValue);
        row.put("captureCount", totals.captureCount);
        row.put("captures", totals.captures);
        row.put("refundCount", totals.refundCount);
        row.put("refunds", totals.refunds);
        row.put("net", totals.captures.subtract(totals.refunds));
        return row;
    }

    private static BigDecimal sum(List<Map<String, Object>> rows, String field) {
        return rows.stream().map(row -> (BigDecimal) row.get(field))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static long count(List<Map<String, Object>> rows, String field) {
        return rows.stream().mapToLong(row -> (Long) row.get(field)).sum();
    }

    private void exportCsv(HttpServletResponse response, LocalDate from, LocalDate to,
                           List<Map<String, Object>> daily, List<Map<String, Object>> byRoom,
                           Map<String, Long> statuses) throws IOException {
        response.setContentType("text/csv; charset=UTF-8");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setHeader("Content-Disposition", "attachment; filename=hotel-report-" + from + "-to-" + to + ".csv");
        var writer = response.getWriter();
        writer.write("Report,Date range," + from + " to " + to + "\r\n\r\n");
        writer.write("Daily payment activity\r\nDate,Captured INR,Refunded INR,Net INR,Captures,Refunds\r\n");
        for (Map<String, Object> row : daily) {
            writer.write(csv(row.get("day")) + "," + row.get("captures") + "," + row.get("refunds") + "," +
                    row.get("net") + "," + row.get("captureCount") + "," + row.get("refundCount") + "\r\n");
        }
        writer.write("\r\nPayment activity by room type\r\nRoom type,Captured INR,Refunded INR,Net INR,Captures,Refunds\r\n");
        for (Map<String, Object> row : byRoom) {
            writer.write(csv(row.get("roomType")) + "," + row.get("captures") + "," + row.get("refunds") + "," +
                    row.get("net") + "," + row.get("captureCount") + "," + row.get("refundCount") + "\r\n");
        }
        writer.write("\r\nBookings by current status for booking creation date range\r\nStatus,Bookings\r\n");
        for (Map.Entry<String, Long> entry : statuses.entrySet()) {
            writer.write(csv(entry.getKey()) + "," + entry.getValue() + "\r\n");
        }
        writer.flush();
    }

    private static String csv(Object value) {
        String text = value == null ? "" : String.valueOf(value);
        return "\"" + text.replace("\"", "\"\"") + "\"";
    }

    private static final class Totals {
        private long captureCount;
        private long refundCount;
        private BigDecimal captures = BigDecimal.ZERO;
        private BigDecimal refunds = BigDecimal.ZERO;
        private void addCaptures(long count, BigDecimal amount) {
            captureCount += count;
            captures = captures.add(amount);
        }
        private void addRefunds(long count, BigDecimal amount) {
            refundCount += count;
            refunds = refunds.add(amount);
        }
    }
}
