<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession,java.util.Map" %>
<%
    /* ── Session guard ── */
    HttpSession userSession = request.getSession(false);
    String sessionName  = null;
    String sessionEmail = null;

    if (userSession != null) {
        sessionName  = (String) userSession.getAttribute("userName");
        sessionEmail = (String) userSession.getAttribute("userEmail");
    }
    if (sessionName == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    Map<String, Object> profile = (Map<String, Object>) request.getAttribute("profile");
    if (profile == null) {
        response.sendRedirect(request.getContextPath() + "/profile");
        return;
    }
    String csrfToken = (String) request.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";
    java.util.function.Function<Object, String> esc = value -> {
        if (value == null) return "";
        return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    };

    String firstName = String.valueOf(profile.get("firstName"));
    String lastName = String.valueOf(profile.get("lastName"));
    sessionEmail = String.valueOf(profile.get("email"));

    /* ── Flash messages from ProfileServlet ── */
    String successMsg = (String) request.getAttribute("success");
    String errorMsg   = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .profile-page {
            min-height: 100vh;
            padding: 7rem 0 6rem;
            background: var(--obsidian);
        }

        /* ── Page header ── */
        .profile-header {
            display: flex;
            align-items: center;
            gap: 2rem;
            margin-bottom: 3rem;
            flex-wrap: wrap;
        }
        .profile-avatar-wrap {
            position: relative;
        }
        .profile-avatar {
            width: 90px;
            height: 90px;
            border-radius: 50%;
            background: var(--gold-glow);
            border: 2px solid var(--gold-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 2.2rem;
            color: var(--gold-light);
            flex-shrink: 0;
            transition: var(--transition);
        }
        .profile-avatar:hover { border-color: var(--gold); }
        .avatar-edit-btn {
            position: absolute;
            bottom: 2px; right: 2px;
            width: 26px; height: 26px;
            background: var(--gold);
            border: none;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--obsidian);
            transition: var(--transition);
        }
        .avatar-edit-btn:hover { background: var(--gold-light); }
        .profile-header__text { flex: 1; }
        .profile-header__name {
            font-family: var(--font-display);
            font-size: clamp(1.6rem, 3vw, 2.4rem);
            font-weight: 300;
            line-height: 1.1;
            margin-bottom: 0.3rem;
        }
        .profile-header__name em { font-style: italic; color: var(--gold-light); }
        .profile-header__email { font-size: 0.85rem; color: var(--text-muted); }
        .profile-member-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            font-size: 0.62rem;
            letter-spacing: 0.25em;
            text-transform: uppercase;
            color: var(--gold);
            border: 1px solid var(--border-light);
            padding: 0.3rem 0.9rem;
            border-radius: 2px;
            margin-top: 0.6rem;
        }

        /* ── Layout ── */
        .profile-layout {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 2.5rem;
            align-items: start;
        }

        /* ── Sidebar nav ── */
        .profile-sidenav {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            overflow: hidden;
            position: sticky;
            top: 7rem;
        }
        .profile-sidenav__item {
            display: flex;
            align-items: center;
            gap: 0.8rem;
            padding: 0.9rem 1.4rem;
            font-size: 0.83rem;
            color: var(--text-secondary);
            cursor: pointer;
            border-bottom: 1px solid rgba(255,255,255,0.04);
            transition: var(--transition);
            background: none;
            border-left: none;
            border-right: none;
            border-top: none;
            font-family: var(--font-body);
            width: 100%;
            text-align: left;
            text-decoration: none;
        }
        .profile-sidenav__item:last-child { border-bottom: none; }
        .profile-sidenav__item:hover { background: var(--surface-2); color: var(--text-primary); }
        .profile-sidenav__item.active {
            background: var(--gold-glow);
            color: var(--gold);
            border-left: 2px solid var(--gold);
        }
        .profile-sidenav__item svg { width: 16px; height: 16px; flex-shrink: 0; }

        /* ── Sections ── */
        .profile-section { display: none; }
        .profile-section.active { display: block; }

        .section-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            overflow: hidden;
            margin-bottom: 1.5rem;
        }
        .section-card__header {
            padding: 1.4rem 2rem;
            border-bottom: 1px solid var(--border);
            background: var(--charcoal);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .section-card__title {
            font-family: var(--font-display);
            font-size: 1.25rem;
            font-weight: 400;
        }
        .section-card__body { padding: 2rem; }

        /* ── Password strength indicator ── */
        .pwd-strength {
            margin-top: 0.6rem;
            height: 3px;
            background: var(--border);
            border-radius: 2px;
            overflow: hidden;
        }
        .pwd-strength__bar {
            height: 100%;
            width: 0;
            border-radius: 2px;
            transition: width 0.3s ease, background 0.3s ease;
        }
        .pwd-strength__label {
            font-size: 0.7rem;
            margin-top: 0.3rem;
            color: var(--text-muted);
        }

        /* ── Preference toggles ── */
        .pref-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1rem 0;
            border-bottom: 1px solid rgba(255,255,255,0.04);
        }
        .pref-row:last-child { border-bottom: none; }
        .pref-row__info { }
        .pref-row__label {
            font-size: 0.9rem;
            color: var(--text-primary);
            margin-bottom: 0.15rem;
        }
        .pref-row__desc { font-size: 0.78rem; color: var(--text-muted); }
        /* Custom toggle */
        .toggle {
            position: relative;
            width: 42px;
            height: 24px;
            flex-shrink: 0;
        }
        .toggle input { opacity: 0; width: 0; height: 0; }
        .toggle-slider {
            position: absolute;
            inset: 0;
            background: var(--border);
            border-radius: 12px;
            cursor: pointer;
            transition: var(--transition);
        }
        .toggle-slider::before {
            content: '';
            position: absolute;
            width: 18px;
            height: 18px;
            left: 3px;
            top: 3px;
            background: var(--text-muted);
            border-radius: 50%;
            transition: var(--transition);
        }
        .toggle input:checked + .toggle-slider { background: var(--gold-muted); }
        .toggle input:checked + .toggle-slider::before {
            transform: translateX(18px);
            background: var(--gold);
        }

        /* ── Danger zone ── */
        .danger-zone {
            background: rgba(192,81,58,0.06);
            border: 1px solid rgba(192,81,58,0.2);
            border-radius: var(--radius-md);
            padding: 1.8rem 2rem;
        }
        .danger-zone__title {
            font-size: 0.65rem;
            letter-spacing: 0.3em;
            text-transform: uppercase;
            color: var(--error);
            margin-bottom: 0.6rem;
        }
        .danger-zone__text { font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 1.2rem; }

        @media (max-width: 900px) {
            .profile-layout { grid-template-columns: 1fr; }
            .profile-sidenav { position: static; display: flex; overflow-x: auto; }
            .profile-sidenav__item {
                flex-direction: column;
                text-align: center;
                padding: 0.8rem 1.2rem;
                border-bottom: none;
                border-right: 1px solid rgba(255,255,255,0.04);
                font-size: 0.72rem;
                white-space: nowrap;
                min-width: fit-content;
            }
            .profile-sidenav__item.active { border-left: none; border-bottom: 2px solid var(--gold); }
        }
        @media (max-width: 580px) {
            .section-card__body { padding: 1.5rem; }
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
                <li><a href="user-dashboard.jsp">Dashboard</a></li>
                <li><a href="profile.jsp" class="active">Profile</a></li>
            </ul>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="profile-page">
    <div class="container">

        <!-- ── Header ─────────────────────────────────────────────── -->
        <div class="profile-header">
            <div class="profile-avatar-wrap">
                <div class="profile-avatar"><%=esc.apply(firstName.isEmpty() ? "G" : firstName.substring(0,1).toUpperCase())%></div>
                <button class="avatar-edit-btn" title="Change avatar">
                    <svg width="12" height="12" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                </button>
            </div>
            <div class="profile-header__text">
                <h1 class="profile-header__name">
                    <%=esc.apply(firstName)%> <em><%=esc.apply(lastName)%></em>
                </h1>
                <p class="profile-header__email"><%=esc.apply(sessionEmail)%></p>
                <span class="profile-member-badge">
          <svg width="10" height="10" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          Guest Member
        </span>
            </div>
            <div>
                <a href="user-dashboard.jsp" class="btn btn--ghost btn--sm">← My Dashboard</a>
            </div>
        </div>

        <!-- ── Flash ──────────────────────────────────────────────── -->
        <% if (successMsg != null) { %>
        <div class="alert alert--success" style="margin-bottom:1.5rem;">
            <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            <%=esc.apply(successMsg)%>
        </div>
        <% } %>
        <% if (errorMsg != null) { %>
        <div class="alert alert--error" style="margin-bottom:1.5rem;">
            <svg width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <%=esc.apply(errorMsg)%>
        </div>
        <% } %>

        <!-- ── Layout ─────────────────────────────────────────────── -->
        <div class="profile-layout">

            <!-- Sidebar -->
            <nav class="profile-sidenav">
                <button class="profile-sidenav__item active" data-section="personal">
                    <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    Personal Info
                </button>
                <button class="profile-sidenav__item" data-section="security">
                    <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                    Password
                </button>
                <button class="profile-sidenav__item" data-section="preferences">
                    <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93l-1.41 1.41M4.93 4.93l1.41 1.41M4.93 19.07l1.41-1.41M19.07 19.07l-1.41-1.41M12 2v2M12 20v2M2 12h2M20 12h2"/></svg>
                    Preferences
                </button>
                <a href="LoginServlet?action=logout" class="profile-sidenav__item" style="color:var(--error);">
                    <svg fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    Sign Out
                </a>
            </nav>

            <!-- ── Main panels ──────────────────────────────────────── -->
            <div>

                <!-- Personal Info -->
                <div class="profile-section active" id="section-personal">
                    <div class="section-card">
                        <div class="section-card__header">
                            <h2 class="section-card__title">Personal Information</h2>
                            <span style="font-size:0.72rem;color:var(--text-muted);">Fields marked * are required</span>
                        </div>
                        <div class="section-card__body">
                            <form action="ProfileServlet" method="post" id="personalForm">
                                <input type="hidden" name="action" value="updatePersonal">
                                <input type="hidden" name="_csrf" value="<%=esc.apply(csrfToken)%>">

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="pfFirst">First Name *</label>
                                        <input type="text" id="pfFirst" name="firstName" class="form-control"
                                               value="<%=esc.apply(firstName)%>" required maxlength="60">
                                    </div>
                                    <div class="form-group">
                                        <label for="pfLast">Last Name *</label>
                                        <input type="text" id="pfLast" name="lastName" class="form-control"
                                               value="<%=esc.apply(lastName)%>" required maxlength="60">
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label for="pfEmail">Email Address *</label>
                                    <input type="email" id="pfEmail" name="email" class="form-control"
                                           value="<%=esc.apply(sessionEmail)%>" required maxlength="150" readonly>
                                    <p class="form-hint">Changing your email requires re-verification.</p>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="pfPhone">Phone Number</label>
                                        <input type="tel" id="pfPhone" name="phone" class="form-control"
                                               value="<%=esc.apply(profile.get("phone"))%>" maxlength="20">
                                    </div>
                                    <div class="form-group">
                                        <label for="pfDob">Date of Birth</label>
                                        <input type="date" id="pfDob" name="dob" class="form-control" value="<%=esc.apply(profile.get("dob"))%>">
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label for="pfAddress">Address</label>
                                    <textarea id="pfAddress" name="address" class="form-control" rows="2"
                                              maxlength="255"><%=esc.apply(profile.get("address"))%></textarea>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="pfCity">City</label>
                                        <input type="text" id="pfCity" name="city" class="form-control" maxlength="80" value="<%=esc.apply(profile.get("city"))%>">
                                    </div>
                                    <div class="form-group">
                                        <label for="pfCountry">Country</label>
                                        <select id="pfCountry" name="country" class="form-control form-select">
                                            <option <%= "India".equals(profile.get("country")) ? "selected" : "" %>>India</option>
                                            <option <%= "United States".equals(profile.get("country")) ? "selected" : "" %>>United States</option>
                                            <option <%= "United Kingdom".equals(profile.get("country")) ? "selected" : "" %>>United Kingdom</option>
                                            <option <%= "UAE".equals(profile.get("country")) ? "selected" : "" %>>UAE</option>
                                            <option <%= "Singapore".equals(profile.get("country")) ? "selected" : "" %>>Singapore</option>
                                            <option <%= "Other".equals(profile.get("country")) ? "selected" : "" %>>Other</option>
                                        </select>
                                    </div>
                                </div>

                                <div style="display:flex;gap:0.8rem;margin-top:0.5rem;flex-wrap:wrap;">
                                    <button type="submit" class="btn btn--primary">Save Changes</button>
                                    <button type="reset" class="btn btn--ghost">Discard</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div><!-- /personal -->


                <!-- Security / Password -->
                <div class="profile-section" id="section-security">
                    <div class="section-card">
                        <div class="section-card__header">
                            <h2 class="section-card__title">Change Password</h2>
                        </div>
                        <div class="section-card__body">
                            <form action="ProfileServlet" method="post" id="passwordForm">
                                <input type="hidden" name="action" value="updatePassword">
                                <input type="hidden" name="_csrf" value="<%=esc.apply(csrfToken)%>">

                                <div class="form-group">
                                    <label for="pfCurrentPwd">Current Password</label>
                                    <input type="password" id="pfCurrentPwd" name="currentPassword"
                                           class="form-control" placeholder="••••••••" required>
                                </div>

                                <div class="form-group">
                                    <label for="pfNewPwd">New Password</label>
                                    <input type="password" id="pfNewPwd" name="newPassword"
                                           class="form-control" placeholder="Min. 12 characters" minlength="12" maxlength="128"
                                           required oninput="checkStrength(this.value)">
                                    <div class="pwd-strength">
                                        <div class="pwd-strength__bar" id="strengthBar"></div>
                                    </div>
                                    <p class="pwd-strength__label" id="strengthLabel">Enter a new password</p>
                                </div>

                                <div class="form-group">
                                    <label for="pfConfirmPwd">Confirm New Password</label>
                                    <input type="password" id="pfConfirmPwd" name="confirmPassword"
                                           class="form-control" placeholder="Repeat new password" required>
                                    <span class="form-error" id="pwdMatchErr">Passwords do not match.</span>
                                </div>

                                <button type="submit" class="btn btn--primary">Update Password</button>
                            </form>
                        </div>
                    </div>

                    <!-- Danger zone -->
                    <div class="danger-zone">
                        <p class="danger-zone__title">⚠ &nbsp; Danger Zone</p>
                        <p class="danger-zone__text">
                            Permanently delete your account and all associated booking history.
                            This action cannot be reversed.
                        </p>
                        <button type="button" class="btn btn--danger btn--sm" onclick="confirmDelete()">
                            Delete My Account
                        </button>
                    </div>
                </div><!-- /security -->


                <!-- Preferences -->
                <div class="profile-section" id="section-preferences">
                    <div class="section-card">
                        <div class="section-card__header">
                            <h2 class="section-card__title">Notifications &amp; Preferences</h2>
                        </div>
                        <div class="section-card__body">
                            <form action="ProfileServlet" method="post">
                                <input type="hidden" name="action" value="updatePreferences">
                                <input type="hidden" name="_csrf" value="<%=esc.apply(csrfToken)%>">

                                <div class="pref-row">
                                    <div class="pref-row__info">
                                        <p class="pref-row__label">Booking Confirmations</p>
                                        <p class="pref-row__desc">Receive email when a booking is confirmed or modified.</p>
                                    </div>
                                    <label class="toggle">
                                        <input type="checkbox" name="notifBooking" <%=Boolean.TRUE.equals(profile.get("notifBooking")) ? "checked" : ""%>>
                                        <span class="toggle-slider"></span>
                                    </label>
                                </div>

                                <div class="pref-row">
                                    <div class="pref-row__info">
                                        <p class="pref-row__label">Check-In Reminders</p>
                                        <p class="pref-row__desc">Get a reminder 24 hours before your stay begins.</p>
                                    </div>
                                    <label class="toggle">
                                        <input type="checkbox" name="notifReminder" <%=Boolean.TRUE.equals(profile.get("notifReminder")) ? "checked" : ""%>>
                                        <span class="toggle-slider"></span>
                                    </label>
                                </div>

                                <div class="pref-row">
                                    <div class="pref-row__info">
                                        <p class="pref-row__label">Special Offers &amp; Promotions</p>
                                        <p class="pref-row__desc">Exclusive member rates and seasonal packages.</p>
                                    </div>
                                    <label class="toggle">
                                        <input type="checkbox" name="notifPromos" <%=Boolean.TRUE.equals(profile.get("notifPromos")) ? "checked" : ""%>>
                                        <span class="toggle-slider"></span>
                                    </label>
                                </div>

                                <div class="pref-row">
                                    <div class="pref-row__info">
                                        <p class="pref-row__label">SMS Notifications</p>
                                        <p class="pref-row__desc">Receive booking updates via SMS to your registered number.</p>
                                    </div>
                                    <label class="toggle">
                                        <input type="checkbox" name="notifSms" <%=Boolean.TRUE.equals(profile.get("notifSms")) ? "checked" : ""%>>
                                        <span class="toggle-slider"></span>
                                    </label>
                                </div>

                                <div style="margin-top:1.8rem;padding-top:1.5rem;border-top:1px solid var(--border);">
                                    <div class="form-group">
                                        <label for="pfLang">Preferred Language</label>
                                        <select id="pfLang" name="language" class="form-control form-select" style="max-width:280px;">
                                            <option value="English" <%= "English".equals(profile.get("language")) ? "selected" : "" %>>English</option>
                                            <option value="Hindi" <%= "Hindi".equals(profile.get("language")) ? "selected" : "" %>>Hindi</option>
                                            <option value="Punjabi" <%= "Punjabi".equals(profile.get("language")) ? "selected" : "" %>>Punjabi</option>
                                            <option value="Arabic" <%= "Arabic".equals(profile.get("language")) ? "selected" : "" %>>Arabic</option>
                                        </select>
                                    </div>
                                    <div class="form-group" style="margin-top:1.2rem;">
                                        <label for="pfCurrency">Preferred Currency</label>
                                        <select id="pfCurrency" name="currency" class="form-control form-select" style="max-width:280px;">
                                            <option value="INR" <%= "INR".equals(profile.get("currency")) ? "selected" : "" %>>INR — Indian Rupee (₹)</option>
                                            <option value="USD" <%= "USD".equals(profile.get("currency")) ? "selected" : "" %>>USD — US Dollar ($)</option>
                                            <option value="GBP" <%= "GBP".equals(profile.get("currency")) ? "selected" : "" %>>GBP — British Pound (£)</option>
                                            <option value="AED" <%= "AED".equals(profile.get("currency")) ? "selected" : "" %>>AED — UAE Dirham (د.إ)</option>
                                        </select>
                                    </div>
                                </div>

                                <button type="submit" class="btn btn--primary" style="margin-top:0.5rem;">
                                    Save Preferences
                                </button>
                            </form>
                        </div>
                    </div>
                </div><!-- /preferences -->

            </div><!-- /right col -->
        </div><!-- /profile-layout -->

    </div><!-- /container -->
</div><!-- /profile-page -->

<form id="deleteAccountForm" action="ProfileServlet" method="post" style="display:none">
    <input type="hidden" name="action" value="deleteAccount">
    <input type="hidden" name="_csrf" value="<%=esc.apply(csrfToken)%>">
    <input type="hidden" name="currentPassword" id="deleteCurrentPassword">
</form>
<script>
    /* ── Sidebar navigation ── */
    const navBtns  = document.querySelectorAll('.profile-sidenav__item[data-section]');
    const sections = document.querySelectorAll('.profile-section');

    navBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            navBtns.forEach(b => b.classList.remove('active'));
            sections.forEach(s => s.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById('section-' + btn.dataset.section).classList.add('active');
        });
    });

    /* ── Password strength ── */
    function checkStrength(val) {
        const bar   = document.getElementById('strengthBar');
        const label = document.getElementById('strengthLabel');
        let score = 0;
        if (val.length >= 12)         score++;
        if (val.length >= 12)         score++;
        if (/[A-Z]/.test(val))        score++;
        if (/[0-9]/.test(val))        score++;
        if (/[^A-Za-z0-9]/.test(val)) score++;

        const cfg = [
            { w: '0%',   bg: 'transparent', lbl: 'Enter a new password' },
            { w: '25%',  bg: 'var(--error)', lbl: 'Weak' },
            { w: '50%',  bg: 'var(--warning)', lbl: 'Fair' },
            { w: '75%',  bg: '#a0a020', lbl: 'Good' },
            { w: '100%', bg: 'var(--success)', lbl: 'Strong' },
        ];
        const c = cfg[Math.min(score, 4)];
        bar.style.width      = c.w;
        bar.style.background = c.bg;
        label.textContent    = c.lbl;
        label.style.color    = score > 0 ? c.bg : 'var(--text-muted)';
    }

    /* ── Password match validation ── */
    document.getElementById('passwordForm').addEventListener('submit', function(e) {
        const p1 = document.getElementById('pfNewPwd').value;
        const p2 = document.getElementById('pfConfirmPwd').value;
        if (p1 !== p2) {
            document.getElementById('pwdMatchErr').classList.add('visible');
            e.preventDefault();
        } else {
            document.getElementById('pwdMatchErr').classList.remove('visible');
        }
    });

    /* ── Delete account confirm ── */
    function confirmDelete() {
        if (!confirm('Permanently delete your account? Upcoming bookings must be completed or cancelled first.')) return;
        const password = prompt('Enter your current password to confirm account deletion:');
        if (password === null || password.length === 0) return;
        document.getElementById('deleteCurrentPassword').value = password;
        document.getElementById('deleteAccountForm').submit();
    }

    /* ── Auto-show section from hash ── */
    const hash = window.location.hash.replace('#', '');
    if (hash) {
        const btn = document.querySelector('.profile-sidenav__item[data-section="' + hash + '"]');
        if (btn) btn.click();
    }
</script>
<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
    &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
    <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
