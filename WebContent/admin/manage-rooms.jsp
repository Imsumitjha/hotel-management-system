<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%!
  private String escapeHtml(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
  }
  private String escapeAttribute(Object value) {
    return escapeHtml(value).replace("\r", " ").replace("\n", " ");
  }
%>
<%
  HttpSession adminSession = request.getSession(false);
  if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
    return;
  }
  if (request.getAttribute("rooms") == null && request.getAttribute("roomAdminError") == null) {
    request.getRequestDispatcher("/RoomServlet?action=admin-list").include(request, response);
  }
  java.util.List<java.util.Map<String, Object>> rooms =
      (java.util.List<java.util.Map<String, Object>>) request.getAttribute("rooms");
  if (rooms == null) rooms = java.util.Collections.emptyList();
  Integer availableCount = (Integer) request.getAttribute("availableCount");
  Integer occupiedCount = (Integer) request.getAttribute("occupiedCount");
  Integer maintenanceCount = (Integer) request.getAttribute("maintenanceCount");
  if (availableCount == null) availableCount = 0;
  if (occupiedCount == null) occupiedCount = 0;
  if (maintenanceCount == null) maintenanceCount = 0;
  boolean roomAdminError = Boolean.TRUE.equals(request.getAttribute("roomAdminError"));
  String adminName    = (String) adminSession.getAttribute("userName");
  if (adminName == null) adminName = "Administrator";
  String adminInitial = adminName.substring(0, 1).toUpperCase();

  String flashSuccess = (String) request.getAttribute("success");
  String flashError   = (String) request.getAttribute("error");

  /* Query-string flash (from servlet redirect) */
  if (flashSuccess == null && "added".equals(request.getParameter("success")))
    flashSuccess = "Room added successfully.";
  if (flashSuccess == null && "updated".equals(request.getParameter("success")))
    flashSuccess = "Room updated successfully.";
  if (flashSuccess == null && "deleted".equals(request.getParameter("success")))
    flashSuccess = "Room deleted.";
  if (flashError   == null && "has_bookings".equals(request.getParameter("error")))
    flashError   = "Cannot delete — this room has active bookings.";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Manage Rooms — Grand Horizon Admin</title>
  <link rel="stylesheet" href="../css/style.css">
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
      <a href="manage-booking.jsp" class="sidebar__nav-item">
        <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        Bookings
        <span class="sidebar__badge">2</span>
      </a>
      <a href="manage-rooms.jsp" class="sidebar__nav-item active">
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
      <h1 class="admin-topbar__title">Manage Rooms</h1>
      <div class="admin-topbar__actions">
        <button class="btn btn--primary btn--sm" onclick="openAddModal()">+ Add New Room</button>
      </div>
    </div>

    <div class="admin-content">

      <%-- Flash messages --%>
      <% if (flashSuccess != null) { %>
      <div class="alert alert--success" style="margin-bottom:1.5rem;">
        <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
        <%=escapeHtml(flashSuccess)%>
      </div>
      <% } %>
      <% if (flashError != null) { %>
      <div class="alert alert--error" style="margin-bottom:1.5rem;"><%=escapeHtml(flashError)%></div>
      <% } %>

      <!-- ── Summary Stats ─────────────────────────────────── -->
      <div class="stats-grid" style="margin-bottom:2rem;">
        <div class="stat-card">
          <p class="stat-card__label">Total Rooms</p>
          <p class="stat-card__value"><%= rooms.size() %></p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Available</p>
          <p class="stat-card__value" style="color:#4a8c6a;"><%= availableCount %></p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Occupied</p>
          <p class="stat-card__value" style="color:var(--gold);"><%= occupiedCount %></p>
        </div>
        <div class="stat-card">
          <p class="stat-card__label">Maintenance</p>
          <p class="stat-card__value" style="color:var(--warning);"><%= maintenanceCount %></p>
        </div>
      </div>

      <!-- ── Toolbar ───────────────────────────────────────── -->
      <div class="admin-toolbar">
        <div class="search-input-wrap" style="flex:2;">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input type="text" id="roomSearch" class="form-control"
                 placeholder="Search by number, type or floor…" oninput="filterRooms()">
        </div>
        <select id="typeFilter" class="form-control form-select" style="width:185px;" onchange="filterRooms()">
          <option value="">All Types</option>
          <option>Deluxe Room</option>
          <option>Twin Room</option>
          <option>Family Suite</option>
          <option>Junior Suite</option>
          <option>Executive Suite</option>
          <option>Presidential Suite</option>
        </select>
        <select id="statusFilter" class="form-control form-select" style="width:155px;" onchange="filterRooms()">
          <option value="">All Status</option>
          <option>Available</option>
          <option>Occupied</option>
          <option>Maintenance</option>
        </select>
      </div>

      <!-- ── Rooms Table (all 13 rows from hotel.sql) ──────── -->
      <div class="table-card">
        <div class="table-card__header">
          <h3 class="table-card__title">All Rooms
            <span style="font-size:0.82rem;color:var(--text-muted);font-family:var(--font-body);">(<%= rooms.size() %> total)</span>
          </h3>
        </div>
        <table class="data-table" id="roomsTable">
          <thead>
          <tr>
            <th>Room No.</th>
            <th>Type</th>
            <th>Floor</th>
            <th>Capacity</th>
            <th>Rate / Night</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
          </thead>
          <tbody>
          <% if (roomAdminError) { %>
          <tr><td colspan="7">Could not load rooms. Refresh the page to try again.</td></tr>
          <% } else if (rooms.isEmpty()) { %>
          <tr><td colspan="7">No rooms have been added yet.</td></tr>
          <% } else { for (java.util.Map<String, Object> room : rooms) {
              String status = String.valueOf(room.get("status"));
              String statusClass = "Available".equals(status) ? "available"
                  : ("Occupied".equals(status) ? "occupied" : "maintenance");
              java.math.BigDecimal rate = (java.math.BigDecimal) room.get("rate");
          %>
          <tr data-type="<%= escapeAttribute(room.get("roomType")) %>" data-status="<%= escapeAttribute(status) %>">
            <td style="color:var(--text-primary);font-weight:500;"><%= escapeHtml(room.get("roomNumber")) %></td>
            <td><%= escapeHtml(room.get("roomType")) %></td>
            <td><%= escapeHtml(room.get("floor")) %></td>
            <td><%= escapeHtml(room.get("capacity")) %></td>
            <td style="color:var(--gold);">&#8377;<%= rate == null ? "0.00" : rate.toPlainString() %></td>
            <td><span class="status status--<%= statusClass %>"><%= escapeHtml(status) %></span></td>
            <td class="actions">
              <button class="btn btn--ghost btn--sm" onclick="editRoom(this)"
                  data-id="<%= room.get("id") %>" data-number="<%= escapeAttribute(room.get("roomNumber")) %>"
                  data-type="<%= escapeAttribute(room.get("roomType")) %>" data-floor="<%= escapeAttribute(room.get("floor")) %>"
                  data-capacity="<%= escapeAttribute(room.get("capacity")) %>" data-rate="<%= rate == null ? "" : rate.toPlainString() %>"
                  data-status="<%= escapeAttribute(status) %>" data-description="<%= escapeAttribute(room.get("description")) %>">Edit</button>
              <button class="btn btn--ghost btn--sm" onclick="toggleStatus(this)"
                  data-id="<%= room.get("id") %>" data-number="<%= escapeAttribute(room.get("roomNumber")) %>"
                  data-status="<%= escapeAttribute(status) %>">Status</button>
              <button class="btn btn--ghost btn--sm" onclick="confirmDelete(this)"
                  data-id="<%= room.get("id") %>" data-number="<%= escapeAttribute(room.get("roomNumber")) %>">Delete</button>
            </td>
          </tr>
          <% } } %>
          </tbody>
        </table>

        <div style="padding:1rem 1.5rem;border-top:1px solid var(--border);
                    font-size:0.78rem;color:var(--text-muted);" id="roomCount">
          Showing <%= rooms.size() %> of <%= rooms.size() %> rooms
        </div>
      </div>

    </div><!-- /admin-content -->
  </main>
