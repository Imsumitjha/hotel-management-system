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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * LoginServlet — handles POST from login.jsp and admin/admin-login.jsp.
 *
 * <p>Routes:
 * <ul>
 *   <li>{@code POST /LoginServlet}       — guest login (login.jsp)
 *   <li>{@code POST /AdminLoginServlet}  — mapped via url-pattern below
 * </ul>
 *
 * <p>On success, stores the following attributes in the {@link HttpSession}:
 * <ul>
 *   <li>{@code userId}    — int
 *   <li>{@code userEmail} — String
 *   <li>{@code userName}  — String (first + last)
 *   <li>{@code userRole}  — "guest" | "admin"
 * </ul>
 */
@WebServlet(urlPatterns = {"/login", "/LoginServlet", "/admin-login", "/adminlogin", "/AdminLoginServlet"})
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(LoginServlet.class.getName());

    // SQL — fetch user by email
    private static final String SQL_FIND_USER =
            "SELECT id, first_name, last_name, email, password_hash, role, is_suspended " +
                    "FROM users WHERE email = ? LIMIT 1";

    // ── GET — redirect to appropriate login page ──────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if ("logout".equalsIgnoreCase(req.getParameter("action"))) {
            resp.sendRedirect(req.getContextPath() + "/logout");
            return;
        }
        if (isAdminRequest(req)) {
            resp.sendRedirect(req.getContextPath() + "/admin/admin-login.jsp");
        } else {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
        }
    }

    // ── POST — authenticate ───────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        // Determine which login form was submitted
        boolean isAdminLogin = isAdminRequest(req);

        // 1. Read credentials
        String email    = sanitise(req.getParameter("email"));
        String username = sanitise(req.getParameter("username")); // admin form uses 'username'
        String password = req.getParameter("password");

        // Admin login uses the 'username' field but we store emails in DB
        // Convention: admin username IS the email for simplicity
        String loginEmail = (isAdminLogin && username != null && !username.isEmpty())
                ? username
                : email;

        // 2. Basic validation
        if (isEmpty(loginEmail) || isEmpty(password)) {
            forwardWithError(req, resp, isAdminLogin,
                    "Email / username and password are required.");
            return;
        }

        // 3. Look up user in DB
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_FIND_USER)) {

            // If admin typed their plain username (not email), prepend the domain
            // so admins can log in with just "admin" if they prefer.
            String lookup = loginEmail.contains("@")
                    ? loginEmail.trim()
                    : loginEmail + "@grandhorizon.in";

            ps.setString(1, lookup.toLowerCase(java.util.Locale.ROOT));
            int userId;
            String firstName;
            String lastName;
            String storedEmail;
            String storedPassword;
            String role;
            boolean suspended;
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    forwardWithError(req, resp, isAdminLogin,
                            "Email or password is incorrect.");
                    return;
                }
                userId = rs.getInt("id");
                firstName = rs.getString("first_name");
                lastName = rs.getString("last_name");
                storedEmail = rs.getString("email");
                storedPassword = rs.getString("password_hash");
                role = rs.getString("role");
                suspended = rs.getBoolean("is_suspended");
            }

            if (suspended || !PasswordUtil.verify(password, storedPassword)) {
                forwardWithError(req, resp, isAdminLogin,
                        "Email or password is incorrect.");
                return;
            }

            if (isAdminLogin && !"admin".equalsIgnoreCase(role)) {
                forwardWithError(req, resp, true,
                        "Access denied. This portal is for hotel staff only.");
                return;
            }

            HttpSession oldSession = req.getSession(false);
            String redirect = oldSession == null ? null
                    : (String) oldSession.getAttribute("redirectAfterLogin");
            if (oldSession != null) oldSession.invalidate();
            HttpSession session = req.getSession(true);
            session.setAttribute("userId", userId);
            session.setAttribute("userEmail", storedEmail);
            session.setAttribute("userName", (firstName + " " + lastName).trim());
            session.setAttribute("userRole",  role);
            session.setMaxInactiveInterval(60 * 60); // 1 hour

            LOG.info("Login success — userId=" + userId
                    + " role=" + role);

            // 7. Redirect
            if ("admin".equalsIgnoreCase(role)) {
                resp.sendRedirect(req.getContextPath() + "/admin");
            } else {
                // Redirect to originally requested page, or home
                resp.sendRedirect(isSafeRedirect(redirect, req.getContextPath())
                        ? redirect : req.getContextPath() + "/index.jsp");
            }

        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "LoginServlet DB error", e);
            forwardWithError(req, resp, isAdminLogin,
                    "A server error occurred. Please try again later.");
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static boolean isAdminRequest(HttpServletRequest req) {
        String path = req.getServletPath();
        return "/admin-login".equalsIgnoreCase(path) || "/adminlogin".equalsIgnoreCase(path)
                || "/AdminLoginServlet".equalsIgnoreCase(path);
    }

    private static boolean isSafeRedirect(String path, String contextPath) {
        return path != null && path.startsWith("/") && !path.startsWith("//")
                && (contextPath.isEmpty() || path.equals(contextPath)
                || path.startsWith(contextPath + "/"));
    }

    private void forwardWithError(HttpServletRequest req,
                                  HttpServletResponse resp,
                                  boolean isAdmin,
                                  String message)
            throws ServletException, IOException {

        req.setAttribute("error", message);
        String page = isAdmin ? "/admin/admin-login.jsp" : "/login.jsp";
        req.getRequestDispatcher(page).forward(req, resp);
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}
