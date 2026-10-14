<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession,java.util.List,java.util.Map" %>
<%!
    private String dashboardEscape(Object value) {
        if (value == null) return "";
        return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    HttpSession userSession = request.getSession(false);
    if (userSession == null || !"guest".equals(userSession.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/user-dashboard");
        return;
    }
    if (request.getAttribute("dashboardBookings") == null) {
        response.sendRedirect(request.getContextPath() + "/user-dashboard");
        return;
    }
    List<Map<String, Object>> dashboardBookings = (List<Map<String, Object>>) request.getAttribute("dashboardBookings");
    Map<String, Object> upcomingBooking = (Map<String, Object>) request.getAttribute("upcomingBooking");
    String firstName = dashboardEscape(request.getAttribute("dashboardFirstName"));
    String sessionName = dashboardEscape(request.getAttribute("dashboardName"));
    String sessionEmail = dashboardEscape(request.getAttribute("dashboardEmail"));
    String csrfToken = String.valueOf(request.getAttribute("csrfToken"));
    String dashboardMessage = "cancelled".equals(request.getParameter("status"))
            ? "Your unpaid booking was cancelled." : null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Dashboard — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Dashboard page shell ── */
        .dashboard-page {
            min-height: 100vh;
            padding-top: 5rem;
            background: var(--obsidian);
        }

        /* ── Profile strip at top ── */
        .dash-hero {
            background: var(--deep-navy);
            border-bottom: 1px solid var(--border);
            padding: 3rem 0 0;
            position: relative;
            overflow: hidden;
        }
        .dash-hero::before {
            content: '';
            position: absolute;
            inset: 0;
            background: radial-gradient(ellipse 50% 80% at 80% 50%,
            rgba(200,170,100,0.05) 0%, transparent 60%);
        }
        .dash-hero__inner {
            position: relative;
            display: flex;
            align-items: flex-end;
            gap: 2rem;
            flex-wrap: wrap;
        }
        .dash-avatar {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: var(--gold-glow);
            border: 2px solid var(--gold-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 1.8rem;
            color: var(--gold-light);
            flex-shrink: 0;
        }
        .dash-hero__text { flex: 1; }
        .dash-greeting {
            font-size: 0.65rem;
            letter-spacing: 0.35em;
            text-transform: uppercase;
            color: var(--gold);
            margin-bottom: 0.4rem;
        }
        .dash-name {
            font-family: var(--font-display);
            font-size: clamp(1.8rem, 3vw, 2.6rem);
            font-weight: 300;
            line-height: 1.1;
        }
        .dash-name em { font-style: italic; color: var(--gold-light); }
        .dash-email {
            font-size: 0.82rem;
            color: var(--text-muted);
            margin-top: 0.3rem;
        }

        /* ── Tab strip ── */
        .dash-tabs {
            display: flex;
            gap: 0;
            margin-top: 2rem;
            border-top: 1px solid var(--border);
        }
        .dash-tab {
            padding: 0.9rem 1.8rem;
            font-size: 0.72rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
            cursor: pointer;
            border-bottom: 2px solid transparent;
            transition: var(--transition);
            background: none;
            border-left: none;
            border-right: none;
            border-top: none;
            font-family: var(--font-body);
        }
        .dash-tab:hover { color: var(--text-primary); }
        .dash-tab.active {
            color: var(--gold);
            border-bottom-color: var(--gold);
        }

        /* ── Content area ── */
        .dash-content { padding: 3rem 0 6rem; }

        /* ── Stat strip ── */
        .dash-stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 1.2rem;
            margin-bottom: 3rem;
        }
        .dash-stat {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 1.5rem;
            text-align: center;
            transition: var(--transition);
            position: relative;
            overflow: hidden;
        }
        .dash-stat::after {
            content: '';
            position: absolute;
            bottom: 0; left: 0; right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--gold-muted), transparent);
            transform: scaleX(0);
            transition: var(--transition);
        }
        .dash-stat:hover { border-color: var(--border-light); }
        .dash-stat:hover::after { transform: scaleX(1); }
        .dash-stat__num {
            font-family: var(--font-display);
            font-size: 2.4rem;
            font-weight: 300;
            color: var(--gold-light);
            line-height: 1;
            margin-bottom: 0.4rem;
        }
        .dash-stat__label {
            font-size: 0.65rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
        }

        /* ── Panel heading ── */
        .panel-heading {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 1.5rem;
        }
        .panel-title {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 300;
        }

        /* ── Booking cards (timeline style) ── */
        .booking-timeline {
            display: flex;
            flex-direction: column;
            gap: 1.2rem;
        }
        .booking-tile {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            overflow: hidden;
            display: grid;
            grid-template-columns: 4px 1fr auto;
            transition: var(--transition);
        }
        .booking-tile:hover { border-color: var(--border-light); box-shadow: var(--shadow-card); }
        .booking-tile__accent { background: var(--gold-muted); }
        .booking-tile__accent--confirmed { background: var(--success); }
        .booking-tile__accent--pending   { background: var(--warning); }
        .booking-tile__accent--cancelled { background: var(--error); }
        .booking-tile__body {
            padding: 1.4rem 1.8rem;
            display: grid;
            grid-template-columns: 1fr 1fr 1fr 1fr;
            gap: 1rem;
            align-items: center;
        }
        .booking-tile__ref {
            font-family: var(--font-display);
            font-size: 1.1rem;
            color: var(--gold-light);
            line-height: 1;
            margin-bottom: 0.3rem;
        }
        .booking-tile__room {
            font-size: 0.82rem;
            color: var(--text-muted);
        }
        .booking-tile__label {
            font-size: 0.62rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 0.25rem;
        }
        .booking-tile__value {
            font-size: 0.9rem;
            color: var(--text-primary);
        }
        .booking-tile__actions {
            padding: 1.4rem 1.5rem;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            justify-content: center;
            border-left: 1px solid var(--border);
            min-width: 130px;
        }

        /* ── Upcoming stay highlight ── */
        .upcoming-card {
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            overflow: hidden;
            margin-bottom: 3rem;
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
        .upcoming-card__visual {
            background: linear-gradient(140deg, #1e1a2c 0%, #2e2440 100%);
            padding: 3rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 220px;
            position: relative;
            overflow: hidden;
        }
        .upcoming-card__visual::before {
            content: '';
            position: absolute;
            inset: 0;
            background: radial-gradient(ellipse 60% 60% at 30% 30%,
            rgba(200,170,100,0.08) 0%, transparent 60%);
        }
        .upcoming-card__visual-content { position: relative; }
        .upcoming-label {
            font-size: 0.6rem;
            letter-spacing: 0.35em;
            text-transform: uppercase;
            color: var(--gold);
            border: 1px solid var(--border-light);
            display: inline-block;
            padding: 0.25rem 0.7rem;
            border-radius: 2px;
            margin-bottom: 1.2rem;
        }
        .upcoming-room-name {
            font-family: var(--font-display);
            font-size: 1.8rem;
            font-weight: 300;
            line-height: 1.2;
        }
        .upcoming-room-name em { font-style: italic; color: var(--gold-light); }
        .upcoming-countdown {
            font-size: 0.78rem;
            color: var(--text-muted);
            margin-top: 0.5rem;
        }
        .upcoming-countdown span { color: var(--gold); font-weight: 500; }
        .upcoming-card__info { padding: 2.5rem 2rem; }
        .upcoming-detail-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1.2rem;
            margin-bottom: 1.5rem;
        }
        .upcoming-detail { }
        .upcoming-detail__label {
            font-size: 0.62rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 0.25rem;
        }
        .upcoming-detail__value {
            font-size: 0.95rem;
            color: var(--text-primary);
        }

        /* ── Empty state ── */
        .empty-state {
            text-align: center;
            padding: 5rem 2rem;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
        }
        .empty-state__icon {
            width: 56px; height: 56px;
            border: 1px solid var(--border-light);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            color: var(--gold);
        }
        .empty-state__title {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 300;
            margin-bottom: 0.5rem;
        }
        .empty-state__text {
            font-size: 0.9rem;
            color: var(--text-muted);
            margin-bottom: 1.5rem;
        }

        /* ── Tab panels ── */
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        @media (max-width: 1024px) {
            .dash-stats        { grid-template-columns: repeat(2, 1fr); }
            .booking-tile__body{ grid-template-columns: 1fr 1fr; }
            .upcoming-card     { grid-template-columns: 1fr; }
        }
        @media (max-width: 640px) {
            .dash-stats        { grid-template-columns: repeat(2, 1fr); }
            .dash-tabs         { overflow-x: auto; }
            .booking-tile      { grid-template-columns: 4px 1fr; }
            .booking-tile__actions { display:none; }
            .booking-tile__body{ grid-template-columns: 1fr; }
            .upcoming-detail-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<!-- ── Navbar ───────────────────────────────────────────────── -->
<nav class="navbar scrolled">
    <div class="container">
        <div class="navbar__inner">
            <a href="index.jsp" class="navbar__logo">
                <span class="navbar__logo-main">Grand Horizon</span>
                <span class="navbar__logo-sub">Luxury Hotel &amp; Suites</span>
            </a>
            <ul class="navbar__links">
                <li><a href="index.jsp">Home</a></li>
                <li><a href="rooms.jsp">Rooms</a></li>
                <li><a href="booking.jsp">Book</a></li>
                <li><a href="contact.jsp">Contact</a></li>
                <li><a href="user-dashboard.jsp" class="active">Dashboard</a></li>
            </ul>
            <a href="<%=request.getContextPath()%>/profile" class="btn navbar__cta">My Profile</a>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="dashboard-page">

    <!-- ── Profile Hero ─────────────────────────────────────────── -->
    <div class="dash-hero">
        <div class="container">
            <div class="dash-hero__inner">
                <div class="dash-avatar"><%=firstName.substring(0,1).toUpperCase()%></div>
                <div class="dash-hero__text">
                    <p class="dash-greeting">Welcome back</p>
                    <h1 class="dash-name">Good to see you, <em><%=firstName%></em></h1>
                    <p class="dash-email"><%=sessionEmail%></p>
                </div>
                <div style="padding-bottom:1.2rem;">
                    <a href="booking.jsp" class="btn btn--primary btn--sm">New Reservation</a>
                </div>
            </div>

            <!-- Tabs -->
            <div class="dash-tabs">
                <button class="dash-tab active" data-tab="overview">Overview</button>
                <button class="dash-tab" data-tab="bookings">My Bookings</button>
                <button class="dash-tab" data-tab="profile">Profile</button>
            </div>
        </div>
    </div>

    <!-- ── Content ──────────────────────────────────────────────── -->
    <div class="dash-content">
        <div class="container">

            <% if (dashboardMessage != null) { %><div class="alert alert--success" role="status"><%=dashboardEscape(dashboardMessage)%></div><% } %>

            <!-- ══════════════ OVERVIEW TAB ══════════════ -->
            <div class="tab-panel active" id="tab-overview">

                <!-- Stats -->
                <div class="dash-stats">
                    <div class="dash-stat">
                        <p class="dash-stat__num"><%=request.getAttribute("totalBookings")%></p>
                        <p class="dash-stat__label">Total Bookings</p>
                    </div>
                    <div class="dash-stat">
                        <p class="dash-stat__num"><%=request.getAttribute("upcomingCount")%></p>
                        <p class="dash-stat__label">Upcoming</p>
                    </div>
                    <div class="dash-stat">
                        <p class="dash-stat__num"><%=request.getAttribute("nightsStayed")%></p>
                        <p class="dash-stat__label">Nights Stayed</p>
                    </div>
                    <div class="dash-stat">
                        <p class="dash-stat__num" style="font-size:1.8rem;"><%=dashboardEscape(request.getAttribute("totalSpent"))%></p>
                        <p class="dash-stat__label">Total Spent</p>
                    </div>
                </div>

                <!-- Upcoming Stay -->
                <div class="panel-heading">
                    <h2 class="panel-title">Upcoming <em style="font-style:italic;color:var(--gold-light);">Stay</em></h2>
                </div>
                <% if (upcomingBooking != null) { %>
                <div class="upcoming-card">
                    <div class="upcoming-card__visual">
                        <div class="upcoming-card__visual-content">
                            <span class="upcoming-label">Next Stay</span>
                            <p class="upcoming-room-name"><%=dashboardEscape(upcomingBooking.get("room"))%></p>
                            <p class="upcoming-countdown">Check-in: <span><%=dashboardEscape(upcomingBooking.get("checkin"))%></span></p>
                        </div>
                        <p style="font-size:0.8rem;color:var(--text-muted);position:relative;">Room <%=dashboardEscape(upcomingBooking.get("roomNumber"))%> ? <%=dashboardEscape(upcomingBooking.get("floor"))%> floor</p>
                    </div>
                    <div class="upcoming-card__info">
                        <div class="upcoming-detail-grid">
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Booking Ref</p><p class="upcoming-detail__value" style="color:var(--gold);">#<%=dashboardEscape(upcomingBooking.get("ref"))%></p></div>
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Status</p><p class="upcoming-detail__value"><%=dashboardEscape(upcomingBooking.get("status"))%></p></div>
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Check-In</p><p class="upcoming-detail__value"><%=dashboardEscape(upcomingBooking.get("checkin"))%></p></div>
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Check-Out</p><p class="upcoming-detail__value"><%=dashboardEscape(upcomingBooking.get("checkout"))%></p></div>
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Guests</p><p class="upcoming-detail__value"><%=dashboardEscape(upcomingBooking.get("guests"))%></p></div>
                            <div class="upcoming-detail"><p class="upcoming-detail__label">Total</p><p class="upcoming-detail__value"><%=dashboardEscape(upcomingBooking.get("total"))%></p></div>
                        </div>
                        <% if (Boolean.TRUE.equals(upcomingBooking.get("canCancel"))) { %>
                        <form action="<%=request.getContextPath()%>/booking" method="post" onsubmit="return confirm('Cancel this unpaid reservation?')">
                            <input type="hidden" name="action" value="guest-cancel"><input type="hidden" name="ref" value="<%=dashboardEscape(upcomingBooking.get("ref"))%>"><input type="hidden" name="_csrf" value="<%=dashboardEscape(csrfToken)%>">
                            <button class="btn btn--ghost btn--sm" type="submit">Cancel unpaid booking</button>
                        </form>
                        <% } %>
                    </div>
                </div>
                <% } else { %><div class="empty-state"><h3 class="empty-state__title">No upcoming stay</h3><p class="empty-state__text">Your upcoming reservations will appear here.</p><a href="booking.jsp" class="btn btn--primary btn--sm">Book a stay</a></div><% } %>

                <!-- Recent activity -->
                <div class="panel-heading">
                    <h2 class="panel-title">Recent <em style="font-style:italic;color:var(--gold-light);">Activity</em></h2>
                    <button class="dash-tab" onclick="switchTab('bookings')" style="padding:0;border:none;">View all →</button>
                </div>
                <div class="booking-timeline">
                    <% int recentIndex = 0; for (Map<String, Object> item : dashboardBookings) { if (recentIndex++ >= 3) break; %>
                    <div class="booking-tile">
                        <div class="booking-tile__accent booking-tile__accent--<%=item.get("statusClass")%>"></div>
                        <div class="booking-tile__body">
                            <div><p class="booking-tile__ref">#<%=dashboardEscape(item.get("ref"))%></p><p class="booking-tile__room"><%=dashboardEscape(item.get("room"))%> ? <%=dashboardEscape(item.get("roomNumber"))%></p></div>
                            <div><p class="booking-tile__label">Check-In</p><p class="booking-tile__value"><%=dashboardEscape(item.get("checkin"))%></p></div>
                            <div><p class="booking-tile__label">Duration</p><p class="booking-tile__value"><%=dashboardEscape(item.get("nights"))%> nights</p></div>
                            <div><p class="booking-tile__label">Total</p><p class="booking-tile__value"><%=dashboardEscape(item.get("total"))%></p></div>
                        </div>
                        <div class="booking-tile__actions"><span class="status status--<%=item.get("statusClass")%>"><%=dashboardEscape(item.get("status"))%></span></div>
                    </div>
                    <% } if (dashboardBookings.isEmpty()) { %><p class="empty-state__text">No booking activity yet.</p><% } %>
                </div><!-- /booking-timeline -->
            </div><!-- /overview tab -->


            <!-- ══════════════ BOOKINGS TAB ══════════════ -->
            <div class="tab-panel" id="tab-bookings">

                <div class="panel-heading" style="margin-bottom:2rem;">
                    <h2 class="panel-title">All <em style="font-style:italic;color:var(--gold-light);">Bookings</em></h2>
                    <a href="booking.jsp" class="btn btn--primary btn--sm">+ New Booking</a>
                </div>

                <!-- Filter row -->
                <div style="display:flex;gap:0.8rem;margin-bottom:1.5rem;flex-wrap:wrap;">
                    <button class="filter-btn active" data-bfilter="all">All</button>
                    <button class="filter-btn" data-bfilter="confirmed">Confirmed</button>
                    <button class="filter-btn" data-bfilter="pending">Pending</button>
                    <button class="filter-btn" data-bfilter="cancelled">Cancelled</button>
                </div>

                <div class="booking-timeline" id="allBookings">
                    <% for (Map<String, Object> item : dashboardBookings) { %>
                    <div class="booking-tile" data-status="<%=item.get("filterStatus")%>">
                        <div class="booking-tile__accent booking-tile__accent--<%=item.get("statusClass")%>"></div>
                        <div class="booking-tile__body">
                            <div><p class="booking-tile__ref">#<%=dashboardEscape(item.get("ref"))%></p><p class="booking-tile__room"><%=dashboardEscape(item.get("room"))%> ? <%=dashboardEscape(item.get("roomNumber"))%></p></div>
                            <div><p class="booking-tile__label">Check-In</p><p class="booking-tile__value"><%=dashboardEscape(item.get("checkin"))%></p></div>
                            <div><p class="booking-tile__label">Duration</p><p class="booking-tile__value"><%=dashboardEscape(item.get("nights"))%> nights</p></div>
                            <div><p class="booking-tile__label">Total</p><p class="booking-tile__value"><%=dashboardEscape(item.get("total"))%></p></div>
                        </div>
                        <div class="booking-tile__actions"><span class="status status--<%=item.get("statusClass")%>"><%=dashboardEscape(item.get("status"))%></span>
                        <% if (Boolean.TRUE.equals(item.get("canCancel"))) { %>
                        <form action="<%=request.getContextPath()%>/booking" method="post" onsubmit="return confirm('Cancel this unpaid reservation?')">
                            <input type="hidden" name="action" value="guest-cancel"><input type="hidden" name="ref" value="<%=dashboardEscape(item.get("ref"))%>"><input type="hidden" name="_csrf" value="<%=dashboardEscape(csrfToken)%>"><button class="btn btn--ghost btn--sm" type="submit">Cancel</button>
                        </form><% } %></div>
                    </div>
                    <% } if (dashboardBookings.isEmpty()) { %><div class="empty-state"><h3 class="empty-state__title">No bookings yet</h3><p class="empty-state__text">Your reservations will appear here once you book a stay.</p><a href="booking.jsp" class="btn btn--primary btn--sm">Book a stay</a></div><% } %>
                </div><!-- /allBookings -->
            </div><!-- /bookings tab -->


            <!-- ══════════════ PROFILE TAB ══════════════ -->
            <div class="tab-panel" id="tab-profile">
                <div style="max-width:680px;">
                    <div class="panel-heading" style="margin-bottom:2rem;">
                        <h2 class="panel-title">My <em style="font-style:italic;color:var(--gold-light);">Profile</em></h2>
                    </div>
                    <div style="background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-md);padding:0.5rem 0;margin-bottom:2rem;">
                        <div class="policy-row" style="padding:1.2rem 2rem;">
                            <span class="policy-row__key">Full Name</span>
                            <span class="policy-row__val"><%=sessionName%></span>
                        </div>
                        <div class="policy-row" style="padding:1.2rem 2rem;">
                            <span class="policy-row__key">Email</span>
                            <span class="policy-row__val"><%=sessionEmail%></span>
                        </div>
                        <div class="policy-row" style="padding:1.2rem 2rem;">
                            <span class="policy-row__key">Member Since</span>
                            <span class="policy-row__val"><%=dashboardEscape(request.getAttribute("memberSince"))%></span>
                        </div>
                        <div class="policy-row" style="padding:1.2rem 2rem;border-bottom:none;">
                            <span class="policy-row__key">Account Type</span>
                            <span class="policy-row__val">Guest Member</span>
                        </div>
                    </div>
                    <div style="display:flex;gap:0.8rem;flex-wrap:wrap;">
                        <a href="<%=request.getContextPath()%>/profile" class="btn btn--primary">Edit Profile</a>
                        <a href="<%=request.getContextPath()%>/logout" class="btn btn--ghost">Sign Out</a>
                    </div>
                </div>
            </div><!-- /profile tab -->

        </div><!-- /container -->
    </div><!-- /dash-content -->
</div><!-- /dashboard-page -->

<script>
    /* ── Tab switching ── */
    const tabs   = document.querySelectorAll('.dash-tab[data-tab]');
    const panels = document.querySelectorAll('.tab-panel');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => switchTab(tab.dataset.tab));
    });

    function switchTab(id) {
        tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === id));
        panels.forEach(p => p.classList.toggle('active', p.id === 'tab-' + id));
    }

    /* ── Booking filter ── */
    document.querySelectorAll('.filter-btn[data-bfilter]').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.filter-btn[data-bfilter]').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            const f = this.dataset.bfilter;
            document.querySelectorAll('#allBookings .booking-tile').forEach(tile => {
                tile.style.display = (f === 'all' || tile.dataset.status === f) ? '' : 'none';
            });
        });
    });

</script>
<div style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
    &copy; 2026 Grand Horizon Hotel &nbsp;·&nbsp;
    <a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy</a>
    &nbsp;·&nbsp;
    <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a>
</div>
</body>
</html>
