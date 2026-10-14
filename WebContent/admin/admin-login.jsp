<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%!
  private String escapeHtml(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
  }
%>
<%
  /* ── If already logged in as admin, skip the login page ── */
  HttpSession s = request.getSession(false);
  if (s != null && "admin".equals(s.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath() + "/admin/dashboard.jsp");
    return;
  }

  String  error     = (String) request.getAttribute("error");
  boolean loggedOut = "true".equals(request.getParameter("logout"));
  boolean csrfWarn  = "1".equals(request.getParameter("csrf"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Staff Portal — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="../css/style.css">
  <style>
    .admin-login-page {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--deep-navy);
      position: relative;
      overflow: hidden;
    }
    .admin-login-page::before {
      content: '';
      position: absolute; inset: 0;
      background-image:
              repeating-linear-gradient(0deg,  transparent, transparent 59px, rgba(200,170,100,0.04) 60px),
              repeating-linear-gradient(90deg, transparent, transparent 59px, rgba(200,170,100,0.04) 60px);
      pointer-events: none;
    }
    .admin-login-page::after {
      content: '';
      position: absolute;
      width: 600px; height: 600px; border-radius: 50%;
      background: radial-gradient(circle, rgba(200,170,100,0.05) 0%, transparent 70%);
      top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      pointer-events: none;
    }
    .admin-login-card {
      position: relative; z-index: 1;
      background: var(--surface);
      border: 1px solid var(--border-light);
      border-radius: var(--radius-md);
      padding: 3.5rem 3rem;
      width: 100%; max-width: 420px;
      box-shadow: 0 24px 64px rgba(0,0,0,0.5), 0 0 40px rgba(200,170,100,0.06);
      animation: cardFadeUp 0.5s cubic-bezier(0.4,0,0.2,1) both;
    }
    @keyframes cardFadeUp {
      from { opacity:0; transform:translateY(20px); }
      to   { opacity:1; transform:translateY(0); }
    }
    .admin-login-card::before {
      content: '';
      position: absolute; top:0; left:12%; right:12%; height:1px;
      background: linear-gradient(90deg, transparent, var(--gold), transparent);
    }
    .alc-header { text-align:center; margin-bottom:2.5rem; }
    .alc-lock {
      width:52px; height:52px; border-radius:50%;
      background: var(--gold-glow);
      border: 1px solid var(--border-light);
      display:flex; align-items:center; justify-content:center;
      margin: 0 auto 1.2rem; color: var(--gold);
    }
    .alc-badge {
      display:inline-block;
      font-size:0.58rem; letter-spacing:0.35em; text-transform:uppercase;
      color:var(--gold); border:1px solid var(--border-light);
      padding:0.25rem 0.9rem; border-radius:2px; margin-bottom:1rem;
    }
    .alc-brand {
      font-family:var(--font-display); font-size:1.7rem;
      color:var(--gold-light); font-weight:600; line-height:1; margin-bottom:0.3rem;
    }
    .alc-sub {
      font-size:0.62rem; letter-spacing:0.3em;
      text-transform:uppercase; color:var(--text-muted);
    }
    .capslock-warn {
      display:none; align-items:center; gap:0.5rem;
      font-size:0.75rem; color:var(--warning); margin-top:0.4rem;
    }
    .capslock-warn.show { display:flex; }
    .alc-security {
      display:flex; align-items:center; gap:0.5rem;
      justify-content:center; margin-top:1.5rem;
      font-size:0.7rem; color:var(--text-muted);
    }
    .alc-security svg { color:var(--success); width:12px; height:12px; }
    .alc-footer { text-align:center; margin-top:1.5rem; font-size:0.78rem; }
    .alc-footer a { color:var(--text-muted); }
    .alc-footer a:hover { color:var(--gold); }
    @media (max-width:480px) { .admin-login-card { padding:2.5rem 1.8rem; } }
  </style>
</head>
<body>

<div class="admin-login-page">
  <div class="admin-login-card">

    <div class="alc-header">
      <div class="alc-lock">
        <svg width="22" height="22" fill="none" stroke="currentColor"
             stroke-width="1.8" viewBox="0 0 24 24">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0110 0v4"/>
        </svg>
      </div>
      <span class="alc-badge">Staff Portal</span>
      <p class="alc-brand">Grand Horizon</p>
      <p class="alc-sub">Administration</p>
    </div>

    <%-- Flash messages --%>
    <% if (loggedOut) { %>
    <div class="alert alert--info" style="margin-bottom:1.5rem;">
      <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
      You have been signed out successfully.
    </div>
    <% } %>
    <% if (csrfWarn) { %>
    <div class="alert alert--error" style="margin-bottom:1.5rem;">
      <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      Security warning: session mismatch. Please sign in again.
    </div>
    <% } %>
    <% if (error != null) { %>
    <div class="alert alert--error" style="margin-bottom:1.5rem;">
      <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      <%=escapeHtml(error)%>
    </div>
    <% } %>

    <form action="<%= request.getContextPath() %>/AdminLoginServlet" method="post" id="adminLoginForm" novalidate>

      <div class="form-group">
        <label for="username">Username or Email</label>
        <input type="text" id="username" name="username" class="form-control"
               placeholder="admin" required autocomplete="username" autofocus>
        <span class="form-error" id="usernameErr">Username is required.</span>
      </div>

      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" class="form-control"
               placeholder="••••••••" required autocomplete="current-password">
        <div class="capslock-warn" id="capsWarn">
          <svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          Caps Lock is on
        </div>
        <span class="form-error" id="passErr">Password is required.</span>
      </div>

      <button type="submit" class="btn btn--primary btn--full" id="loginBtn"
              style="margin-top:0.5rem;">
        Access Dashboard
      </button>

    </form>

    <div class="alc-security">
      <svg fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
      Secured by 256-bit SSL
    </div>

    <div class="alc-footer">
      <a href="../index.jsp">← Return to Hotel Website</a>
    </div>

  </div>
</div>

<script>
  document.getElementById('password').addEventListener('keydown', function(e) {
    document.getElementById('capsWarn')
            .classList.toggle('show', e.getModifierState('CapsLock'));
  });

  document.getElementById('adminLoginForm').addEventListener('submit', function(e) {
    let valid = true;
    const user = document.getElementById('username');
    const pass = document.getElementById('password');
    if (!user.value.trim()) {
      document.getElementById('usernameErr').classList.add('visible');
      user.classList.add('form-control--error'); valid = false;
    } else {
      document.getElementById('usernameErr').classList.remove('visible');
      user.classList.remove('form-control--error');
    }
    if (!pass.value) {
      document.getElementById('passErr').classList.add('visible');
      pass.classList.add('form-control--error'); valid = false;
    } else {
      document.getElementById('passErr').classList.remove('visible');
      pass.classList.remove('form-control--error');
    }
    if (!valid) {
      e.preventDefault();
    } else {
      const btn = document.getElementById('loginBtn');
      btn.disabled = true; btn.textContent = 'Signing in…';
    }
  });
</script>
</body>
</html>