</div><!-- /admin-layout -->


<!-- ══ ADD / EDIT ROOM MODAL ══════════════════════════════════════ -->
<div class="modal-overlay" id="roomModal">
  <div class="modal">
    <div class="modal__header">
      <h2 class="modal__title" id="modalTitle">Add New Room</h2>
      <button class="modal__close" onclick="closeModal('roomModal')">✕</button>
    </div>
    <form action="../RoomServlet" method="post" id="roomForm" novalidate>
      <input type="hidden" name="action" id="formAction" value="add">
      <input type="hidden" name="id"     id="formId"     value="">
      <input type="hidden" name="csrfToken" value="<%= request.getAttribute("roomCsrfToken") == null ? "" : request.getAttribute("roomCsrfToken") %>">

      <div class="form-row">
        <div class="form-group">
          <label>Room Number *</label>
          <input type="text" name="roomNumber" id="formNumber"
                 class="form-control" placeholder="e.g. 104 or P02" required>
        </div>
        <div class="form-group">
          <label>Floor *</label>
          <input type="text" name="floor" id="formFloor"
                 class="form-control" placeholder="e.g. 1st">
        </div>
      </div>

      <div class="form-group">
        <label>Room Type *</label>
        <select name="roomType" id="formType" class="form-control form-select">
          <option>Deluxe Room</option>
          <option>Twin Room</option>
          <option>Family Suite</option>
          <option>Junior Suite</option>
          <option>Executive Suite</option>
          <option>Presidential Suite</option>
        </select>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label>Capacity</label>
          <input type="text" name="capacity" id="formCapacity"
                 class="form-control" placeholder="e.g. 2 Adults">
        </div>
        <div class="form-group">
          <label>Rate Per Night (₹) *</label>
          <input type="number" name="rate" id="formRate"
                 class="form-control" placeholder="8500" min="1" required>
          <span class="form-error" id="rateErr">Must be greater than 0.</span>
        </div>
      </div>

      <div class="form-group">
        <label>Status</label>
        <select name="status" id="formStatus" class="form-control form-select">
          <option>Available</option>
          <option>Occupied</option>
          <option>Maintenance</option>
        </select>
      </div>

      <div class="form-group">
        <label>Description</label>
        <textarea name="description" id="formDesc" class="form-control"
                  rows="3" placeholder="Brief room description…"></textarea>
      </div>

      <div style="display:flex;gap:0.75rem;justify-content:flex-end;margin-top:0.5rem;">
        <button type="button" class="btn btn--ghost" onclick="closeModal('roomModal')">Cancel</button>
        <button type="submit" class="btn btn--primary" id="formSubmitBtn">Add Room</button>
      </div>
    </form>
  </div>
