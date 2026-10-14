<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="java.util.List,java.util.Map,java.text.SimpleDateFormat" %>
<%! private String userHtml(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
} %>
<%
    HttpSession adminSession = request.getSession(false);
    if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
        return;
    }
    if (request.getAttribute("users") == null) {
        response.sendRedirect(request.getContextPath() + "/User");
        return;
    }
    String userCsrfToken = (String) adminSession.getAttribute("csrfToken");
    if (userCsrfToken == null) {
        userCsrfToken = java.util.UUID.randomUUID().toString();
        adminSession.setAttribute("csrfToken", userCsrfToken);
    }
    String flashSuccess = (String) request.getAttribute("success");
    String flashError   = (String) request.getAttribute("error");
    String status = request.getParameter("status");
    if (flashSuccess == null && status != null) {
        if ("created".equals(status)) flashSuccess = "User created.";
        else if ("updated".equals(status)) flashSuccess = "User updated.";
        else if ("deleted".equals(status)) flashSuccess = "User deleted.";
        else if ("suspended".equals(status)) flashSuccess = "User account suspended.";
        else if ("reinstated".equals(status)) flashSuccess = "User account reinstated.";
    }
    List<Map<String, Object>> users = (List<Map<String, Object>>) request.getAttribute("users");
    if (users == null) users = java.util.Collections.emptyList();
    SimpleDateFormat joinedFormat = new SimpleDateFormat("dd MMM yyyy");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users — Grand Horizon Admin</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        /* ── User-specific components ───────────────────────── */

        /* Avatar pill in table */
        .user-cell {
            display: flex;
            align-items: center;
            gap: 0.9rem;
        }
        .user-cell__avatar {
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: var(--gold-glow);
            border: 1px solid var(--gold-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 0.85rem;
            color: var(--gold-light);
            flex-shrink: 0;
        }
        .user-cell__name  { font-size: 0.9rem; color: var(--text-primary); font-weight: 400; }
        .user-cell__email { font-size: 0.75rem; color: var(--text-muted); margin-top: 1px; }

        /* Role badge */
        .role-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            font-size: 0.65rem;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            padding: 0.25rem 0.75rem;
            border-radius: 2px;
            font-weight: 500;
        }
        .role-badge::before {
            content: '';
            width: 5px; height: 5px;
            border-radius: 50%;
            background: currentColor;
            flex-shrink: 0;
        }
        .role-badge--admin {
            background: rgba(200,170,100,0.1);
            color: var(--gold);
            border: 1px solid var(--border-light);
        }
        .role-badge--guest {
            background: rgba(100,120,200,0.08);
            color: #8898cc;
            border: 1px solid rgba(100,120,200,0.2);
        }
        .role-badge--banned {
            background: rgba(192,81,58,0.1);
            color: var(--error);
            border: 1px solid rgba(192,81,58,0.2);
        }

        /* Inline quick-edit role select */
        .role-select {
            background: var(--surface-2);
            border: 1px solid var(--border);
            color: var(--text-secondary);
            font-size: 0.75rem;
            padding: 0.3rem 0.6rem;
            border-radius: var(--radius-sm);
            font-family: var(--font-body);
            cursor: pointer;
            appearance: none;
            outline: none;
            transition: var(--transition);
        }
        .role-select:focus { border-color: var(--gold-muted); }

        /* User detail modal sections */
        .modal-user-header {
            display: flex;
            align-items: center;
            gap: 1.2rem;
            padding: 1.5rem 0 1.5rem;
            border-bottom: 1px solid var(--border);
            margin-bottom: 1.5rem;
        }
        .modal-avatar-lg {
            width: 56px; height: 56px;
            border-radius: 50%;
            background: var(--gold-glow);
            border: 2px solid var(--gold-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 1.5rem;
            color: var(--gold-light);
            flex-shrink: 0;
        }
        .modal-user-meta__name {
            font-family: var(--font-display);
            font-size: 1.4rem;
            font-weight: 300;
        }
        .modal-user-meta__email { font-size: 0.82rem; color: var(--text-muted); margin-top: 2px; }

        /* Stat mini-strip inside modal */
        .modal-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 0.8rem;
            margin-bottom: 1.5rem;
        }
        .modal-stat {
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 0.9rem 1rem;
            text-align: center;
        }
        .modal-stat__num {
            font-family: var(--font-display);
            font-size: 1.5rem;
            color: var(--gold-light);
            line-height: 1;
            margin-bottom: 0.25rem;
        }
        .modal-stat__label {
            font-size: 0.62rem;
            letter-spacing: 0.18em;
            text-transform: uppercase;
            color: var(--text-muted);
        }

        /* Confirmation modal overlay (ban / delete) */
        .confirm-modal {
            max-width: 400px;
        }
        .confirm-modal__icon {
            width: 50px; height: 50px;
            border-radius: 50%;
            border: 1px solid rgba(192,81,58,0.35);
            background: rgba(192,81,58,0.08);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--error);
            margin: 0 auto 1.2rem;
        }

        /* Pagination info */
        .table-info {
            font-size: 0.78rem;
            color: var(--text-muted);
            padding: 1rem 1.5rem;
            border-top: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 0.5rem;
        }

        /* Bulk action bar (appears when rows selected) */
        .bulk-bar {
            display: none;
            align-items: center;
            gap: 1rem;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            padding: 0.8rem 1.2rem;
            margin-bottom: 1.2rem;
            font-size: 0.83rem;
            color: var(--gold);
            flex-wrap: wrap;
        }
        .bulk-bar.visible { display: flex; }
        .bulk-bar__count { font-weight: 500; }

        @media (max-width: 900px) {
            .modal-stats { grid-template-columns: repeat(3,1fr); }
        }
        @media (max-width: 640px) {
            .modal-stats { grid-template-columns: 1fr 1fr; }
            .user-cell__email { display: none; }
        }
    </style>
