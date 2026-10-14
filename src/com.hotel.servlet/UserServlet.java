package com.hotel.servlet;

import com.hotel.util.DBConnection;
import com.hotel.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
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
import java.util.regex.Pattern;

@WebServlet("/User")
public class UserServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(UserServlet.class.getName());
    private static final Pattern EMAIL = Pattern.compile("^[\\w._%+\\-]+@[\\w.\\-]+\\.[A-Za-z]{2,}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
            return;
        }
        if (session.getAttribute("csrfToken") == null) {
            session.setAttribute("csrfToken", java.util.UUID.randomUUID().toString());
        }

        List<Map<String, Object>> users = new ArrayList<>();
        String sql = "SELECT u.id, u.first_name, u.last_name, u.email, u.phone, u.role, " +
                "u.is_suspended, u.created_at, COUNT(b.id) AS booking_count, " +
                "COALESCE(SUM(CASE WHEN b.status <> 'Cancelled' THEN b.nights ELSE 0 END), 0) AS nights, " +
                "COALESCE(SUM(CASE WHEN b.status <> 'Cancelled' THEN b.total_amount ELSE 0 END), 0) AS total_spent " +
                "FROM users u LEFT JOIN bookings b ON b.user_id = u.id " +
                "GROUP BY u.id, u.first_name, u.last_name, u.email, u.phone, u.role, u.is_suspended, u.created_at " +
                "ORDER BY u.created_at DESC, u.id DESC";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rows = statement.executeQuery()) {
            while (rows.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rows.getInt("id"));
                user.put("firstName", rows.getString("first_name"));
                user.put("lastName", rows.getString("last_name"));
                user.put("email", rows.getString("email"));
                user.put("phone", rows.getString("phone"));
                user.put("role", rows.getString("role"));
                user.put("suspended", rows.getBoolean("is_suspended"));
                user.put("createdAt", rows.getTimestamp("created_at"));
                user.put("bookingCount", rows.getInt("booking_count"));
                user.put("nights", rows.getInt("nights"));
                user.put("totalSpent", rows.getBigDecimal("total_spent"));
                users.add(user);
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load admin users", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not load users. Please try again.");
            return;
        }
        request.setAttribute("users", users);
        request.getRequestDispatcher("/admin/manage-users.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        if (!(session.getAttribute("userId") instanceof Integer)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Administrator identity is missing. Please sign in again.");
            return;
        }
        if (!validCsrf(session, request.getParameter("_csrf"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
            return;
        }
        String action = request.getParameter("action");
        try {
            if ("add".equals(action)) addUser(request, response);
            else if ("edit".equals(action)) editUser(request, response, session);
            else if ("delete".equals(action)) deleteUser(request, response, session);
            else if ("suspend".equals(action)) setSuspended(request, response, session, true);
            else if ("reinstate".equals(action)) setSuspended(request, response, session, false);
            else if ("bulk-suspend".equals(action)) bulkAction(request, response, session, true);
            else if ("bulk-delete".equals(action)) bulkAction(request, response, session, false);
            else response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unsupported user action.");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, e.getMessage());
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Admin user action failed", e);
            if ("23000".equals(e.getSQLState())) {
                response.sendError(HttpServletResponse.SC_CONFLICT, "Email is already in use or this user has related records.");
            } else {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not save the user. Please try again.");
            }
        }
    }

    private void addUser(HttpServletRequest request, HttpServletResponse response) throws SQLException, IOException {
        UserForm form = readAndValidate(request, true);
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "INSERT INTO users (first_name,last_name,email,phone,password_hash,role) VALUES (?,?,?,?,?,?)")) {
            statement.setString(1, form.firstName);
            statement.setString(2, form.lastName);
            statement.setString(3, form.email);
            statement.setString(4, form.phone.isEmpty() ? null : form.phone);
            statement.setString(5, PasswordUtil.hash(form.password));
            statement.setString(6, form.role);
            statement.executeUpdate();
        }
        response.sendRedirect(request.getContextPath() + "/User?status=created");
    }

    private void editUser(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws SQLException, IOException {
        int id = parseId(request.getParameter("userId"));
        UserForm form = readAndValidate(request, false);
        Integer adminId = (Integer) session.getAttribute("userId");
        if (adminId != null && adminId == id && !"admin".equals(form.role)) {
            throw new IllegalArgumentException("You cannot remove your own administrator role.");
        }
        String sql = form.password.isEmpty()
                ? "UPDATE users SET first_name=?,last_name=?,email=?,phone=?,role=?,updated_at=NOW() WHERE id=?"
                : "UPDATE users SET first_name=?,last_name=?,email=?,phone=?,role=?,password_hash=?,updated_at=NOW() WHERE id=?";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, form.firstName);
            statement.setString(2, form.lastName);
            statement.setString(3, form.email);
            statement.setString(4, form.phone.isEmpty() ? null : form.phone);
            statement.setString(5, form.role);
            if (form.password.isEmpty()) statement.setInt(6, id);
            else {
                statement.setString(6, PasswordUtil.hash(form.password));
                statement.setInt(7, id);
            }
            if (statement.executeUpdate() != 1) throw new IllegalArgumentException("User not found.");
        }
        response.sendRedirect(request.getContextPath() + "/User?status=updated");
    }

    private void deleteUser(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws SQLException, IOException {
        int id = parseId(request.getParameter("id"));
        Integer adminId = (Integer) session.getAttribute("userId");
        if (adminId != null && adminId == id) {
            throw new IllegalArgumentException("You cannot delete your own administrator account.");
        }
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement("DELETE FROM users WHERE id=?")) {
            statement.setInt(1, id);
            if (statement.executeUpdate() != 1) throw new IllegalArgumentException("User not found.");
        }
        response.sendRedirect(request.getContextPath() + "/User?status=deleted");
    }

    private void setSuspended(HttpServletRequest request, HttpServletResponse response,
                              HttpSession session, boolean suspended) throws SQLException, IOException {
        int id = parseId(request.getParameter("id"));
        Integer adminId = (Integer) session.getAttribute("userId");
        if (adminId != null && adminId == id) {
            throw new IllegalArgumentException("You cannot change your own administrator account status.");
        }
        String sql = suspended
                ? "UPDATE users SET is_suspended=1, suspension_note=?, updated_at=NOW() WHERE id=?"
                : "UPDATE users SET is_suspended=0, suspension_note=NULL, updated_at=NOW() WHERE id=?";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            if (suspended) {
                String note = trim(request.getParameter("reason"));
                statement.setString(1, note.isEmpty() ? null : note.substring(0, Math.min(255, note.length())));
                statement.setInt(2, id);
            } else {
                statement.setInt(1, id);
            }
            if (statement.executeUpdate() != 1) throw new IllegalArgumentException("User not found.");
        }
        response.sendRedirect(request.getContextPath() + "/User?status=" + (suspended ? "suspended" : "reinstated"));
    }

    private void bulkAction(HttpServletRequest request, HttpServletResponse response, HttpSession session,
                            boolean suspend) throws SQLException, IOException {
        String[] values = request.getParameterValues("userIds");
        if (values == null || values.length == 0 || values.length > 100) {
            throw new IllegalArgumentException("Select between 1 and 100 users.");
        }
        Integer adminId = (Integer) session.getAttribute("userId");
        List<Integer> ids = new ArrayList<>();
        for (String value : values) {
            int id = parseId(value);
            if (adminId != null && adminId == id) {
                throw new IllegalArgumentException("Your administrator account cannot be changed in a bulk action.");
            }
            if (!ids.contains(id)) ids.add(id);
        }
        String placeholders = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
        String sql = suspend
                ? "UPDATE users SET is_suspended=1, suspension_note=?, updated_at=NOW() WHERE id IN (" + placeholders + ")"
                : "DELETE FROM users WHERE id IN (" + placeholders + ")";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            int index = 1;
            if (suspend) {
                String note = trim(request.getParameter("reason"));
                statement.setString(index++, note.isEmpty() ? null : note.substring(0, Math.min(255, note.length())));
            }
            for (Integer id : ids) statement.setInt(index++, id);
            statement.executeUpdate();
        }
        response.sendRedirect(request.getContextPath() + "/User?status=" + (suspend ? "suspended" : "deleted"));
    }

    private UserForm readAndValidate(HttpServletRequest request, boolean requirePassword) {
        UserForm form = new UserForm();
        form.firstName = trim(request.getParameter("firstName"));
        form.lastName = trim(request.getParameter("lastName"));
        form.email = trim(request.getParameter("email")).toLowerCase(java.util.Locale.ROOT);
        form.phone = trim(request.getParameter("phone"));
        form.role = trim(request.getParameter("role")).toLowerCase(java.util.Locale.ROOT);
        form.password = request.getParameter("password");
        if (form.password == null) form.password = "";
        if (form.firstName.isEmpty() || form.firstName.length() > 60
                || form.lastName.isEmpty() || form.lastName.length() > 60)
            throw new IllegalArgumentException("First and last names are required and must be 60 characters or fewer.");
        if (form.email.length() > 150 || !EMAIL.matcher(form.email).matches())
            throw new IllegalArgumentException("Enter a valid email address.");
        if (form.phone.length() > 20) throw new IllegalArgumentException("Phone must be 20 characters or fewer.");
        if (!"guest".equals(form.role) && !"admin".equals(form.role))
            throw new IllegalArgumentException("Choose a valid user role.");
        if (requirePassword && !PasswordUtil.isStrong(form.password))
            throw new IllegalArgumentException("Password must be 12-128 characters and include uppercase, lowercase, a number, and a symbol.");
        if (!form.password.isEmpty() && !PasswordUtil.isStrong(form.password))
            throw new IllegalArgumentException("Password must be 12-128 characters and include uppercase, lowercase, a number, and a symbol.");
        return form;
    }

    private static int parseId(String value) {
        try {
            int id = Integer.parseInt(value);
            if (id > 0) return id;
        } catch (NumberFormatException ignored) { }
        throw new IllegalArgumentException("Invalid user ID.");
    }

    private static String trim(String value) { return value == null ? "" : value.trim(); }

    private static final class UserForm {
        private String firstName, lastName, email, phone, role, password;
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        String expected = (String) session.getAttribute("csrfToken");
        return expected != null && supplied != null
                && MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }
}