</div>

<form id="roomActionForm" action="../RoomServlet" method="post" style="display:none">
  <input type="hidden" name="action" id="roomAction">
  <input type="hidden" name="id" id="roomActionId">
  <input type="hidden" name="status" id="roomActionStatus">
  <input type="hidden" name="csrfToken" value="<%= request.getAttribute("roomCsrfToken") == null ? "" : request.getAttribute("roomCsrfToken") %>">
</form>

<script>
  /* ── Filter ── */
  function filterRooms() {
    const search = document.getElementById('roomSearch').value.toLowerCase();
    const type   = document.getElementById('typeFilter').value;
    const status = document.getElementById('statusFilter').value;
    let count = 0;
    document.querySelectorAll('#roomsTable tbody tr').forEach(row => {
      const text  = row.textContent.toLowerCase();
      const rType = row.dataset.type   || '';
      const rStat = row.dataset.status || '';
      const show  = (!search || text.includes(search))
              && (!type   || rType === type)
              && (!status || rStat === status);
      row.style.display = show ? '' : 'none';
      if (show) count++;
    });
    document.getElementById('roomCount').textContent =
            'Showing ' + count + ' of <%= rooms.size() %> rooms';
  }

  /* ── Add modal ── */
  function openAddModal() {
    document.getElementById('modalTitle').textContent      = 'Add New Room';
    document.getElementById('formAction').value            = 'add';
    document.getElementById('formId').value                = '';
    document.getElementById('formSubmitBtn').textContent   = 'Add Room';
    document.getElementById('roomForm').reset();
    openModal('roomModal');
  }

  /* ── Edit modal — pre-fills all fields ── */
  function editRoom(number) {
    const data = number.dataset;
    document.getElementById('modalTitle').textContent      = 'Edit Room ' + data.number;
    document.getElementById('formAction').value            = 'edit';
    document.getElementById('formId').value                = data.id;
    document.getElementById('formNumber').value            = data.number;
    document.getElementById('formFloor').value             = data.floor;
    document.getElementById('formCapacity').value          = data.capacity;
    document.getElementById('formRate').value              = data.rate;
    document.getElementById('formDesc').value              = data.description;
    document.getElementById('formSubmitBtn').textContent   = 'Save Changes';

    /* Select correct option in dropdowns */
    setSelect('formType',   data.type);
    setSelect('formStatus', data.status);

    openModal('roomModal');
  }

  function setSelect(id, value) {
    const sel = document.getElementById(id);
    for (let i = 0; i < sel.options.length; i++) {
      if (sel.options[i].value === value || sel.options[i].text === value) {
        sel.selectedIndex = i; break;
      }
    }
  }

  /* ── Delete confirm ── */
  function confirmDelete(button) {
    const number = button.dataset;
    if (confirm('Delete Room ' + number.number + '?\nThis cannot be undone. Rooms with active bookings cannot be deleted.')) {
      submitRoomAction('delete', number.id);
    }
  }

  /* ── Toggle maintenance status ── */
  function toggleStatus(button) {
    const number = button.dataset;
    const newStatus = number.status === 'Available' ? 'Maintenance' : 'Available';
    if (confirm('Set Room ' + number.number + ' to ' + newStatus + '?')) {
      submitRoomAction('status', number.id, newStatus);
    }
  }

  function submitRoomAction(action, id, status) {
    document.getElementById('roomAction').value = action;
    document.getElementById('roomActionId').value = id;
    document.getElementById('roomActionStatus').value = status || '';
    document.getElementById('roomActionForm').submit();
  }

  /* ── Form validation ── */
  document.getElementById('roomForm').addEventListener('submit', function(e) {
    const rate = parseFloat(document.getElementById('formRate').value);
    if (!rate || rate <= 0) {
      document.getElementById('rateErr').classList.add('visible');
      document.getElementById('formRate').classList.add('form-control--error');
      e.preventDefault();
    } else {
      document.getElementById('rateErr').classList.remove('visible');
      document.getElementById('formRate').classList.remove('form-control--error');
    }
  });

  /* ── Modal helpers ── */
  function openModal(id)  { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }

  document.querySelectorAll('.modal-overlay').forEach(o => {
    o.addEventListener('click', e => { if (e.target === o) o.classList.remove('open'); });
  });
</script>
</body>
</html>
