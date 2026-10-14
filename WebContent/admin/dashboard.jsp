<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="java.util.Map,java.util.List,java.util.Locale,java.math.BigDecimal" %>
<%!
  private String escapeHtml(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
  }
%>
<%
  /* ── Session guard ── */
  HttpSession adminSession = request.getSession(false);
  if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
    return;
  }
  if (request.getAttribute("adminDashboardLoaded") == null) {
    response.sendRedirect(request.getContextPath() + "/admin");
    return;
  }

  String adminName  = (String) adminSession.getAttribute("userName");
  String adminEmail = (String) adminSession.getAttribute("userEmail");
  if (adminName  == null) adminName  = "Administrator";
  if (adminEmail == null) adminEmail = "admin@grandhorizon.in";

  /* First name only for greeting */
  String adminFirst = adminName.contains(" ")
          ? adminName.substring(0, adminName.indexOf(" "))
          : adminName;
  if (adminFirst.isEmpty()) adminFirst = "Administrator";
  /* Avatar initial */
  String adminInitial = adminFirst.substring(0, 1).toUpperCase();
  Map<String, Object> stats = (Map<String, Object>) request.getAttribute("adminStats");
  if (stats == null) stats = java.util.Collections.emptyMap();
  List<Map<String, Object>> recentBookings =
      (List<Map<String, Object>>) request.getAttribute("recentBookings");
  if (recentBookings == null) recentBookings = java.util.Collections.emptyList();
  List<Map<String, Object>> dashboardRooms =
      (List<Map<String, Object>>) request.getAttribute("dashboardRooms");
  if (dashboardRooms == null) dashboardRooms = java.util.Collections.emptyList();
  int bookingCount = stats.get("bookingCount") == null ? 0 : (Integer) stats.get("bookingCount");
  int pendingCount = stats.get("pendingCount") == null ? 0 : (Integer) stats.get("pendingCount");
  int roomCount = stats.get("roomCount") == null ? 0 : (Integer) stats.get("roomCount");
  int availableRooms = stats.get("availableRooms") == null ? 0 : (Integer) stats.get("availableRooms");
  int userCount = stats.get("userCount") == null ? 0 : (Integer) stats.get("userCount");
  int suspendedUsers = stats.get("suspendedUsers") == null ? 0 : (Integer) stats.get("suspendedUsers");
  BigDecimal capturedRevenue = (BigDecimal) stats.get("capturedRevenue");
  if (capturedRevenue == null) capturedRevenue = BigDecimal.ZERO;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard — Grand Horizon Admin</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>

