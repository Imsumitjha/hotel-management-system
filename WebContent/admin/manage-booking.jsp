<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession,java.util.List" %>
<%!
  private String bookingEscape(Object value) {
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
  if (request.getAttribute("adminBookings") == null) {
    response.sendRedirect(request.getContextPath() + "/booking?action=admin-list");
    return;
  }
  String adminName    = (String) adminSession.getAttribute("userName");
  String bookingCsrfToken = (String) adminSession.getAttribute("csrfToken");
  if (bookingCsrfToken == null) {
    bookingCsrfToken = java.util.UUID.randomUUID().toString();
    adminSession.setAttribute("csrfToken", bookingCsrfToken);
  }
  if (adminName == null) adminName = "Administrator";
  String adminInitial = adminName.substring(0, 1).toUpperCase();

  String flashSuccess = (String) request.getAttribute("success");
  String flashError   = (String) request.getAttribute("error");
  String bookingActionSuccess = (String) request.getAttribute("bookingActionSuccess");
  String bookingActionError = (String) request.getAttribute("bookingActionError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Manage Bookings — Grand Horizon Admin</title>
  <link rel="stylesheet" href="../css/style.css">
  <style>
    /* ── Payment status mini-badge inside table ── */
    .pay-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.3rem;
      font-size: 0.6rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      padding: 0.2rem 0.55rem;
      border-radius: 2px;
      font-weight: 500;
    }
    .pay-badge::before {
      content: '';
      width: 4px; height: 4px;
      border-radius: 50%;
      background: currentColor;
      flex-shrink: 0;
    }
    .pay-badge--captured { background:rgba(74,140,106,0.12); color:#4a8c6a; border:1px solid rgba(74,140,106,0.2); }
    .pay-badge--failed   { background:rgba(192,81,58,0.12);  color:var(--error); border:1px solid rgba(192,81,58,0.2); }
    .pay-badge--pending  { background:rgba(184,115,51,0.12); color:var(--warning); border:1px solid rgba(184,115,51,0.2); }
    .pay-badge--none     { background:var(--charcoal); color:var(--text-muted); border:1px solid var(--border); }
    .pay-badge--refunded { background:rgba(100,120,200,0.12); color:#8898cc; border:1px solid rgba(100,120,200,0.2); }
  </style>
</head>
<body>

<div class="admin-layout">

  <%-- ══════════ SIDEBAR ══════════ --%>
  <aside class="sidebar">
    <div class="sidebar__brand">
      <div class="sidebar__brand-name">Grand Horizon</div>
      <div class="sidebar__brand-sub">Administration Portal</div>
    </div>

    <p class="sidebar__section-label">Main</p>
    <nav class="sidebar__nav">
      <a href="../admin" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>
        Dashboard
      </a>
      <a href="manage-booking.jsp" class="sidebar__nav-item active">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        Bookings
        <span class="sidebar__badge">2</span>
      </a>
      <a href="manage-rooms.jsp" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        Rooms
      </a>
      <a href="../User" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
        Users
      </a>
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
      <h1 class="admin-topbar__title">Manage Bookings</h1>
      <div class="admin-topbar__actions">
        <button class="btn btn--outline btn--sm" onclick="exportBookings()">
          <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Export CSV
        </button>
      </div>
    </div>

    <div class="admin-content">

      <%-- Flash messages --%>
      <% if (bookingActionSuccess != null) { %><div class="alert alert--success" role="status"><%=bookingEscape(bookingActionSuccess)%></div><% } %>
      <% if (bookingActionError != null) { %><div class="alert alert--error" role="alert"><%=bookingEscape(bookingActionError)%></div><% } %>
      <% if (flashSuccess != null) { %>
      <div class="alert alert--success" style="margin-bottom:1.5rem;">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
        <%=bookingEscape(flashSuccess)%>
      </div>
      <% } %>
      <% if (flashError != null) { %>
      <div class="alert alert--error" style="margin-bottom:1.5rem;"><%=bookingEscape(flashError)%></div>
      <% } %>

      <!-- ── Summary Stats ─────────────────────────────────── -->
      <div class="stats-grid" style="grid-template-columns:repeat(5,1fr);margin-bottom:2rem;">
        <div class="stat-card">
          <p class="stat-card__label">Total</p>
          <p class="stat-card__value">8</p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Confirmed</p>
          <p class="stat-card__value" style="color:#4a8c6a;">3</p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Pending</p>
          <p class="stat-card__value" style="color:#b87333;">2</p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Cancelled</p>
          <p class="stat-card__value" style="color:var(--error);">2</p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Checked-Out</p>
          <p class="stat-card__value" style="color:var(--gold);">1</p>
        </div>
      </div>

      <!-- ── Toolbar ───────────────────────────────────────── -->
      <div class="admin-toolbar">
        <div class="search-input-wrap" style="flex:2;">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input type="text" id="bookingSearch" class="form-control"
                 placeholder="Search by name, ID, room…" oninput="filterBookings()">
        </div>
        <select id="statusFilter" class="form-control form-select" style="width:160px;" onchange="filterBookings()">
          <option value="">All Status</option>
          <option>Confirmed</option>
          <option>Pending</option>
          <option>Cancelled</option>
          <option>Checked-In</option>
          <option>Checked-Out</option>
        </select>
        <select id="payFilter" class="form-control form-select" style="width:165px;" onchange="filterBookings()">
          <option value="">All Payments</option>
          <option value="captured">Captured</option>
          <option value="pending">Pending / No Pay</option>
          <option value="failed">Failed</option>
        </select>
        <input type="date" id="dateFrom" class="form-control" style="width:155px;"
               onchange="filterBookings()" title="From date">
        <input type="date" id="dateTo"   class="form-control" style="width:155px;"
               onchange="filterBookings()" title="To date">
      </div>

      <!-- ── Bookings Table ────────────────────────────────── -->
      <div class="table-card">
        <div class="table-card__header">
          <h3 class="table-card__title">All Bookings
            <span style="font-size:0.8rem;color:var(--text-muted);font-family:var(--font-body);">(<%=((List<?>)request.getAttribute("adminBookings")).size()%> total)</span>
          </h3>
        </div>
        <table class="data-table" id="bookingsTable">
          <thead>
          <tr>
            <th>Booking ID</th>
            <th>Guest</th>
            <th>Room</th>
            <th>Check-In</th>
            <th>Check-Out</th>
            <th>Nights</th>
            <th>Amount</th>
            <th>Payment</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
          </thead>
          <tbody>
          <% java.util.List<java.util.Map<String,Object>> bookingRows = (java.util.List<java.util.Map<String,Object>>) request.getAttribute("adminBookings");
             if (bookingRows != null) for (java.util.Map<String,Object> row : bookingRows) {
               String rowStatus = String.valueOf(row.get("status"));
               String rowPay = String.valueOf(row.get("payment"));
               String payClass = "captured".equals(rowPay) ? "captured" : "failed".equals(rowPay) ? "failed" : ("pending".equals(rowPay) ? "pending" : "none");
               String rowRef = bookingEscape(row.get("ref"));
          %>
          <tr data-status="<%=bookingEscape(rowStatus)%>" data-pay="<%=bookingEscape(rowPay)%>" data-checkin="<%=bookingEscape(row.get("checkinIso"))%>" data-ref="<%=rowRef%>" data-guest="<%=bookingEscape(row.get("guest"))%>" data-room="<%=bookingEscape(row.get("room"))%>" data-checkout="<%=bookingEscape(row.get("checkout"))%>" data-guests="<%=bookingEscape(row.get("guests"))%>" data-amount="<%=bookingEscape(row.get("amount"))%>" data-payid="<%=bookingEscape(row.get("paymentId"))%>" data-method="<%=bookingEscape(row.get("paymentMethod"))%>">
            <td>#<%=rowRef%></td><td><%=bookingEscape(row.get("guest"))%></td><td><%=bookingEscape(row.get("room"))%></td>
            <td><%=bookingEscape(row.get("checkin"))%></td><td><%=bookingEscape(row.get("checkout"))%></td><td><%=bookingEscape(row.get("nights"))%></td>
            <td><%=bookingEscape(row.get("amount"))%></td><td><span class="pay-badge pay-badge--<%=payClass%>"><%=bookingEscape(rowPay)%></span></td>
            <td><span class="status status--<%=rowStatus.equals("Confirmed") ? "confirmed" : rowStatus.equals("Cancelled") ? "cancelled" : "pending"%>"><%=bookingEscape(rowStatus)%></span></td>
            <td class="actions"><button class="btn btn--ghost btn--sm" onclick="viewBooking(this)">View</button>
            <% if (Boolean.TRUE.equals(row.get("canCancel"))) { %><button class="btn btn--danger btn--sm" onclick="cancelBooking(this)">Cancel</button><% } %>
            <% if (Boolean.TRUE.equals(row.get("canRefund"))) { %><button class="btn btn--danger btn--sm" onclick="refundAndCancel(this)">Refund &amp; Cancel</button><% } %>
            <% if ("Pending".equals(rowStatus) && "captured".equals(rowPay)) { %><button class="btn btn--primary btn--sm" onclick="confirmBooking(this)">Confirm</button><% } %></td>
          </tr><% } %>
          </tbody>
        </table>

        <div style="display:flex;align-items:center;justify-content:space-between;
                    padding:1rem 1.5rem;border-top:1px solid var(--border);
                    font-size:0.78rem;color:var(--text-muted);">
          <span id="rowCount">Showing <%=((List<?>)request.getAttribute("adminBookings")).size()%> of <%=((List<?>)request.getAttribute("adminBookings")).size()%> bookings</span>
          <div class="pagination" style="padding:0;">
            <div class="page-item">‹</div>
            <div class="page-item active">1</div>
            <div class="page-item">›</div>
          </div>
        </div>
      </div>

    </div><!-- /admin-content -->
  </main>
</div><!-- /admin-layout -->


<!-- ══ VIEW BOOKING MODAL ════════════════════════════════════════ -->
<div class="modal-overlay" id="viewModal">
  <div class="modal" style="max-width:560px;">
    <div class="modal__header">
      <h2 class="modal__title">Booking Details</h2>
      <button class="modal__close" onclick="closeModal('viewModal')">✕</button>
    </div>

    <!-- Booking info rows -->
    <div class="summary-row"><span class="summary-row__label">Booking ID</span><span class="summary-row__value" id="vRef" style="color:var(--gold);">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Guest Name</span><span class="summary-row__value" id="vGuest">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Room</span><span class="summary-row__value" id="vRoom">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Check-In</span><span class="summary-row__value" id="vIn">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Check-Out</span><span class="summary-row__value" id="vOut">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Guests</span><span class="summary-row__value" id="vGuests">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Amount</span><span class="summary-row__value" id="vAmount" style="color:var(--gold-light);font-family:var(--font-display);">—</span></div>

    <!-- Divider -->
    <div style="height:1px;background:var(--border);margin:1rem 0;"></div>
    <p style="font-size:0.62rem;letter-spacing:0.25em;text-transform:uppercase;color:var(--gold);margin-bottom:0.8rem;">Payment Information</p>

    <div class="summary-row"><span class="summary-row__label">Payment Status</span><span class="summary-row__value" id="vPayStatus">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Payment ID</span><span class="summary-row__value" id="vPayId" style="font-size:0.78rem;word-break:break-all;">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Method</span><span class="summary-row__value" id="vPayMethod">—</span></div>
    <div class="summary-row"><span class="summary-row__label">Booking Status</span><span class="summary-row__value" id="vStatus">—</span></div>

    <div style="display:flex;gap:0.75rem;justify-content:flex-end;margin-top:1.5rem;">
      <button class="btn btn--ghost" onclick="closeModal('viewModal')">Close</button>
    </div>
  </div>
</div>

<script>
  /* ── Filter ── */
  function filterBookings() {
    const search  = document.getElementById('bookingSearch').value.toLowerCase();
    const status  = document.getElementById('statusFilter').value;
    const pay     = document.getElementById('payFilter').value;
    const from    = document.getElementById('dateFrom').value;
    const to      = document.getElementById('dateTo').value;

    let visible = 0;
    document.querySelectorAll('#bookingsTable tbody tr').forEach(row => {
      const text    = row.textContent.toLowerCase();
      const rStatus = row.dataset.status  || '';
      const rPay    = row.dataset.pay     || '';
      const rDate   = row.dataset.checkin || '';

      const matchSearch  = !search || text.includes(search);
      const matchStatus  = !status || rStatus === status;
      const matchPay     = !pay    || (pay === 'pending' ? (rPay === 'pending' || rPay === 'none') : rPay === pay);
      const matchFrom    = !from   || rDate >= from;
      const matchTo      = !to     || rDate <= to;

      const show = matchSearch && matchStatus && matchPay && matchFrom && matchTo;
      row.style.display = show ? '' : 'none';
      if (show) visible++;
    });

    document.getElementById('rowCount').textContent =
            'Showing ' + visible + ' of ' + document.querySelectorAll('#bookingsTable tbody tr').length + ' bookings';
  }

  /* ── View modal ── */
  function viewBooking(button) {
    const row = button.closest('tr');
    const {ref, guest, room, checkin: checkIn, checkout: checkOut, guests, amount,
      status: bookingStatus, pay: payStatus, payid: payId, method: payMethod} = row.dataset;
    document.getElementById('vRef').textContent       = '#' + ref;
    document.getElementById('vGuest').textContent     = guest;
    document.getElementById('vRoom').textContent      = room;
    document.getElementById('vIn').textContent        = checkIn;
    document.getElementById('vOut').textContent       = checkOut;
    document.getElementById('vGuests').textContent    = guests;
    document.getElementById('vAmount').textContent    = amount;
    document.getElementById('vPayId').textContent     = payId;
    document.getElementById('vPayMethod').textContent = payMethod !== '—' ? payMethod.charAt(0).toUpperCase() + payMethod.slice(1) : '—';

    const payBadgeClass = {
      captured: 'pay-badge--captured',
      failed:   'pay-badge--failed',
      pending:  'pay-badge--pending',
      none:     'pay-badge--none'
    }[payStatus] || 'pay-badge--none';

    document.getElementById('vPayStatus').innerHTML =
            '<span class="pay-badge ' + payBadgeClass + '">' +
            (payStatus === 'none' ? 'No payment' : payStatus.charAt(0).toUpperCase() + payStatus.slice(1)) +
            '</span>';

    const statusClass = {
      'Confirmed':   'status--confirmed',
      'Pending':     'status--pending',
      'Cancelled':   'status--cancelled',
      'Checked-In':  'status--occupied',
      'Checked-Out': 'status--confirmed'
    }[bookingStatus] || 'status--pending';

    document.getElementById('vStatus').innerHTML =
            '<span class="status ' + statusClass + '">' + bookingStatus + '</span>';

    openModal('viewModal');
  }

  /* ── Confirm / Cancel ── */
  function confirmBooking(button) {
    const ref = button.closest('tr').dataset.ref;
    if (confirm('Confirm paid booking #' + ref + '?')) {
      submitBookingAction('confirm', ref);
    }
  }
  function cancelBooking(button) {
    const ref = button.closest('tr').dataset.ref;
    if (confirm('Cancel unpaid booking #' + ref + '?')) {
      submitBookingAction('cancel', ref);
    }
  }
  function refundAndCancel(button) {
    const ref = button.closest('tr').dataset.ref;
    const refundReference = prompt('First process and verify the refund in Razorpay. Then enter its completed refund ID (rfnd_…):');
    if (!refundReference) return;
    if (confirm('Record refund ' + refundReference.trim() + ' and cancel booking #' + ref + '?')) {
      submitBookingAction('refund-cancel', ref, refundReference.trim());
    }
  }
  function submitBookingAction(action, ref, refundReference) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '<%= request.getContextPath() %>/booking';
    [['action', action], ['ref', ref], ['_csrf', '<%= bookingCsrfToken %>']].forEach(([name, value]) => {
      const input = document.createElement('input');
      input.type = 'hidden'; input.name = name; input.value = value;
      form.appendChild(input);
    });
    if (refundReference) {
      const input = document.createElement('input');
      input.type = 'hidden'; input.name = 'refundReference'; input.value = refundReference;
      form.appendChild(input);
    }
    document.body.appendChild(form);
    form.submit();
  }

  /* ── Export ── */
  function exportBookings() {
    window.location.href = '<%=request.getContextPath()%>/booking?action=export&format=csv';
  }

  /* ── Modal helpers ── */
  function openModal(id)  { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }

  document.querySelectorAll('.modal-overlay').forEach(o => {
    o.addEventListener('click', e => { if (e.target === o) o.classList.remove('open'); });
  });
</script>
</body>
</html>