</head>
<body>

<div class="admin-layout">

    <!-- ══════════════════════════════════════════════════════
         SIDEBAR
    ══════════════════════════════════════════════════════ -->
    <aside class="sidebar" id="sidebar">
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
                <span class="sidebar__badge">12</span>
            </a>
            <a href="manage-rooms.jsp" class="sidebar__nav-item">
                <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
                Rooms
            </a>
            <a href="../User" class="sidebar__nav-item active">
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
                <div class="sidebar__avatar">A</div>
                <div>
                    <div class="sidebar__user-name">Administrator</div>
                    <div class="sidebar__user-role">Super Admin</div>
                </div>
            </div>
        </div>
    </aside>

    <!-- ══════════════════════════════════════════════════════
         MAIN
    ══════════════════════════════════════════════════════ -->
    <main class="admin-main">

        <!-- Topbar -->
        <div class="admin-topbar">
            <h1 class="admin-topbar__title">Manage Users</h1>
            <div class="admin-topbar__actions">
                <button class="btn btn--primary btn--sm" onclick="openAddModal()">+ Add User</button>
                <a href="../index.jsp" class="btn btn--outline btn--sm" target="_blank">View Site</a>
            </div>
        </div>

        <div class="admin-content">

            <!-- Flash messages -->
            <% if (flashSuccess != null) { %>
            <div class="alert alert--success" style="margin-bottom:1.5rem;">
                <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                <%=flashSuccess%>
            </div>
            <% } %>
            <% if (flashError != null) { %>
            <div class="alert alert--error" style="margin-bottom:1.5rem;"><%=flashError%></div>
            <% } %>

            <!-- Summary stats -->
            <div class="stats-grid" style="margin-bottom:2rem;">
                <div class="stat-card">
                    <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    <p class="stat-card__label">Total Users</p>
                    <p class="stat-card__value">142</p>
                    <p class="stat-card__change">↑ 8 this month</p>
                </div>
                <div class="stat-card">
                    <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
                    <p class="stat-card__label">Guest Accounts</p>
                    <p class="stat-card__value">139</p>
                    <p class="stat-card__change">97.9% of total</p>
                </div>
                <div class="stat-card">
                    <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                    <p class="stat-card__label">Active This Month</p>
                    <p class="stat-card__value">67</p>
                    <p class="stat-card__change">↑ 14% vs last month</p>
                </div>
                <div class="stat-card">
                    <svg class="stat-card__icon" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                    <p class="stat-card__label">Suspended</p>
                    <p class="stat-card__value" style="color:var(--error);">3</p>
                    <p class="stat-card__change down">Requires review</p>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="admin-toolbar">
                <div class="search-input-wrap" style="flex:2;">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                    <input type="text" id="userSearch" class="form-control"
                           placeholder="Search by name, email or phone..." oninput="filterUsers()">
                </div>
                <select id="roleFilter" class="form-control form-select" style="width:140px;" onchange="filterUsers()">
                    <option value="">All Roles</option>
                    <option value="admin">Admin</option>
                    <option value="guest">Guest</option>
                </select>
                <select id="statusFilter" class="form-control form-select" style="width:150px;" onchange="filterUsers()">
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="banned">Suspended</option>
                </select>
                <button class="btn btn--ghost btn--sm" onclick="exportUsers()">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                    Export
                </button>
            </div>

            <!-- Bulk action bar (shown when checkboxes selected) -->
            <div class="bulk-bar" id="bulkBar">
                <span class="bulk-bar__count" id="bulkCount">0 selected</span>
                <button class="btn btn--ghost btn--sm" onclick="bulkAction('suspend')">Suspend Selected</button>
                <button class="btn btn--danger btn--sm" onclick="bulkAction('delete')">Delete Selected</button>
                <button class="btn btn--ghost btn--sm" style="margin-left:auto;" onclick="clearSelection()">Clear</button>
            </div>

            <!-- Users Table -->
            <div class="table-card">
                <div class="table-card__header">
                    <h3 class="table-card__title">
                        All Users
                        <span style="font-size:0.82rem;color:var(--text-muted);font-family:var(--font-body);">(<%= users.size() %> total)</span>
                    </h3>

                </div>

                <table class="data-table" id="usersTable">
                    <thead>
                    <tr>
                        <th style="width:40px;">
                            <input type="checkbox" id="selectAll" style="accent-color:var(--gold);"
                                   onchange="toggleSelectAll(this)">
                        </th>
                        <th>User</th>
                        <th>Phone</th>
                        <th>Role</th>
                        <th>Bookings</th>
                        <th>Joined</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                    <% for (Map<String, Object> user : users) {
                        int id = (Integer) user.get("id");
                        String first = (String) user.get("firstName");
                        String last = (String) user.get("lastName");
                        String fullName = ((first == null ? "" : first) + " " + (last == null ? "" : last)).trim();
                        String role = String.valueOf(user.get("role"));
                        boolean suspended = Boolean.TRUE.equals(user.get("suspended"));
                        String joined = user.get("createdAt") == null ? "—" : joinedFormat.format(user.get("createdAt"));
                    %>
                    <tr data-role="<%= userHtml(role) %>" data-status="<%= suspended ? "banned" : "active" %>"
                        data-id="<%= id %>" data-first="<%= userHtml(first) %>" data-last="<%= userHtml(last) %>"
                        data-email="<%= userHtml(user.get("email")) %>" data-phone="<%= userHtml(user.get("phone")) %>"
                        data-bookings="<%= user.get("bookingCount") %>" data-nights="<%= user.get("nights") %>"
                        data-spent="<%= user.get("totalSpent") %>" data-joined="<%= userHtml(joined) %>">
                        <td><input type="checkbox" class="row-check" value="<%= id %>" style="accent-color:var(--gold);" onchange="updateBulkBar()"></td>
                        <td><div class="user-cell"><div class="user-cell__avatar"><%= userHtml(fullName.isEmpty() ? "?" : fullName.substring(0, 1).toUpperCase()) %></div><div>
                            <p class="user-cell__name"><%= userHtml(fullName) %></p><p class="user-cell__email"><%= userHtml(user.get("email")) %></p>
                        </div></div></td>
                        <td><%= userHtml(user.get("phone") == null ? "—" : user.get("phone")) %></td>
                        <td><span class="role-badge role-badge--<%= userHtml(role) %>"><%= userHtml(role) %></span></td>
                        <td style="text-align:center;color:var(--gold);"><%= user.get("bookingCount") %></td>
                        <td><%= userHtml(joined) %></td>
                        <td><span class="status <%= suspended ? "status--cancelled" : "status--available" %>"><%= suspended ? "Suspended" : "Active" %></span></td>
                        <td class="actions"><button type="button" class="btn btn--ghost btn--sm" onclick="viewUser(this)">View</button>
                            <button type="button" class="btn btn--ghost btn--sm" onclick="editUser(this)">Edit</button>
                            <% if (suspended) { %><button type="button" class="btn btn--primary btn--sm" onclick="userAction('reinstate',<%= id %>)">Reinstate</button>
                            <% } else { %><button type="button" class="btn btn--danger btn--sm" onclick="prepareSuspend(<%= id %>)">Suspend</button><% } %>
                            <button type="button" class="btn btn--danger btn--sm" onclick="userAction('delete',<%= id %>)">Delete</button>
                        </td>
                    </tr>
                    <% } %>
                    <% if (users.isEmpty()) { %><tr><td colspan="8" style="text-align:center;padding:2rem;">No users found.</td></tr><% } %>
                    </tbody>
                </table>

                <div class="table-info">
                    <span>Showing <%= users.size() %> users</span>

                </div>
            </div><!-- /table-card -->

        </div><!-- /admin-content -->
    </main>