<div class="admin-layout">

  <%-- ══════════ SIDEBAR ══════════ --%>
  <aside class="sidebar" id="sidebar">
    <div class="sidebar__brand">
      <div class="sidebar__brand-name">Grand Horizon</div>
      <div class="sidebar__brand-sub">Administration Portal</div>
    </div>

    <p class="sidebar__section-label">Main</p>
    <nav class="sidebar__nav">
      <a href="../admin" class="sidebar__nav-item active">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
        Dashboard
      </a>
      <a href="manage-booking.jsp" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        Bookings
        <span class="sidebar__badge"><%= pendingCount %></span>
      </a>
      <a href="manage-rooms.jsp" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        Rooms
      </a>
      <a href="../User" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
        Users
      </a>
      <a href="../review?action=all" class="sidebar__nav-item">Reviews</a>
      <a href="manage-messages.jsp" class="sidebar__nav-item">Messages</a>
    </nav>

    <p class="sidebar__section-label">Reports</p>
    <nav class="sidebar__nav">
      <a href="reports" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        Reports &amp; Analytics
      </a>
    </nav>

    <p class="sidebar__section-label">System</p>
    <nav class="sidebar__nav">
      <a href="../logout" class="sidebar__nav-item" style="color:var(--error);">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Sign Out
      </a>
    </nav>

    <div class="sidebar__footer">
      <div class="sidebar__user">
        <div class="sidebar__avatar"><%=adminInitial%></div>
        <div>
          <div class="sidebar__user-name"><%=adminName%></div>
          <div class="sidebar__user-role">Super Admin</div>
        </div>
      </div>
    </div>
  </aside>

  <%-- ══════════ MAIN ══════════ --%>
  <main class="admin-main">

    <div class="admin-topbar">
      <div>
        <h1 class="admin-topbar__title">Dashboard</h1>
        <p style="font-size:0.75rem;color:var(--text-muted);margin-top:2px;">
          Welcome back, <strong style="color:var(--gold);"><%=adminFirst%></strong>
        </p>
      </div>
      <div class="admin-topbar__actions">
        <span style="font-size:0.78rem;color:var(--text-muted);" id="topbarDate"></span>
        <a href="../index.jsp" class="btn btn--ghost btn--sm" target="_blank">View Site</a>
        <a href="manage-booking.jsp" class="btn btn--primary btn--sm">View Bookings</a>
      </div>
    </div>

    <div class="admin-content">

      <!-- ── Stat Cards (5) ─────────────────────────────────── -->
      <div class="stats-grid" style="grid-template-columns:repeat(5,1fr);margin-bottom:2.5rem;">

        <div class="stat-card">
          <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/></svg>
          <p class="stat-card__label">Total Bookings</p>
          <p class="stat-card__value"><%= bookingCount %></p>
          <p class="stat-card__change">All recorded bookings</p>
        </div>

        <div class="stat-card">
          <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg>
          <p class="stat-card__label">Rooms Available</p>
          <p class="stat-card__value"><%= availableRooms %></p>
          <p class="stat-card__change">of <%= roomCount %> total rooms</p>
        </div>

        <div class="stat-card">
          <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>
          <p class="stat-card__label">Revenue (Captured)</p>
          <p class="stat-card__value">&#8377;<%= String.format(Locale.US, "%,.0f", capturedRevenue.doubleValue()) %></p>
          <p class="stat-card__change">Captured payments</p>
        </div>

        <div class="stat-card">
          <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
          <p class="stat-card__label">Pending Payment</p>
          <p class="stat-card__value" style="color:var(--warning);"><%= pendingCount %></p>
          <p class="stat-card__change">Awaiting confirmation</p>
        </div>

        <div class="stat-card">
          <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
          <p class="stat-card__label">Registered Users</p>
          <p class="stat-card__value"><%= userCount %></p>
          <p class="stat-card__change"><%= suspendedUsers %> suspended</p>
        </div>

      </div>

      <!-- ── Recent Bookings ────────────────────────────────── -->
      <div class="table-card" style="margin-bottom:2rem;">
        <div class="table-card__header">
          <h3 class="table-card__title">Recent Bookings</h3>
          <a href="manage-booking.jsp" class="btn btn--ghost btn--sm">View All</a>
        </div>
        <table class="data-table">
          <thead>
          <tr>
            <th>Booking ID</th>
            <th>Guest</th>
            <th>Room</th>
            <th>Check-In</th>
            <th>Check-Out</th>
            <th>Amount</th>
            <th>Payment</th>
            <th>Status</th>
          </tr>
          </thead>
          <tbody>
          <% if (Boolean.TRUE.equals(request.getAttribute("adminDashboardError"))) { %>
            <tr><td colspan="8">Dashboard data is temporarily unavailable.</td></tr>
          <% } else if (recentBookings.isEmpty()) { %>
            <tr><td colspan="8">No bookings have been recorded yet.</td></tr>
          <% } else { for (Map<String, Object> booking : recentBookings) {
               String bStatus = String.valueOf(booking.get("status"));
               String pStatus = String.valueOf(booking.get("paymentStatus"));
               String paymentClass = "captured".equals(pStatus) ? "confirmed"
                   : ("failed".equals(pStatus) || "refunded".equals(pStatus) ? "cancelled" : "pending");
          %>
            <tr>
              <td style="color:var(--gold);font-size:.82rem;">#<%= escapeHtml(booking.get("bookingRef")) %></td>
              <td style="color:var(--text-primary);"><%= escapeHtml(booking.get("guest")) %></td>
              <td><%= escapeHtml(booking.get("roomType")) %></td>
              <td><%= escapeHtml(booking.get("checkin")) %></td>
              <td><%= escapeHtml(booking.get("checkout")) %></td>
              <td style="color:var(--text-primary);">&#8377;<%= String.format(Locale.US, "%,.2f", ((BigDecimal) booking.get("total")).doubleValue()) %></td>
              <td><span class="status status--<%= paymentClass %>" style="font-size:.6rem;"><%= escapeHtml(pStatus) %></span></td>
              <td><span class="status status--<%= "Cancelled".equals(bStatus) || "Checked-Out".equals(bStatus) ? "cancelled" : ("Pending".equals(bStatus) ? "pending" : "confirmed") %>"><%= escapeHtml(bStatus) %></span></td>
            </tr>
          <% } } %>
          </tbody>
        </table>
      </div>

      <!-- ── Two-column bottom ──────────────────────────────── -->
      <div style="display:grid;grid-template-columns:1.2fr 1fr;gap:1.5rem;">

        <!-- Room Status Overview -->
        <div class="table-card">
          <div class="table-card__header">
            <h3 class="table-card__title">Room Status</h3>
            <a href="manage-rooms.jsp" class="btn btn--ghost btn--sm">Manage</a>
          </div>
          <table class="data-table">
            <thead>
            <tr><th>Room</th><th>Type</th><th>Status</th><th>Current Guest</th></tr>
            </thead>
            <tbody>
            <% if (dashboardRooms.isEmpty()) { %>
              <tr><td colspan="4">No rooms found.</td></tr>
            <% } else { for (Map<String, Object> room : dashboardRooms) {
                 String roomStatus = String.valueOf(room.get("status"));
                 String roomClass = "Available".equals(roomStatus) ? "available"
                     : ("Occupied".equals(roomStatus) ? "occupied" : "pending");
            %>
              <tr>
                <td style="color:var(--text-primary);font-weight:500;"><%= escapeHtml(room.get("number")) %></td>
                <td><%= escapeHtml(room.get("type")) %></td>
                <td><span class="status status--<%= roomClass %>"><%= escapeHtml(roomStatus) %></span></td>
                <td>—</td>
              </tr>
            <% } } %>
            </tbody>
          </table>
        </div>

        <!-- Pending Payments Panel -->
        <div class="table-card">
          <div class="table-card__header">
            <h3 class="table-card__title">
              Pending Payments
              <span style="font-size:0.75rem;color:var(--warning);font-family:var(--font-body);margin-left:0.5rem;"><%= pendingCount %> awaiting</span>
            </h3>
            <a href="manage-booking.jsp" class="btn btn--ghost btn--sm">View All</a>
          </div>
          <div style="padding:1rem 1.5rem;">
            <p style="font-size:0.88rem;color:var(--text-secondary);">
              <%= pendingCount %> booking<%= pendingCount == 1 ? "" : "s" %> are awaiting payment or confirmation.
            </p>
            <a href="manage-booking.jsp" class="btn btn--ghost btn--sm" style="margin-top:1rem;">Review bookings</a>
          </div>
        </div>
      </div><!-- /two-column -->

    </div><!-- /admin-content -->
  </main>

</div><!-- /admin-layout -->

<script>
  document.getElementById('topbarDate').textContent = new Date().toLocaleDateString('en-IN', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
  });
</script>
</body>
</html>
