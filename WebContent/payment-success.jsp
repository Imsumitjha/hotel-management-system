<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String bookingRef      = (String) request.getAttribute("bookingRef");
    String roomType        = (String) request.getAttribute("roomType");
    String checkinFmt      = (String) request.getAttribute("checkinFmt");
    String checkoutFmt     = (String) request.getAttribute("checkoutFmt");
    String amountFormatted = (String) request.getAttribute("amountFormatted");
    String paymentId       = (String) request.getAttribute("paymentId");
    String guestName       = (String) request.getAttribute("guestName");
    String guestEmail      = (String) request.getAttribute("guestEmail");
    Object nightsObj       = request.getAttribute("nights");

    if (bookingRef == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp");
        return;
    }

    long nights = nightsObj != null ? Long.parseLong(nightsObj.toString()) : 1;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Successful — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .success-page {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 6rem 1.5rem 4rem;
            background: var(--obsidian);
            position: relative;
            overflow: hidden;
        }
        .success-page::before {
            content: '';
            position: absolute; inset: 0;
            background:
                    radial-gradient(ellipse 50% 40% at 50% 30%,
                    rgba(74,140,106,0.06) 0%, transparent 60%),
                    radial-gradient(ellipse 40% 30% at 50% 70%,
                    rgba(200,170,100,0.05) 0%, transparent 55%);
            pointer-events: none;
        }
        .success-card {
            position: relative;
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            max-width: 620px;
            width: 100%;
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0,0,0,0.5),
            0 0 40px rgba(74,140,106,0.06);
            animation: cardRise 0.7s cubic-bezier(0.4,0,0.2,1) both;
        }
        @keyframes cardRise {
            from { opacity:0; transform:translateY(28px); }
            to   { opacity:1; transform:translateY(0); }
        }

        /* Gold top line */
        .success-card::before {
            content: '';
            position: absolute;
            top: 0; left: 15%; right: 15%; height: 2px;
            background: linear-gradient(90deg, transparent, #4a8c6a, transparent);
        }

        /* Header */
        .success-header {
            padding: 3rem 3rem 2rem;
            text-align: center;
            border-bottom: 1px solid var(--border);
        }
        .success-icon-wrap {
            width: 80px; height: 80px;
            border-radius: 50%;
            background: rgba(74,140,106,0.08);
            border: 1px solid rgba(74,140,106,0.3);
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 1.5rem;
            animation: popIn 0.6s 0.2s cubic-bezier(0.34,1.56,0.64,1) both;
        }
        @keyframes popIn {
            from { opacity:0; transform:scale(0.4); }
            to   { opacity:1; transform:scale(1); }
        }
        .success-icon-wrap svg {
            width: 36px; height: 36px; color: #4a8c6a;
            stroke-dasharray: 50; stroke-dashoffset: 50;
            animation: drawCheck 0.5s 0.6s ease forwards;
        }
        @keyframes drawCheck { to { stroke-dashoffset: 0; } }

        .success-badge {
            display: inline-block;
            background: rgba(74,140,106,0.1);
            border: 1px solid rgba(74,140,106,0.3);
            color: #5ebd8a;
            font-size: 0.62rem; letter-spacing: 0.3em;
            text-transform: uppercase;
            padding: 0.3rem 1rem; border-radius: 2px;
            margin-bottom: 1.2rem;
        }
        .success-title {
            font-family: var(--font-display);
            font-size: clamp(1.8rem, 4vw, 2.6rem);
            font-weight: 300; margin-bottom: 0.5rem;
        }
        .success-title em { font-style:italic; color: var(--gold-light); }
        .success-subtitle {
            font-size: 0.88rem; color: var(--text-secondary);
            margin-bottom: 1.2rem; line-height: 1.8;
        }
        .booking-ref-badge {
            display: inline-flex; align-items: center; gap: 0.8rem;
            background: var(--gold-glow); border: 1px solid var(--border-light);
            border-radius: var(--radius-sm); padding: 0.7rem 1.5rem;
        }
        .booking-ref-badge__label { font-size: 0.65rem; letter-spacing: 0.2em; text-transform: uppercase; color: var(--text-muted); }
        .booking-ref-badge__value { font-family: var(--font-display); font-size: 1.3rem; color: var(--gold-light); }

        /* Body */
        .success-body { padding: 2rem 3rem; }
        .success-grid {
            display: grid; grid-template-columns: 1fr 1fr;
            gap: 1px; background: var(--border);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            overflow: hidden; margin-bottom: 1.8rem;
        }
        .success-cell {
            background: var(--charcoal);
            padding: 1.1rem 1.4rem;
            transition: var(--transition);
        }
        .success-cell:hover { background: var(--surface-2); }
        .success-cell__label {
            font-size: 0.6rem; letter-spacing: 0.22em;
            text-transform: uppercase; color: var(--text-muted);
            margin-bottom: 0.3rem;
        }
        .success-cell__value { font-size: 0.92rem; color: var(--text-primary); font-weight: 400; }
        .success-cell--wide  { grid-column: 1 / -1; }
        .success-cell--green .success-cell__value { color: #4a8c6a; font-family: var(--font-display); font-size: 1.1rem; }
        .success-cell--gold  .success-cell__value { color: var(--gold-light); font-family: var(--font-display); font-size: 1.3rem; }

        /* Next steps */
        .next-steps {
            background: var(--charcoal); border: 1px solid var(--border);
            border-radius: var(--radius-sm); padding: 1.4rem;
            margin-bottom: 1.8rem;
        }
        .next-steps__title {
            font-size: 0.62rem; letter-spacing: 0.28em; text-transform: uppercase;
            color: var(--gold); margin-bottom: 1rem;
        }
        .next-step-item {
            display: flex; align-items: flex-start; gap: 0.9rem;
            font-size: 0.86rem; color: var(--text-secondary);
            margin-bottom: 0.75rem; line-height: 1.6;
        }
        .next-step-item:last-child { margin-bottom: 0; }
        .next-step-num {
            width: 22px; height: 22px; border-radius: 50%;
            border: 1px solid var(--gold-muted); color: var(--gold);
            font-size: 0.65rem; font-weight: 600;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0; margin-top: 1px;
        }

        /* Actions */
        .success-actions {
            display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem;
        }

        @media (max-width:580px) {
            .success-header, .success-body { padding: 2rem 1.5rem; }
            .success-grid { grid-template-columns: 1fr; }
            .success-cell--wide { grid-column: 1; }
            .success-actions { grid-template-columns: 1fr; }
        }

        @media print {
            .navbar, .success-actions, .next-steps { display:none !important; }
            .success-page { padding-top: 1rem; }
        }
    </style>
</head>
<body>

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
                <li><a href="user-dashboard.jsp">My Bookings</a></li>
                <li><a href="contact.jsp">Contact</a></li>
            </ul>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="success-page">
    <div class="success-card">

        <!-- Header -->
        <div class="success-header">
            <div class="success-icon-wrap">
                <svg fill="none" stroke="currentColor" stroke-width="2.5"
                     stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                    <polyline points="20 6 9 17 4 12"/>
                </svg>
            </div>
            <span class="success-badge">Payment Confirmed</span>
            <h1 class="success-title">Booking <em>Confirmed!</em></h1>
            <p class="success-subtitle">
                Your payment was successful. A confirmation has been sent to<br>
                <strong style="color:var(--text-primary);"><%=guestEmail%></strong>
            </p>
            <div class="booking-ref-badge">
                <span class="booking-ref-badge__label">Booking Reference</span>
                <span class="booking-ref-badge__value">#<%=bookingRef%></span>
                <button onclick="copyRef('<%=bookingRef%>')" id="copyBtn"
                        style="background:none;border:none;cursor:pointer;color:var(--text-muted);padding:2px;"
                        title="Copy reference">
                    <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <rect x="9" y="9" width="13" height="13" rx="2"/>
                        <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>
                    </svg>
                </button>
            </div>
        </div>

        <!-- Body -->
        <div class="success-body">

            <div class="success-grid">
                <div class="success-cell">
                    <p class="success-cell__label">Guest</p>
                    <p class="success-cell__value"><%=guestName%></p>
                </div>
                <div class="success-cell">
                    <p class="success-cell__label">Room</p>
                    <p class="success-cell__value"><%=roomType%></p>
                </div>
                <div class="success-cell">
                    <p class="success-cell__label">Check-In</p>
                    <p class="success-cell__value"><%=checkinFmt%></p>
                </div>
                <div class="success-cell">
                    <p class="success-cell__label">Check-Out</p>
                    <p class="success-cell__value"><%=checkoutFmt%></p>
                </div>
                <div class="success-cell">
                    <p class="success-cell__label">Duration</p>
                    <p class="success-cell__value"><%=nights%> <%=nights==1?"Night":"Nights"%></p>
                </div>
                <div class="success-cell success-cell--green">
                    <p class="success-cell__label">Payment Status</p>
                    <p class="success-cell__value">✓ Paid</p>
                </div>
                <div class="success-cell">
                    <p class="success-cell__label">Payment ID</p>
                    <p class="success-cell__value" style="font-size:0.78rem;word-break:break-all;"><%=paymentId%></p>
                </div>
                <div class="success-cell success-cell--gold">
                    <p class="success-cell__label">Amount Paid</p>
                    <p class="success-cell__value">₹<%=amountFormatted%></p>
                </div>
            </div>

            <!-- What happens next -->
            <div class="next-steps">
                <p class="next-steps__title">✦ &nbsp; What happens next</p>
                <div class="next-step-item">
                    <span class="next-step-num">1</span>
                    <span>A booking confirmation email with your receipt has been sent to <strong style="color:var(--text-primary);"><%=guestEmail%></strong>.</span>
                </div>
                <div class="next-step-item">
                    <span class="next-step-num">2</span>
                    <span>Present your booking reference <strong style="color:var(--gold);">#<%=bookingRef%></strong> at the front desk upon arrival. Check-in is from 2:00 PM.</span>
                </div>
                <div class="next-step-item">
                    <span class="next-step-num">3</span>
                    <span>For early check-in, late check-out, or special requests, call our concierge at <a href="tel:+919321132636" style="color:var(--gold);">+91 93211 32636</a>.</span>
                </div>
                <div class="next-step-item">
                    <span class="next-step-num">4</span>
                    <span>Free cancellation is available up to 48 hours before your check-in date from your dashboard.</span>
                </div>
            </div>

            <!-- Actions -->
            <div class="success-actions">
                <a href="user-dashboard.jsp" class="btn btn--primary">View My Bookings</a>
                <button onclick="window.print()" class="btn btn--outline">Print Receipt</button>
                <a href="rooms.jsp" class="btn btn--ghost">Browse More Rooms</a>
                <a href="contact.jsp" class="btn btn--ghost">Need Help?</a>
            </div>

        </div>
    </div>
</div>

<script>
    function copyRef(ref) {
        navigator.clipboard.writeText(ref).then(() => {
            document.getElementById('copyBtn').innerHTML =
                '<svg width="13" height="13" fill="none" stroke="#4a8c6a" stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>';
            setTimeout(() => {
                document.getElementById('copyBtn').innerHTML =
                    '<svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
            }, 2500);
        });
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