</div><!-- /admin-layout -->


<!-- ══════════════════════════════════════════════════════
     MODAL: View User Details
══════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="viewModal">
    <div class="modal" style="max-width:520px;">
        <div class="modal__header">
            <h2 class="modal__title">User Profile</h2>
            <button class="modal__close" onclick="closeModal('viewModal')">✕</button>
        </div>
        <div class="modal-user-header">
            <div class="modal-avatar-lg" id="viewAvatar">A</div>
            <div class="modal-user-meta">
                <p class="modal-user-meta__name" id="viewName">—</p>
                <p class="modal-user-meta__email" id="viewEmail">—</p>
                <span class="role-badge role-badge--guest" id="viewRole" style="margin-top:6px;display:inline-flex;">Guest</span>
            </div>
        </div>
        <div class="modal-stats">
            <div class="modal-stat">
                <p class="modal-stat__num" id="viewBookings">0</p>
                <p class="modal-stat__label">Bookings</p>
            </div>
            <div class="modal-stat">
                <p class="modal-stat__num" id="viewNights">0</p>
                <p class="modal-stat__label">Nights</p>
            </div>
            <div class="modal-stat">
                <p class="modal-stat__num" id="viewSpend">₹0</p>
                <p class="modal-stat__label">Total Booking Value</p>
            </div>
        </div>
        <div class="summary-row"><span class="summary-row__label">Joined</span><span class="summary-row__value" id="viewJoined">—</span></div>
        <div class="summary-row"><span class="summary-row__label">User ID</span><span class="summary-row__value" id="viewId">—</span></div>
        <div style="display:flex;gap:0.75rem;justify-content:flex-end;margin-top:1.5rem;">
            <button class="btn btn--danger btn--sm" id="viewSuspendBtn">Suspend Account</button>
            <button class="btn btn--ghost btn--sm" onclick="closeModal('viewModal')">Close</button>
        </div>
    </div>
