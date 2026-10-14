<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="javax.servlet.http.HttpSession,java.util.List,java.util.Map" %>
<%!
  private String reviewEscape(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;")
        .replace("\r", " ").replace("\n", " ");
  }
%>
<%
  HttpSession adminSession = request.getSession(false);
  if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
    return;
  }
  if (request.getAttribute("reviews") == null) {
    response.sendRedirect(request.getContextPath() + "/review?action=all");
    return;
  }
  String csrf = String.valueOf(request.getAttribute("reviewCsrfToken"));
  String contextPath = request.getContextPath();
  String adminName = String.valueOf(adminSession.getAttribute("userName"));
  if ("null".equals(adminName) || adminName.trim().isEmpty()) adminName = "Administrator";
  List<Map<String, Object>> reviews = (List<Map<String, Object>>) request.getAttribute("reviews");
  String statusFilter = String.valueOf(request.getAttribute("statusFilter"));
  String loadError = (String) request.getAttribute("reviewLoadError");
  Object pending = request.getAttribute("pendingCount");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Manage Reviews — Grand Horizon Admin</title>
  <link rel="stylesheet" href="<%=reviewEscape(contextPath)%>/css/style.css">
  <style>
    .review-wrap{max-width:1200px;margin:0 auto}.review-toolbar{display:flex;gap:12px;align-items:center;justify-content:space-between;margin:20px 0}
    .review-table-wrap{overflow-x:auto;background:var(--surface,#171a20);border:1px solid var(--border,#30343b);border-radius:8px}
    .review-table{width:100%;border-collapse:collapse;min-width:900px}.review-table th,.review-table td{padding:14px;text-align:left;vertical-align:top;border-bottom:1px solid var(--border,#30343b)}
    .review-table th{font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;color:var(--text-muted,#9ca3af)}.review-body{max-width:340px;white-space:pre-wrap;overflow-wrap:anywhere}
    .review-actions{display:flex;flex-wrap:wrap;gap:8px}.review-actions form{display:inline-flex;gap:6px}.review-note{max-width:160px}.review-status{font-weight:600}
    .review-flash{padding:12px 16px;margin:12px 0;border-radius:5px;background:rgba(184,115,51,.14)}
    @media(max-width:700px){.review-toolbar{align-items:stretch;flex-direction:column}}
  </style>
</head>
<body>
<div class="admin-layout">
  <aside class="sidebar">
    <div class="sidebar__brand"><div class="sidebar__brand-name">Grand Horizon</div><div class="sidebar__brand-sub">Administration Portal</div></div>
    <p class="sidebar__section-label">Main</p>
    <nav class="sidebar__nav">
      <a href="<%=reviewEscape(contextPath)%>/admin" class="sidebar__nav-item">Dashboard</a>
      <a href="<%=reviewEscape(contextPath)%>/admin/manage-booking.jsp" class="sidebar__nav-item">Bookings</a>
      <a href="<%=reviewEscape(contextPath)%>/admin/manage-rooms.jsp" class="sidebar__nav-item">Rooms</a>
      <a href="<%=reviewEscape(contextPath)%>/User" class="sidebar__nav-item">Users</a>
      <a href="<%=reviewEscape(contextPath)%>/review?action=all" class="sidebar__nav-item active">Reviews <span class="sidebar__badge"><%=reviewEscape(pending)%></span></a>
      <a href="<%=reviewEscape(contextPath)%>/admin/manage-messages.jsp" class="sidebar__nav-item">Messages</a>
      <a href="<%=reviewEscape(contextPath)%>/admin/reports" class="sidebar__nav-item">Reports</a>
    </nav>
    <p class="sidebar__section-label">System</p>
    <nav class="sidebar__nav"><a href="<%=reviewEscape(contextPath)%>/logout" class="sidebar__nav-item" style="color:var(--error)">Sign Out</a></nav>
    <div class="sidebar__footer"><div class="sidebar__user"><div class="sidebar__user-name"><%=reviewEscape(adminName)%></div><div class="sidebar__user-role">Administrator</div></div></div>
  </aside>
  <main class="admin-main">
    <div class="admin-topbar"><h1 class="admin-topbar__title">Manage Reviews</h1></div>
    <div class="admin-content review-wrap">
      <% if (loadError != null) { %><div class="alert alert--error" role="alert"><%=reviewEscape(loadError)%></div><% } %>
      <% if ("1".equals(request.getParameter("deleted"))) { %><div class="alert alert--success" role="status">Review deleted.</div><% } %>
      <% if ("1".equals(request.getParameter("moderated"))) { %><div class="alert alert--success" role="status">Review moderation saved.</div><% } %>
      <div class="review-toolbar">
        <div><strong><%=reviewEscape(pending)%></strong> pending reviews</div>
        <form method="get" action="<%=reviewEscape(contextPath)%>/review" class="review-actions">
          <input type="hidden" name="action" value="all">
          <label for="status">Filter</label>
          <select id="status" name="status" class="form-control form-select">
            <option value="" <%=statusFilter.isEmpty() ? "selected" : ""%>>All reviews</option>
            <option value="Pending" <%="Pending".equals(statusFilter) ? "selected" : ""%>>Pending</option>
            <option value="Approved" <%="Approved".equals(statusFilter) ? "selected" : ""%>>Approved</option>
            <option value="Rejected" <%="Rejected".equals(statusFilter) ? "selected" : ""%>>Rejected</option>
          </select>
          <button class="btn btn--outline btn--sm" type="submit">Apply</button>
        </form>
      </div>
      <% if (reviews.isEmpty() && loadError == null) { %><div class="review-flash">No reviews match this filter.</div><% } %>
      <div class="review-table-wrap">
        <table class="review-table">
          <thead><tr><th>Guest / Booking</th><th>Room</th><th>Rating</th><th>Review</th><th>Status</th><th>Moderation</th></tr></thead>
          <tbody>
          <% for (Map<String, Object> row : reviews) { %>
            <tr>
              <td><strong><%=reviewEscape(row.get("guestName"))%></strong><br><%=reviewEscape(row.get("guestEmail"))%><br>Booking <%=reviewEscape(row.get("bookingRef"))%></td>
              <td><%=reviewEscape(row.get("roomNumber"))%><br><%=reviewEscape(row.get("roomType"))%></td>
              <td><%=reviewEscape(row.get("rating"))%> / 5</td>
              <td><strong><%=reviewEscape(row.get("title"))%></strong><div class="review-body"><%=reviewEscape(row.get("body"))%></div></td>
              <td class="review-status"><%=reviewEscape(row.get("status"))%><% if (row.get("adminNote") != null) { %><br><small><%=reviewEscape(row.get("adminNote"))%></small><% } %></td>
              <td>
                <div class="review-actions">
                  <form method="post" action="<%=reviewEscape(contextPath)%>/review">
                    <input type="hidden" name="_csrf" value="<%=reviewEscape(csrf)%>">
                    <input type="hidden" name="id" value="<%=reviewEscape(row.get("id"))%>">
                    <input type="hidden" name="action" value="moderate">
                    <input type="hidden" name="status" value="Approved">
                    <input class="form-control review-note" name="adminNote" maxlength="255" placeholder="Admin note" aria-label="Admin note">
                    <button class="btn btn--outline btn--sm" type="submit">Approve</button>
                  </form>
                  <form method="post" action="<%=reviewEscape(contextPath)%>/review">
                    <input type="hidden" name="_csrf" value="<%=reviewEscape(csrf)%>">
                    <input type="hidden" name="id" value="<%=reviewEscape(row.get("id"))%>">
                    <input type="hidden" name="action" value="moderate">
                    <input type="hidden" name="status" value="Rejected">
                    <input class="form-control review-note" name="adminNote" maxlength="255" placeholder="Admin note" aria-label="Admin note">
                    <button class="btn btn--outline btn--sm" type="submit">Reject</button>
                  </form>
                  <form method="post" action="<%=reviewEscape(contextPath)%>/review" onsubmit="return confirm('Permanently delete this review?')">
                    <input type="hidden" name="_csrf" value="<%=reviewEscape(csrf)%>">
                    <input type="hidden" name="id" value="<%=reviewEscape(row.get("id"))%>">
                    <input type="hidden" name="action" value="delete">
                    <button class="btn btn--danger btn--sm" type="submit">Delete</button>
                  </form>
                </div>
              </td>
            </tr>
          <% } %>
          </tbody>
        </table>
      </div>
    </div>
  </main>
</div>
</body>
</html>
