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
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/** Handles authenticated guest profile updates. */
@WebServlet(urlPatterns = {"/ProfileServlet", "/profile"})
public class ProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(ProfileServlet.class.getName());
    private static final Pattern EMAIL = Pattern.compile("^[\\w._%+\\-]+@[\\w.\\-]+\\.[A-Za-z]{2,}$");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Integer userId = authenticatedGuest(session);
        if (userId == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        String token = (String) session.getAttribute("csrfToken");
        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute("csrfToken", token);
        }
        request.setAttribute("csrfToken", token);
        request.setAttribute("profile", loadProfile(userId, response));
        if (response.isCommitted()) return;
        request.setAttribute("success", session.getAttribute("profileSuccess"));
        session.removeAttribute("profileSuccess");
        request.setAttribute("error", session.getAttribute("profileError"));
        session.removeAttribute("profileError");
        request.getRequestDispatcher("/profile.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        Integer userId = authenticatedGuest(session);
        if (userId == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        if (!validCsrf(session, request.getParameter("_csrf"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
            return;
        }

        try {
            String action = request.getParameter("action");
            if ("updatePersonal".equals(action)) updatePersonal(request, session, userId);
            else if ("updatePassword".equals(action)) updatePassword(request, userId);
            else if ("updatePreferences".equals(action)) updatePreferences(request, userId);
            else if ("deleteAccount".equals(action)) {
                deleteAccount(request, session, userId, response);
                return;
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unsupported profile action.");
                return;
            }
            session.setAttribute("profileSuccess", "Your profile was updated.");
            response.sendRedirect(request.getContextPath() + "/profile");
        } catch (IllegalArgumentException e) {
            session.setAttribute("profileError", e.getMessage());
            response.sendRedirect(request.getContextPath() + "/profile");
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Guest profile action failed for userId=" + userId, e);
            if ("23000".equals(e.getSQLState())) {
                session.setAttribute("profileError", "That email address is already in use.");
            } else {
                session.setAttribute("profileError", "Could not save your profile. Please try again.");
            }
            response.sendRedirect(request.getContextPath() + "/profile");
        }
    }

    private Map<String, Object> loadProfile(int userId, HttpServletResponse response) throws IOException {
        String sql = "SELECT first_name,last_name,email,phone,dob,address,city,country,notif_booking," +
                "notif_reminder,notif_promos,notif_sms,language_pref,currency_pref FROM users WHERE id=? AND role='guest'";
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet row = statement.executeQuery()) {
                if (!row.next()) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return null;
                }
                Map<String, Object> profile = new HashMap<>();
                profile.put("firstName", row.getString("first_name"));
                profile.put("lastName", row.getString("last_name"));
                profile.put("email", row.getString("email"));
                profile.put("phone", row.getString("phone"));
                Date dob = row.getDate("dob");
                profile.put("dob", dob == null ? "" : dob.toString());
                profile.put("address", row.getString("address"));
                profile.put("city", row.getString("city"));
                profile.put("country", row.getString("country"));
                profile.put("notifBooking", row.getBoolean("notif_booking"));
                profile.put("notifReminder", row.getBoolean("notif_reminder"));
                profile.put("notifPromos", row.getBoolean("notif_promos"));
                profile.put("notifSms", row.getBoolean("notif_sms"));
                profile.put("language", row.getString("language_pref"));
                profile.put("currency", row.getString("currency_pref"));
                return profile;
            }
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not load profile for userId=" + userId, e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Could not load your profile. Please try again.");
            return null;
        }
    }

    private void updatePersonal(HttpServletRequest request, HttpSession session, int userId) throws SQLException {
        String first = trim(request.getParameter("firstName"));
        String last = trim(request.getParameter("lastName"));
        String email = trim(request.getParameter("email")).toLowerCase(Locale.ROOT);
        String phone = trim(request.getParameter("phone"));
        String dobValue = trim(request.getParameter("dob"));
        String address = trim(request.getParameter("address"));
        String city = trim(request.getParameter("city"));
        String country = trim(request.getParameter("country"));
        if (first.isEmpty() || last.isEmpty() || first.length() > 60 || last.length() > 60)
            throw new IllegalArgumentException("First and last names are required (maximum 60 characters).");
        if (email.length() > 150 || !EMAIL.matcher(email).matches())
            throw new IllegalArgumentException("Enter a valid email address.");
        if (!email.equalsIgnoreCase(String.valueOf(session.getAttribute("userEmail"))))
            throw new IllegalArgumentException("Email changes require verification and are not available here yet.");
        if (phone.length() > 20 || address.length() > 255 || city.length() > 80 || country.length() > 60
                || !java.util.Arrays.asList("India", "United States", "United Kingdom", "UAE", "Singapore", "Other").contains(country))
            throw new IllegalArgumentException("One or more profile fields exceed their allowed length.");
        Date dob = null;
        if (!dobValue.isEmpty()) {
            try {
                LocalDate parsedDob = LocalDate.parse(dobValue);
                if (parsedDob.isAfter(LocalDate.now())) throw new IllegalArgumentException("Date of birth cannot be in the future.");
                dob = Date.valueOf(parsedDob);
            }
            catch (RuntimeException e) { throw new IllegalArgumentException("Enter a valid date of birth."); }
        }
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "UPDATE users SET first_name=?,last_name=?,phone=?,dob=?,address=?,city=?,country=?,updated_at=NOW() " +
                             "WHERE id=? AND role='guest'")) {
            statement.setString(1, first);
            statement.setString(2, last);
            statement.setString(3, phone.isEmpty() ? null : phone);
            statement.setDate(4, dob);
            statement.setString(5, address.isEmpty() ? null : address);
            statement.setString(6, city.isEmpty() ? null : city);
            statement.setString(7, country);
            statement.setInt(8, userId);
            if (statement.executeUpdate() != 1) throw new IllegalArgumentException("Account not found.");
        }
        session.setAttribute("userName", first + " " + last);
    }

    private void updatePassword(HttpServletRequest request, int userId) throws SQLException {
        String current = request.getParameter("currentPassword");
        String next = request.getParameter("newPassword");
        String confirm = request.getParameter("confirmPassword");
        if (current == null || next == null || !next.equals(confirm))
            throw new IllegalArgumentException("Enter the current password and make sure the new passwords match.");
        if (!PasswordUtil.isStrong(next))
            throw new IllegalArgumentException("Password must be 12–128 characters and include uppercase, lowercase, a number, and a special character.");
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement query = connection.prepareStatement("SELECT password_hash FROM users WHERE id=? AND role='guest'")) {
            query.setInt(1, userId);
            try (ResultSet row = query.executeQuery()) {
                if (!row.next() || !PasswordUtil.verify(current, row.getString("password_hash")))
                    throw new IllegalArgumentException("Current password is incorrect.");
            }
            try (PreparedStatement update = connection.prepareStatement(
                    "UPDATE users SET password_hash=?,updated_at=NOW() WHERE id=? AND role='guest'")) {
                update.setString(1, PasswordUtil.hash(next));
                update.setInt(2, userId);
                if (update.executeUpdate() != 1) throw new IllegalArgumentException("Account not found.");
            }
        }
    }

    private void updatePreferences(HttpServletRequest request, int userId) throws SQLException {
        String language = trim(request.getParameter("language"));
        String currency = trim(request.getParameter("currency"));
        if (!java.util.Arrays.asList("English", "Hindi", "Punjabi", "Arabic").contains(language))
            throw new IllegalArgumentException("Choose a supported language.");
        if (!java.util.Arrays.asList("INR", "USD", "GBP", "AED").contains(currency))
            throw new IllegalArgumentException("Choose a supported currency.");
        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "UPDATE users SET notif_booking=?,notif_reminder=?,notif_promos=?,notif_sms=?," +
                             "language_pref=?,currency_pref=?,updated_at=NOW() WHERE id=? AND role='guest'")) {
            statement.setBoolean(1, "on".equals(request.getParameter("notifBooking")));
            statement.setBoolean(2, "on".equals(request.getParameter("notifReminder")));
            statement.setBoolean(3, "on".equals(request.getParameter("notifPromos")));
            statement.setBoolean(4, "on".equals(request.getParameter("notifSms")));
            statement.setString(5, language);
            statement.setString(6, currency);
            statement.setInt(7, userId);
            if (statement.executeUpdate() != 1) throw new IllegalArgumentException("Account not found.");
        }
    }

    private void deleteAccount(HttpServletRequest request, HttpSession session, int userId,
                               HttpServletResponse response) throws SQLException, IOException {
        String password = request.getParameter("currentPassword");
        if (password == null || password.isEmpty())
            throw new IllegalArgumentException("Enter your current password to delete your account.");
        try (Connection connection = DBConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                String storedHash;
                try (PreparedStatement query = connection.prepareStatement(
                        "SELECT password_hash FROM users WHERE id=? AND role='guest' FOR UPDATE")) {
                    query.setInt(1, userId);
                    try (ResultSet row = query.executeQuery()) {
                        if (!row.next()) throw new IllegalArgumentException("Guest account not found.");
                        storedHash = row.getString("password_hash");
                    }
                }
                if (!PasswordUtil.verify(password, storedHash))
                    throw new IllegalArgumentException("Current password is incorrect.");
                try (PreparedStatement active = connection.prepareStatement(
                        "SELECT COUNT(*) FROM bookings WHERE user_id=? AND status IN ('Pending','Confirmed','Checked-In') " +
                                "AND checkout_date >= CURDATE()")) {
                    active.setInt(1, userId);
                    try (ResultSet row = active.executeQuery()) {
                        if (row.next() && row.getInt(1) > 0)
                            throw new IllegalArgumentException("Cancel or complete your upcoming bookings before deleting your account.");
                    }
                }
                String anonymizedEmail = "deleted-user-" + userId + "@deleted.invalid";
                try (PreparedStatement bookings = connection.prepareStatement(
                        "UPDATE bookings SET user_id=NULL,guest_first='Deleted',guest_last='Guest',guest_email=?," +
                                "guest_phone=NULL,special_requests=NULL WHERE user_id=?")) {
                    bookings.setString(1, anonymizedEmail);
                    bookings.setInt(2, userId);
                    bookings.executeUpdate();
                }
                try (PreparedStatement audit = connection.prepareStatement(
                        "UPDATE audit_log SET user_id=NULL,user_email=? WHERE user_id=?")) {
                    audit.setString(1, anonymizedEmail);
                    audit.setInt(2, userId);
                    audit.executeUpdate();
                }
                try (PreparedStatement reviews = connection.prepareStatement("DELETE FROM reviews WHERE user_id=?")) {
                    reviews.setInt(1, userId);
                    reviews.executeUpdate();
                }
                try (PreparedStatement delete = connection.prepareStatement("DELETE FROM users WHERE id=? AND role='guest'")) {
                    delete.setInt(1, userId);
                    if (delete.executeUpdate() != 1) throw new SQLException("Account could not be deleted.");
                }
                connection.commit();
            } catch (Exception e) {
                connection.rollback();
                if (e instanceof SQLException) throw (SQLException) e;
                if (e instanceof IllegalArgumentException) throw (IllegalArgumentException) e;
                throw new SQLException("Account deletion failed.", e);
            } finally {
                connection.setAutoCommit(true);
            }
        }
        session.invalidate();
        response.sendRedirect(request.getContextPath() + "/index.jsp?accountDeleted=1");
    }

    private static Integer authenticatedGuest(HttpSession session) {
        if (session == null || !"guest".equals(session.getAttribute("userRole"))) return null;
        Object value = session.getAttribute("userId");
        return value instanceof Integer ? (Integer) value : null;
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        String expected = (String) session.getAttribute("csrfToken");
        return expected != null && supplied != null && MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8));
    }

    private static String trim(String value) { return value == null ? "" : value.trim(); }
}
