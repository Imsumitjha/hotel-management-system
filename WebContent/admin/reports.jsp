<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="javax.servlet.http.HttpSession,java.util.List,java.util.Map,java.util.Locale,java.text.NumberFormat,java.math.BigDecimal" %>
<%!
  private String reportEscape(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }
  private String inr(Object value) {
    NumberFormat format = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
    format.setCurrency(java.util.Currency.getInstance("INR"));
    return format.format(value == null ? BigDecimal.ZERO : value);
  }
%>
<%
  HttpSession adminSession = request.getSession(false);
  if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
    return;
  }
  if (request.getAttribute("dailyRevenue") == null) {
    response.sendRedirect(request.getContextPath() + "/admin/reports");
    return;
  }
  String contextPath = request.getContextPath();
  String from = String.valueOf(request.getAttribute("from"));
  String to = String.valueOf(request.getAttribute("to"));
  List<Map<String, Object>> daily = (List<Map<String, Object>>) request.getAttribute("dailyRevenue");
  List<Map<String, Object>> byRoom = (List<Map<String, Object>>) request.getAttribute("roomRevenue");
  Map<String, Long> statuses = (Map<String, Long>) request.getAttribute("bookingStatuses");
  NumberFormat numbers = NumberFormat.getIntegerInstance(Locale.US);
  String adminName = String.valueOf(adminSession.getAttribute("userName"));
  if ("null".equals(adminName) || adminName.trim().isEmpty()) adminName = "Administrator";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Reports — Grand Horizon Admin</title>
  <link rel="stylesheet" href="<%=reportEscape(contextPath)%>/css/style.css">
  <style>
    .report-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:14px;margin:22px 0}
    .report-card{padding:20px;border:1px solid var(--border,#30343b);border-radius:8px;background:var(--surface,#171a20)}
    .report-card__label{color:var(--text-muted,#9ca3af);font-size:.85rem}.report-card__value{font-size:1.6rem;margin:8px 0 0;font-weight:700}
    .report-section{margin:26px 0}.report-section h2{font-size:1.1rem;margin-bottom:12px}.report-table-wrap{overflow-x:auto;border:1px solid var(--border,#30343b);border-radius:8px}
    .report-table{width:100%;border-collapse:collapse}.report-table th,.report-table td{padding:12px 15px;text-align:left;border-bottom:1px solid var(--border,#30343b)}
    .report-table th{color:var(--text-muted,#9ca3af);font-size:.76rem;text-transform:uppercase;letter-spacing:.05em}
    .report-toolbar{display:flex;align-items:end;gap:12px;flex-wrap:wrap}.report-toolbar label{display:grid;gap:6px}.report-toolbar input{min-width:150px}
    .report-note{color:var(--text-muted,#9ca3af);font-size:.88rem;margin-top:8px}@media(max-width:640px){.report-toolbar{align-items:stretch;flex-direction:column}}
  </style>
</head>
<body>
<div class="admin-layout">
  <aside class="sidebar">
    <div class="sidebar__brand"><div class="sidebar__brand-name">Grand Horizon</div><div class="sidebar__brand-sub">Administration Portal</div></div>
    <p class="sidebar__section-label">Main</p>
    <nav class="sidebar__nav">
      <a href="<%=reportEscape(contextPath)%>/admin" class="sidebar__nav-item">Dashboard</a>
      <a href="<%=reportEscape(contextPath)%>/admin/manage-booking.jsp" class="sidebar__nav-item">Bookings</a>
      <a href="<%=reportEscape(contextPath)%>/admin/manage-rooms.jsp" class="sidebar__nav-item">Rooms</a>
      <a href="<%=reportEscape(contextPath)%>/User" class="sidebar__nav-item">Users</a>
      <a href="<%=reportEscape(contextPath)%>/review?action=all" class="sidebar__nav-item">Reviews</a>
      <a href="<%=reportEscape(contextPath)%>/admin/manage-messages.jsp" class="sidebar__nav-item">Messages</a>
      <a href="<%=reportEscape(contextPath)%>/admin/reports" class="sidebar__nav-item active">Reports</a>
    </nav>
    <p class="sidebar__section-label">System</p><nav class="sidebar__nav"><a href="<%=reportEscape(contextPath)%>/logout" class="sidebar__nav-item" style="color:var(--error)">Sign Out</a></nav>
    <div class="sidebar__footer"><div class="sidebar__user"><div class="sidebar__user-name"><%=reportEscape(adminName)%></div><div class="sidebar__user-role">Administrator</div></div></div>
  </aside>
  <main class="admin-main">
    <div class="admin-topbar"><h1 class="admin-topbar__title">Reports &amp; Analytics</h1></div>
    <div class="admin-content">
      <form class="report-toolbar" method="get" action="<%=reportEscape(contextPath)%>/admin/reports">
        <label>From <input class="form-control" type="date" name="from" value="<%=reportEscape(from)%>" required></label>
        <label>To <input class="form-control" type="date" name="to" value="<%=reportEscape(to)%>" required></label>
        <button class="btn btn--outline btn--sm" type="submit">Apply range</button>
        <button class="btn btn--primary btn--sm" type="submit" name="export" value="csv">Download CSV</button>
      </form>
      <p class="report-note">Payment activity uses capture and refund dates in <%=reportEscape(request.getAttribute("businessZone"))%>. Booking totals use booking creation date and current status. Configure the database/JDBC time zone to match.</p>

      <section class="report-grid" aria-label="Summary">
        <article class="report-card"><div class="report-card__label">Gross captures</div><p class="report-card__value"><%=reportEscape(inr(request.getAttribute("grossCaptures")))%></p><small><%=reportEscape(numbers.format(request.getAttribute("captureCount")))%> payments</small></article>
        <article class="report-card"><div class="report-card__label">Refunds processed</div><p class="report-card__value"><%=reportEscape(inr(request.getAttribute("refundTotal")))%></p><small><%=reportEscape(numbers.format(request.getAttribute("refundCount")))%> refunds</small></article>
        <article class="report-card"><div class="report-card__label">Net payment activity</div><p class="report-card__value"><%=reportEscape(inr(request.getAttribute("netRevenue")))%></p></article>
        <article class="report-card"><div class="report-card__label">Bookings created</div><p class="report-card__value"><%=reportEscape(numbers.format(request.getAttribute("bookingCount")))%></p></article>
      </section>

      <section class="report-section"><h2>Daily payment activity</h2><div class="report-table-wrap"><table class="report-table">
        <thead><tr><th>Date</th><th>Captures</th><th>Gross captured</th><th>Refunds</th><th>Net</th></tr></thead><tbody>
        <% if (daily.isEmpty()) { %><tr><td colspan="5">No payment activity in this date range.</td></tr><% } %>
        <% for (Map<String,Object> row : daily) { %><tr><td><%=reportEscape(row.get("day"))%></td><td><%=reportEscape(numbers.format(row.get("captureCount")))%></td><td><%=reportEscape(inr(row.get("captures")))%></td><td><%=reportEscape(inr(row.get("refunds")))%> (<%=reportEscape(numbers.format(row.get("refundCount")))%>)</td><td><%=reportEscape(inr(row.get("net")))%></td></tr><% } %>
        </tbody></table></div></section>

      <section class="report-section"><h2>Payment activity by room type</h2><div class="report-table-wrap"><table class="report-table">
        <thead><tr><th>Room type</th><th>Captures</th><th>Gross captured</th><th>Refunds</th><th>Net</th></tr></thead><tbody>
        <% if (byRoom.isEmpty()) { %><tr><td colspan="5">No payment activity in this date range.</td></tr><% } %>
        <% for (Map<String,Object> row : byRoom) { %><tr><td><%=reportEscape(row.get("roomType"))%></td><td><%=reportEscape(numbers.format(row.get("captureCount")))%></td><td><%=reportEscape(inr(row.get("captures")))%></td><td><%=reportEscape(inr(row.get("refunds")))%> (<%=reportEscape(numbers.format(row.get("refundCount")))%>)</td><td><%=reportEscape(inr(row.get("net")))%></td></tr><% } %>
        </tbody></table></div></section>

      <section class="report-section"><h2>Bookings by status</h2><div class="report-table-wrap"><table class="report-table">
        <thead><tr><th>Status</th><th>Bookings created</th></tr></thead><tbody>
        <% if (statuses.isEmpty()) { %><tr><td colspan="2">No bookings created in this date range.</td></tr><% } %>
        <% for (Map.Entry<String,Long> row : statuses.entrySet()) { %><tr><td><%=reportEscape(row.getKey())%></td><td><%=reportEscape(numbers.format(row.getValue()))%></td></tr><% } %>
        </tbody></table></div></section>
    </div>
  </main>
</div>
</body>
</html>