</div>


<!-- ══════════════════════════════════════════════════════
     MODAL: Add / Edit User
══════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="editModal">
    <div class="modal">
        <div class="modal__header">
            <h2 class="modal__title" id="editModalTitle">Add New User</h2>
            <button class="modal__close" onclick="closeModal('editModal')">✕</button>
        </div>
        <form action="../User" method="post" id="userForm">
            <input type="hidden" name="_csrf" value="<%= userCsrfToken %>">
            <input type="hidden" name="action" id="formAction" value="add">
            <input type="hidden" name="userId" id="formUserId" value="">
            <div class="form-row">
                <div class="form-group">
                    <label>First Name *</label>
                    <input type="text" name="firstName" id="formFirstName" class="form-control" required placeholder="Arjun">
                </div>
                <div class="form-group">
                    <label>Last Name *</label>
                    <input type="text" name="lastName" id="formLastName" class="form-control" required placeholder="Sharma">
                </div>
            </div>
            <div class="form-group">
                <label>Email Address *</label>
                <input type="email" name="email" id="formEmail" class="form-control" required placeholder="arjun@example.com">
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>Phone</label>
                    <input type="tel" name="phone" id="formPhone" class="form-control" placeholder="+91 98765 43210">
                </div>
                <div class="form-group">
                    <label>Role *</label>
                    <select name="role" id="formRole" class="form-control form-select" required>
                        <option value="guest">Guest</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
            </div>
            <div class="form-group" id="passwordGroup">
                <label>Password <span style="color:var(--text-muted);text-transform:none;letter-spacing:0;font-size:0.75rem;">(leave blank to keep existing)</span></label>
                <input type="password" name="password" id="formPassword" class="form-control" placeholder="12+ chars: upper, lower, number, symbol" minlength="12" maxlength="128" autocomplete="new-password">
            </div>
            <div style="display:flex;gap:0.75rem;justify-content:flex-end;margin-top:0.5rem;">
                <button type="button" class="btn btn--ghost" onclick="closeModal('editModal')">Cancel</button>
                <button type="submit" class="btn btn--primary" id="formSubmitBtn">Add User</button>
            </div>
        </form>
    </div>
