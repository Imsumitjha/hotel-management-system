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
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;

/**
 * RegisterServlet — handles POST from register.jsp.
 *
 * <p>Validates the form, checks for duplicate email, hashes the password,
 * inserts the new user, then logs them in automatically.
 */
@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(RegisterServlet.class.getName());

    private static final Pattern EMAIL_RE =
            Pattern.compile("^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$");

    private static final String SQL_CHECK_EMAIL =
            "SELECT id FROM users WHERE email = ? LIMIT 1";

    private static final String SQL_INSERT_USER =
            "INSERT INTO users (first_name, last_name, email, phone, password_hash, role) " +
                    "VALUES (?, ?, ?, ?, ?, 'guest')";

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect(req.getContextPath() + "/register.jsp");
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        // 1. Collect fields
        String firstName  = sanitise(req.getParameter("firstName"));
        String lastName   = sanitise(req.getParameter("lastName"));
        String email      = sanitise(req.getParameter("email")).toLowerCase();
        String phone      = sanitise(req.getParameter("phone"));
        String password   = req.getParameter("password");
        String confirmPwd = req.getParameter("confirmPassword");
        String terms      = req.getParameter("terms");

        // 2. Server-side validation
        String validationError = validate(firstName, lastName, email, phone, password, confirmPwd, terms);
        if (validationError != null) {
            req.setAttribute("error", validationError);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // 3. DB operations
        try (Connection conn = DBConnection.getConnection()) {

            // 3a. Duplicate email check
            try (PreparedStatement ps = conn.prepareStatement(SQL_CHECK_EMAIL)) {
                ps.setString(1, email);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("error",
                            "An account with that email already exists. " +
                                    "<a href='login.jsp'>Sign in instead?</a>");
                    req.getRequestDispatcher("/register.jsp").forward(req, resp);
                    return;
                }
            }

            // Store a salted, slow hash in the same format used by login and reset.
            String hash = PasswordUtil.hash(password);

            // 3c. Insert user
            try (PreparedStatement ps = conn.prepareStatement(
                    SQL_INSERT_USER, Statement.RETURN_GENERATED_KEYS)) {

                ps.setString(1, firstName);
                ps.setString(2, lastName);
                ps.setString(3, email);
                ps.setString(4, phone.isEmpty() ? null : phone);
                ps.setString(5, hash);

                int rows = ps.executeUpdate();
                if (rows != 1) {
                    throw new SQLException("Expected 1 row inserted, got " + rows);
                }

                // 3d. Retrieve generated PK
                int newUserId;
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) throw new SQLException("Database did not return the new user ID.");
                    newUserId = keys.getInt(1);
                }

                LOG.info("New guest registered — id=" + newUserId + " email=" + email);

                // 4. Auto-login: create session
                HttpSession previousSession = req.getSession(false);
                if (previousSession != null) previousSession.invalidate();
                HttpSession session = req.getSession(true);
                session.setAttribute("userId",    newUserId);
                session.setAttribute("userEmail", email);
                session.setAttribute("userName",  firstName + " " + lastName);
                session.setAttribute("userRole",  "guest");
                session.setMaxInactiveInterval(60 * 60);

                // 5. Redirect to home with a welcome flag
                session.setAttribute("welcomeMessage",
                        "Welcome, " + firstName + "! Your account has been created.");
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "RegisterServlet DB error", e);
            req.setAttribute("error",
                    "A server error occurred while creating your account. Please try again.");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
        }
    }

    // ── Validation ────────────────────────────────────────────────────────────

    private String validate(String firstName, String lastName, String email, String phone,
                            String password, String confirmPwd, String terms) {

        if (firstName.isEmpty())  return "First name is required.";
        if (lastName.isEmpty())   return "Last name is required.";
        if (firstName.length() > 60 || lastName.length() > 60)
            return "Names must be 60 characters or fewer.";

        if (email.isEmpty() || email.length() > 150 || !EMAIL_RE.matcher(email).matches())
            return "Please enter a valid email address.";
        if (phone != null && phone.length() > 20)
            return "Phone number must be 20 characters or fewer.";

        if (!PasswordUtil.isStrong(password))
            return "Password must be 12–128 characters and include uppercase, lowercase, a number, and a special character.";

        if (!password.equals(confirmPwd))
            return "Passwords do not match.";

        if (!"on".equals(terms))
            return "You must accept the Terms of Service to continue.";

        return null; // valid
    }

    // ── Password hashing placeholder ──────────────────────────────────────────

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }
}
