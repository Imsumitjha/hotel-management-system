<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
  private String html(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;")
        .replace("'", "&#x27;");
  }
%>
<%
  String error = (String) request.getAttribute("error");
  String emailValue = request.getParameter("email");
  String logoutMessage = request.getParameter("logout");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign In — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="auth-page">

  <!-- Visual Panel -->
  <div class="auth-panel auth-panel--visual">
    <div class="auth-visual-content">
      <div class="ornament" style="margin-bottom:2.5rem;"><span>✦</span></div>
      <blockquote>
        "A return to Grand Horizon is always a return to oneself."
      </blockquote>
      <cite>— The Grand Horizon Philosophy</cite>
      <div class="ornament" style="margin-top:2.5rem;"><span>✦</span></div>
    </div>
  </div>

  <!-- Form Panel -->
  <div class="auth-panel">
    <div class="auth-form-wrap">

      <a href="index.jsp" class="auth-logo">Grand Horizon</a>
      <p class="auth-tagline">Luxury Hotel &amp; Suites</p>

      <h1 class="auth-title">Welcome Back</h1>
      <p class="auth-subtitle">Sign in to manage your reservations and preferences.</p>

      <%-- Flash messages from servlet --%>
      <% if (error != null) { %>
        <div class="alert alert--error">
          <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          <%= html(error) %>
        </div>
      <% } %>

      <form action="<%= request.getContextPath() %>/login" method="post" id="loginForm" novalidate>

        <% if ("true".equals(logoutMessage)) { %>
          <div class="alert alert--success" role="status">You have been signed out.</div>
        <% } %>

        <div class="form-group">
          <label for="email">Email Address</label>
          <input type="email" id="email" name="email" class="form-control"
                 placeholder="you@example.com" required
                 value="<%= html(emailValue) %>">
          <span class="form-error" id="emailErr">Please enter a valid email.</span>
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" class="form-control"
                 placeholder="••••••••" required>
          <span class="form-error" id="passErr">Password is required.</span>
        </div>

        <div style="display:flex;justify-content:flex-end;margin-bottom:1.5rem;">
          <a href="<%= request.getContextPath() %>/forgot-password.jsp" style="font-size:0.82rem;color:var(--text-muted);">Forgot password?</a>
        </div>

        <button type="submit" class="btn btn--primary btn--full">Sign In</button>

      </form>

      <div class="auth-divider">or</div>

      <p class="auth-footer-text">
        Don't have an account? <a href="register.jsp">Create one →</a>
      </p>

    </div>
  </div>

</div>

<script>
  document.getElementById('loginForm').addEventListener('submit', function(e) {
    let valid = true;
    const email = document.getElementById('email');
    const pass  = document.getElementById('password');

    if (!email.value || !/\S+@\S+\.\S+/.test(email.value)) {
      document.getElementById('emailErr').classList.add('visible');
      email.classList.add('form-control--error');
      valid = false;
    } else {
      document.getElementById('emailErr').classList.remove('visible');
      email.classList.remove('form-control--error');
    }

    if (!pass.value) {
      document.getElementById('passErr').classList.add('visible');
      pass.classList.add('form-control--error');
      valid = false;
    } else {
      document.getElementById('passErr').classList.remove('visible');
      pass.classList.remove('form-control--error');
    }

    if (!valid) e.preventDefault();
  });
</script>
<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
  &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
  <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