</div>


<!-- ══════════════════════════════════════════════════════
     MODAL: Confirm Suspend
══════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="suspendModal">
    <div class="modal confirm-modal">
        <div class="modal__header" style="border-bottom:none;padding-bottom:0;">
            <span></span>
            <button class="modal__close" onclick="closeModal('suspendModal')">✕</button>
        </div>
        <div style="text-align:center;padding:0 1rem 1.5rem;">
            <div class="confirm-modal__icon">
                <svg width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                </svg>
            </div>
            <h3 style="font-family:var(--font-display);font-size:1.4rem;font-weight:300;margin-bottom:0.5rem;">Suspend Account</h3>
            <p style="font-size:0.87rem;color:var(--text-secondary);margin-bottom:1.5rem;" id="suspendMsg">
                This user will be unable to log in or make bookings.
            </p>
            <div class="form-group" style="text-align:left;">
                <label>Reason for Suspension</label>
                <textarea class="form-control" id="suspendReason" rows="2" maxlength="255" placeholder="Policy violation, fraudulent activity..."></textarea>
            </div>
            <div style="display:flex;gap:0.75rem;justify-content:center;margin-top:1rem;">
                <button class="btn btn--danger" onclick="confirmSuspend()">Yes, Suspend</button>
                <button class="btn btn--ghost" onclick="closeModal('suspendModal')">Cancel</button>
            </div>
        </div>
    </div>
</div>


