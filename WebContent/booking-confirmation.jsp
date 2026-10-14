<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal, java.text.NumberFormat, java.util.Locale" %>
<%
    /* ── Pull attributes set by BookingServlet ── */
    String   bookingRef  = (String)     request.getAttribute("bookingRef");
    String   roomNumber  = (String)     request.getAttribute("roomNumber");
    String   roomType    = (String)     request.getAttribute("roomType");
    String   checkin     = (String)     request.getAttribute("checkin");
    String   checkout    = (String)     request.getAttribute("checkout");
    Object   nightsObj   = request.getAttribute("nights");
    BigDecimal total     = (BigDecimal) request.getAttribute("totalAmount");
    String   guestName   = (String)     request.getAttribute("guestName");
    String   guestEmail  = (String)     request.getAttribute("guestEmail");
    String   paymentId   = (String)     request.getAttribute("paymentId");

    if (bookingRef == null || !bookingRef.matches("GH-[A-Z0-9]{4,18}")
            || paymentId == null || paymentId.trim().isEmpty()
            || roomNumber == null || roomType == null || checkin == null || checkout == null
            || nightsObj == null || total == null || guestName == null || guestEmail == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp");
        return;
    }

    /* ── Fallbacks so the page renders even in direct preview ── */

    long nights = (nightsObj instanceof Long) ? (Long) nightsObj : Long.parseLong(nightsObj.toString());

    NumberFormat inrFmt = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
    String totalFmt = inrFmt.format(total);

    /* ── Pretty-format dates  e.g. "10 April 2025" ── */
    java.time.LocalDate ciDate  = java.time.LocalDate.parse(checkin);
    java.time.LocalDate coDate  = java.time.LocalDate.parse(checkout);
    java.time.format.DateTimeFormatter dtf =
            java.time.format.DateTimeFormatter.ofPattern("dd MMMM yyyy");
    String checkinFmt  = ciDate.format(dtf);
    String checkoutFmt = coDate.format(dtf);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmed — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Page-specific overrides ── */
        .confirm-page {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 6rem 1.5rem 4rem;
            position: relative;
            overflow: hidden;
        }
        .confirm-page::before {
            content: '';
            position: absolute;
            inset: 0;
            background:
                    radial-gradient(ellipse 55% 45% at 50% 30%, rgba(200,170,100,0.07) 0%, transparent 65%),
                    radial-gradient(ellipse 30% 50% at 80% 80%, rgba(74,140,106,0.04) 0%, transparent 50%);
            pointer-events: none;
        }

        /* ── Animated check icon ── */
        .confirm-icon-wrap {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 1px solid rgba(74,140,106,0.35);
            background: rgba(74,140,106,0.08);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 2rem;
            animation: iconPop 0.6s cubic-bezier(0.34,1.56,0.64,1) both;
        }
        @keyframes iconPop {
            from { opacity:0; transform: scale(0.4); }
            to   { opacity:1; transform: scale(1); }
        }
        .confirm-icon-wrap svg {
            width: 36px;
            height: 36px;
            color: #4a8c6a;
            stroke-dasharray: 50;
            stroke-dashoffset: 50;
            animation: drawCheck 0.5s 0.4s ease forwards;
        }
        @keyframes drawCheck {
            to { stroke-dashoffset: 0; }
        }

        /* ── Card ── */
        .confirm-card {
            position: relative;
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            max-width: 680px;
            width: 100%;
            overflow: hidden;
            box-shadow: var(--shadow-deep), var(--shadow-gold);
            animation: cardRise 0.7s 0.1s cubic-bezier(0.4,0,0.2,1) both;
        }
        @keyframes cardRise {
            from { opacity:0; transform:translateY(32px); }
            to   { opacity:1; transform:translateY(0); }
        }
        .confirm-card::before {
            content: '';
            position: absolute;
            top: 0; left: 15%; right: 15%;
            height: 1px;
            background: linear-gradient(90deg, transparent, var(--gold), transparent);
        }

        .confirm-header {
            padding: 3rem 3rem 2rem;
            text-align: center;
            border-bottom: 1px solid var(--border);
        }
        .confirm-eyebrow {
            display: inline-block;
            font-size: 0.6rem;
            letter-spacing: 0.4em;
            text-transform: uppercase;
            color: #4a8c6a;
            border: 1px solid rgba(74,140,106,0.3);
            padding: 0.3rem 1rem;
            border-radius: 2px;
            margin-bottom: 1.5rem;
        }
        .confirm-title {
            font-family: var(--font-display);
            font-size: clamp(1.8rem, 4vw, 2.6rem);
            font-weight: 300;
            color: var(--text-primary);
            line-height: 1.2;
            margin-bottom: 0.6rem;
        }
        .confirm-title em { font-style:italic; color: var(--gold-light); }
        .confirm-subtitle {
            font-size: 0.9rem;
            color: var(--text-secondary);
            margin-bottom: 1.5rem;
        }
        .booking-ref-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.8rem;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            padding: 0.7rem 1.5rem;
            font-size: 0.75rem;
        }
        .booking-ref-badge__label {
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
        }
        .booking-ref-badge__value {
            font-family: var(--font-display);
            font-size: 1.3rem;
            color: var(--gold-light);
            letter-spacing: 0.1em;
        }

        /* ── Detail grid ── */
        .confirm-body { padding: 2.5rem 3rem; }
        .confirm-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1px;
            background: var(--border);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            overflow: hidden;
            margin-bottom: 2rem;
        }
        .confirm-cell {
            background: var(--charcoal);
            padding: 1.2rem 1.5rem;
            transition: var(--transition);
        }
        .confirm-cell:hover { background: var(--surface-2); }
        .confirm-cell__label {
            font-size: 0.62rem;
            letter-spacing: 0.25em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 0.35rem;
        }
        .confirm-cell__value {
            font-size: 0.97rem;
            color: var(--text-primary);
            font-weight: 400;
        }
        .confirm-cell--gold .confirm-cell__value {
            font-family: var(--font-display);
            font-size: 1.3rem;
            color: var(--gold-light);
        }
        .confirm-cell--wide {
            grid-column: 1 / -1;
        }

        /* ── What's next strip ── */
        .whats-next {
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 1.5rem;
            margin-bottom: 2rem;
        }
        .whats-next__title {
            font-size: 0.65rem;
            letter-spacing: 0.3em;
            text-transform: uppercase;
            color: var(--gold);
            margin-bottom: 1.2rem;
        }
        .whats-next__steps {
            display: flex;
            flex-direction: column;
            gap: 0.9rem;
        }
        .whats-next__step {
            display: flex;
            align-items: flex-start;
            gap: 1rem;
            font-size: 0.87rem;
            color: var(--text-secondary);
            line-height: 1.6;
        }
        .whats-next__num {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            border: 1px solid var(--gold-muted);
            color: var(--gold);
            font-size: 0.65rem;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            margin-top: 1px;
        }

        /* ── Action buttons ── */
        .confirm-actions {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.9rem;
        }

        /* ── Print styles ── */
        @media print {
            .navbar, .confirm-actions, .whats-next { display: none !important; }
            .confirm-card { box-shadow: none; border: 1px solid #ccc; }
            body { background: white; color: black; }
            .confirm-cell { background: #f9f9f9 !important; }
        }

        @media (max-width: 600px) {
            .confirm-header, .confirm-body { padding: 2rem 1.5rem; }
            .confirm-grid { grid-template-columns: 1fr; }
            .confirm-actions { grid-template-columns: 1fr; }
            .confirm-cell--wide { grid-column: 1; }
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
                <li><a href="user-dashboard.jsp">My Bookings</a></li>
            </ul>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<!-- ── Confirmation ─────────────────────────────────────────── -->
<div class="confirm-page">
    <div class="confirm-card">

        <!-- Header -->
        <div class="confirm-header">
            <div class="confirm-icon-wrap">
                <svg fill="none" stroke="currentColor" stroke-width="2.5"
                     stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                    <polyline points="20 6 9 17 4 12"/>
                </svg>
            </div>
            <span class="confirm-eyebrow">Reservation Confirmed</span>
            <h1 class="confirm-title">Your Stay is <em>Booked</em></h1>
            <p class="confirm-subtitle">
                A confirmation has been sent to <strong style="color:var(--text-primary);"><%=guestEmail%></strong>.
                We look forward to welcoming you.
            </p>
            <div class="booking-ref-badge">
                <span class="booking-ref-badge__label">Booking Reference</span>
                <span class="booking-ref-badge__value">#<%=bookingRef%></span>
                <button onclick="copyRef('<%=bookingRef%>')" title="Copy reference"
                        style="background:none;border:none;cursor:pointer;color:var(--text-muted);padding:2px;"
                        id="copyBtn">
                    <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>
                    </svg>
                </button>
            </div>
        </div>

        <!-- Body -->
        <div class="confirm-body">

            <!-- Details grid -->
            <div class="confirm-grid">

                <div class="confirm-cell">
                    <p class="confirm-cell__label">Guest Name</p>
                    <p class="confirm-cell__value"><%=guestName%></p>
                </div>

                <div class="confirm-cell">
                    <p class="confirm-cell__label">Room</p>
                    <p class="confirm-cell__value"><%=roomType%> &nbsp;·&nbsp; No. <%=roomNumber%></p>
                </div>

                <div class="confirm-cell">
                    <p class="confirm-cell__label">Check-In</p>
                    <p class="confirm-cell__value"><%=checkinFmt%></p>
                </div>

                <div class="confirm-cell">
                    <p class="confirm-cell__label">Check-Out</p>
                    <p class="confirm-cell__value"><%=checkoutFmt%></p>
                </div>

                <div class="confirm-cell">
                    <p class="confirm-cell__label">Duration</p>
                    <p class="confirm-cell__value"><%=nights%> <%=nights==1?"Night":"Nights"%></p>
                </div>

                <div class="confirm-cell confirm-cell--gold">
                    <p class="confirm-cell__label">Total Charged</p>
                    <p class="confirm-cell__value"><%=totalFmt%></p>
                </div>

                <div class="confirm-cell confirm-cell--wide">
                    <p class="confirm-cell__label">Status</p>
                    <p class="confirm-cell__value">
            <span class="status status--pending"
                  style="font-size:0.75rem;">Pending Confirmation</span>
                        &nbsp;
                        <span style="font-size:0.8rem;color:var(--text-muted);">
              Our team will confirm within 2 hours.
            </span>
                    </p>
                </div>

            </div><!-- /confirm-grid -->

            <!-- What happens next -->
            <div class="whats-next">
                <p class="whats-next__title">✦ &nbsp; What happens next</p>
                <div class="whats-next__steps">
                    <div class="whats-next__step">
                        <span class="whats-next__num">1</span>
                        <span>Complete payment to confirm your booking. We will email the receipt to <strong style="color:var(--text-primary);"><%=guestEmail%></strong>.</span>
                    </div>
                    <div class="whats-next__step">
                        <span class="whats-next__num">2</span>
                        <span>Your reservation is held as pending until payment is verified.</span>
                    </div>
                    <div class="whats-next__step">
                        <span class="whats-next__num">3</span>
                        <span>Present your booking reference <strong style="color:var(--gold);">#<%=bookingRef%></strong> at reception on arrival. Check-in is from 2:00 PM.</span>
                    </div>
                    <div class="whats-next__step">
                        <span class="whats-next__num">4</span>
                        <span>Free cancellation is available up to 48 hours before your check-in date.</span>
                    </div>
                </div>
            </div>

            <!-- Actions -->
            <div class="confirm-actions">
                <a href="<%=request.getContextPath()%>/payment.jsp" class="btn btn--primary">Pay securely now</a>
                <a href="user-dashboard.jsp" class="btn btn--primary">View My Bookings</a>
                <button onclick="window.print()" class="btn btn--outline">Print / Save PDF</button>
                <a href="rooms.jsp" class="btn btn--ghost">Browse More Rooms</a>
                <a href="contact.jsp" class="btn btn--ghost">Need Help?</a>
            </div>

        </div><!-- /confirm-body -->
    </div><!-- /confirm-card -->
</div><!-- /confirm-page -->

<script>
    function copyRef(ref) {
        navigator.clipboard.writeText(ref).then(() => {
            const btn = document.getElementById('copyBtn');
            btn.innerHTML = '<svg width="14" height="14" fill="none" stroke="#4a8c6a" stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>';
            setTimeout(() => {
                btn.innerHTML = '<svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
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
