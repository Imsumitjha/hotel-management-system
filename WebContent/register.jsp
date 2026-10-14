<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Create Account — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>

<div class="auth-page">

  <!-- Visual Panel -->
  <div class="auth-panel auth-panel--visual">
    <div class="auth-visual-content">
      <div class="ornament" style="margin-bottom:2.5rem;"><span>✦</span></div>
      <blockquote>
        "Every great journey begins with a single, deliberate step."
      </blockquote>
      <cite>— Grand Horizon, Est. 1924</cite>
      <div style="margin-top:3rem;">
        <p style="font-size:0.75rem;letter-spacing:0.2em;text-transform:uppercase;color:var(--text-muted);margin-bottom:1.5rem;">Member Benefits</p>
        <ul style="display:flex;flex-direction:column;gap:0.8rem;text-align:left;">
          <li style="display:flex;align-items:center;gap:0.8rem;font-size:0.88rem;color:var(--text-secondary);">
            <svg width="16" height="16" fill="none" stroke="var(--gold)" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            Priority reservation access
          </li>
          <li style="display:flex;align-items:center;gap:0.8rem;font-size:0.88rem;color:var(--text-secondary);">
            <svg width="16" height="16" fill="none" stroke="var(--gold)" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            Exclusive member rates
          </li>
          <li style="display:flex;align-items:center;gap:0.8rem;font-size:0.88rem;color:var(--text-secondary);">
            <svg width="16" height="16" fill="none" stroke="var(--gold)" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            Booking history &amp; preferences
          </li>
          <li style="display:flex;align-items:center;gap:0.8rem;font-size:0.88rem;color:var(--text-secondary);">
            <svg width="16" height="16" fill="none" stroke="var(--gold)" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            Late checkout (subject to availability)
          </li>
        </ul>
      </div>
    </div>
  </div>

  <!-- Form Panel -->
  <div class="auth-panel" style="overflow-y:auto;padding:3rem;">
    <div class="auth-form-wrap" style="max-width:460px;">

      <a href="index.jsp" class="auth-logo">Grand Horizon</a>
      <p class="auth-tagline">Luxury Hotel &amp; Suites</p>

      <h1 class="auth-title">Create Account</h1>
      <p class="auth-subtitle">Join our circle of distinguished guests.</p>

      <%-- Flash message --%>
      <% String error = (String) request.getAttribute("error"); %>
      <% if (error != null) { %>
        <div class="alert alert--error"><%= error %></div>
      <% } %>

      <form action="register" method="post" id="regForm" novalidate>

        <div class="form-row">
          <div class="form-group">
            <label for="firstName">First Name</label>
            <input type="text" id="firstName" name="firstName" class="form-control" placeholder="Arjun" required>
          </div>
          <div class="form-group">
            <label for="lastName">Last Name</label>
            <input type="text" id="lastName" name="lastName" class="form-control" placeholder="Sharma" required>
          </div>
        </div>

        <div class="form-group">
          <label for="email">Email Address</label>
          <input type="email" id="email" name="email" class="form-control" placeholder="arjun@example.com" required>
          <span class="form-error" id="emailErr">Please enter a valid email.</span>
        </div>

        <div class="form-group">
          <label for="phone">Phone Number</label>
          <input type="tel" id="phone" name="phone" class="form-control" placeholder="+91 98765 43210">
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input type="password" id="password" name="password" class="form-control" placeholder="Min. 12 characters" minlength="12" maxlength="128" required>
          <span class="form-hint">Use 12–128 characters with uppercase, lowercase, a number, and a special character.</span>
          <span class="form-error" id="passErr">Use at least 12 characters, including upper/lowercase letters, a number, and a special character.</span>
        </div>

        <div class="form-group">
          <label for="confirmPassword">Confirm Password</label>
          <input type="password" id="confirmPassword" name="confirmPassword" class="form-control" placeholder="Repeat password" required>
          <span class="form-error" id="confirmErr">Passwords do not match.</span>
        </div>

        <div style="margin-bottom:1.5rem;display:flex;align-items:flex-start;gap:0.8rem;">
          <input type="checkbox" id="terms" name="terms" style="margin-top:3px;accent-color:var(--gold);" required>
          <label for="terms" style="font-size:0.82rem;color:var(--text-secondary);text-transform:none;letter-spacing:0;">
            I agree to the <a href="terms-of-service.jsp">Terms of Service</a> and <a href="privacy-policy.jsp">Privacy Policy</a>.
          </label>
        </div>

        <button type="submit" class="btn btn--primary btn--full">Create My Account</button>

      </form>

      <p class="auth-footer-text">
        Already a member? <a href="login.jsp">Sign in →</a>
      </p>

    </div>
  </div>

</div>

<script>
  document.getElementById('regForm').addEventListener('submit', function(e) {
    let valid = true;
    const email   = document.getElementById('email');
    const pass    = document.getElementById('password');
    const confirm = document.getElementById('confirmPassword');

    if (!email.value || !/\S+@\S+\.\S+/.test(email.value)) {
      document.getElementById('emailErr').classList.add('visible');
      valid = false;
    } else document.getElementById('emailErr').classList.remove('visible');

    if (!pass.value || pass.value.length < 12 || pass.value.length > 128
        || !/[A-Z]/.test(pass.value) || !/[a-z]/.test(pass.value)
        || !/[0-9]/.test(pass.value) || !/[^A-Za-z0-9]/.test(pass.value)) {
      document.getElementById('passErr').classList.add('visible');
      valid = false;
    } else document.getElementById('passErr').classList.remove('visible');

    if (pass.value !== confirm.value) {
      document.getElementById('confirmErr').classList.add('visible');
      valid = false;
    } else document.getElementById('confirmErr').classList.remove('visible');

    if (!valid) e.preventDefault();
  });
</script>
</body>
</html>