<script>
    const userServletUrl = '<%= request.getContextPath() %>/User';
    const userCsrfToken = '<%= userCsrfToken %>';
    let pendingSuspendId = null;
    function filterUsers() {
        const search = document.getElementById('userSearch').value.toLowerCase();
        const role = document.getElementById('roleFilter').value;
        const status = document.getElementById('statusFilter').value;
        document.querySelectorAll('#usersTable tbody tr[data-id]').forEach(row => {
            const show = (!search || row.textContent.toLowerCase().includes(search)) &&
                (!role || row.dataset.role === role) && (!status || row.dataset.status === status);
            row.style.display = show ? '' : 'none';
        });
    }
    function toggleSelectAll(master) {
        document.querySelectorAll('.row-check').forEach(cb => cb.checked = master.checked);
        updateBulkBar();
    }
    function updateBulkBar() {
        const checks = document.querySelectorAll('.row-check');
        const checked = document.querySelectorAll('.row-check:checked').length;
        document.getElementById('bulkBar').classList.toggle('visible', checked > 0);
        document.getElementById('bulkCount').textContent = checked + ' selected';
        document.getElementById('selectAll').checked = checks.length > 0 && checked === checks.length;
    }
    function clearSelection() {
        document.querySelectorAll('.row-check, #selectAll').forEach(cb => cb.checked = false);
        updateBulkBar();
    }
    function submitUserAction(fields, ids) {
        const form = document.createElement('form');
        form.method = 'post'; form.action = userServletUrl;
        const add = (name, value) => {
            const input = document.createElement('input'); input.type = 'hidden';
            input.name = name; input.value = value == null ? '' : value; form.appendChild(input);
        };
        add('_csrf', userCsrfToken);
        Object.keys(fields).forEach(name => add(name, fields[name]));
        (ids || []).forEach(id => add('userIds', id));
        document.body.appendChild(form); form.submit();
    }
    function bulkAction(type) {
        const ids = Array.from(document.querySelectorAll('.row-check:checked')).map(cb => cb.value);
        if (!ids.length) return;
        if (!confirm((type === 'delete' ? 'Delete ' : 'Suspend ') + ids.length + ' selected users?' +
                (type === 'delete' ? ' This cannot be undone.' : ''))) return;
        const fields = {action: type === 'delete' ? 'bulk-delete' : 'bulk-suspend'};
        if (type === 'suspend') fields.reason = window.prompt('Reason for suspension (optional):', '') || '';
        submitUserAction(fields, ids);
    }
    function openAddModal() {
        document.getElementById('editModalTitle').textContent = 'Add New User';
        document.getElementById('formAction').value = 'add';
        document.getElementById('formUserId').value = '';
        document.getElementById('formSubmitBtn').textContent = 'Add User';
        document.getElementById('userForm').reset();
        document.getElementById('passwordGroup').querySelector('label').childNodes[0].textContent = 'Password * ';
        document.getElementById('formPassword').required = true;
        openModal('editModal');
    }
    function editUser(button) {
        const row = button.closest('tr');
        document.getElementById('editModalTitle').textContent = 'Edit User';
        document.getElementById('formAction').value = 'edit';
        document.getElementById('formUserId').value = row.dataset.id;
        document.getElementById('formFirstName').value = row.dataset.first;
        document.getElementById('formLastName').value = row.dataset.last;
        document.getElementById('formEmail').value = row.dataset.email;
        document.getElementById('formPhone').value = row.dataset.phone;
        document.getElementById('formRole').value = row.dataset.role;
        document.getElementById('formPassword').value = '';
        document.getElementById('formSubmitBtn').textContent = 'Save Changes';
        document.getElementById('passwordGroup').querySelector('label').childNodes[0].textContent = 'Password ';
        document.getElementById('formPassword').required = false;
        openModal('editModal');
    }
    function viewUser(button) {
        const row = button.closest('tr');
        const id = row.dataset.id;
        const name = (row.dataset.first + ' ' + row.dataset.last).trim();
        document.getElementById('viewAvatar').textContent = name.charAt(0) || '?';
        document.getElementById('viewName').textContent = name;
        document.getElementById('viewEmail').textContent = row.dataset.email;
        document.getElementById('viewRole').textContent = row.dataset.role;
        document.getElementById('viewRole').className = 'role-badge role-badge--' + row.dataset.role;
        document.getElementById('viewBookings').textContent = row.dataset.bookings;
        document.getElementById('viewNights').textContent = row.dataset.nights;
        document.getElementById('viewSpend').textContent = '₹' + Number(row.dataset.spent || 0).toLocaleString('en-IN');
        document.getElementById('viewJoined').textContent = row.dataset.joined;
        document.getElementById('viewId').textContent = '#USR-' + String(id).padStart(4, '0');
        const statusButton = document.getElementById('viewSuspendBtn');
        if (row.dataset.status === 'banned') {
            statusButton.textContent = 'Reinstate Account';
            statusButton.onclick = () => userAction('reinstate', id);
        } else {
            statusButton.textContent = 'Suspend Account';
            statusButton.onclick = () => { closeModal('viewModal'); prepareSuspend(id); };
        }
        openModal('viewModal');
    }
    function prepareSuspend(id) {
        pendingSuspendId = id;
        const row = document.querySelector('#usersTable tr[data-id="' + id + '"]');
        const name = row ? (row.dataset.first + ' ' + row.dataset.last).trim() : 'this user';
        document.getElementById('suspendMsg').textContent = 'Suspend "' + name + '"? They will be unable to log in or make new bookings.';
        document.getElementById('suspendReason').value = '';
        openModal('suspendModal');
    }
    function confirmSuspend() {
        submitUserAction({action: 'suspend', id: pendingSuspendId, reason: document.getElementById('suspendReason').value});
    }
    function userAction(action, id) {
        if (action === 'delete' && !confirm('Delete this user? This cannot be undone.')) return;
        if (action === 'reinstate' && !confirm('Reinstate this account?')) return;
        submitUserAction({action: action, id: id});
    }
    function openModal(id) { document.getElementById(id).classList.add('open'); }
    function closeModal(id) { document.getElementById(id).classList.remove('open'); }
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', e => { if (e.target === overlay) overlay.classList.remove('open'); });
    });
    function exportUsers() { window.print(); }
</script>
</body>
</html>
