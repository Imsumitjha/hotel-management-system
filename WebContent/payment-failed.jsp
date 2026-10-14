<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String bookingRef   = (String) request.getAttribute("bookingRef");
    String errorCode    = (String) request.getAttribute("errorCode");
    String errorDesc    = (String) request.getAttribute("errorDesc");
    String guestEmail   = (String) request.getAttribute("guestEmail");
    String totalFmt     = (String) request.getAttribute("amountFormatted");

    if (bookingRef == null) bookingRef = "GH-????";
    if (errorDesc  == null) errorDesc  = "Payment was not completed.";
    if (totalFmt   == null) totalFmt   = "—";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Failed — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .failed-page {
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            padding: 6rem 1.5rem 4rem;
            position: relative; overflow: hidden;
        }
        .failed-page::before {
            content: '';
            position: absolute; inset: 0;
            background: radial-gradient(ellipse 50% 40% at 50% 30%,
            rgba(192,81,58,0.05) 0%, transparent 60%);
            pointer-events: none;
        }
        .failed-card {
            position: relative;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            max-width: 560px; width: 100%;
            overflow: hidden;
            box-shadow: var(--shadow-deep);
            animation: cardRise 0.6s cubic-bezier(0.4,0,0.2,1) both;
        }
        @keyframes cardRise {
            from { opacity:0; transform:translateY(24px); }
            to   { opacity:1; transform:translateY(0); }
        }
        .failed-card::before {
            content: '';
            position: absolute; top:0; left:15%; right:15%; height:2px;
            background: linear-gradient(90deg,transparent,var(--error),transparent);
        }
        .failed-header {
            padding: 3rem 3rem 2rem;
            text-align: center;
            border-bottom: 1px solid var(--border);
        }
        .failed-icon {
            width: 76px; height: 76px; border-radius: 50%;
            background: rgba(192,81,58,0.08);
            border: 1px solid rgba(192,81,58,0.3);
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 1.5rem; color: var(--error);
            animation: popIn 0.5s cubic-bezier(0.34,1.56,0.64,1) both;
        }
        @keyframes popIn {
            from { opacity:0; transform:scale(0.4); }
            to   { opacity:1; transform:scale(1); }
        }
        .failed-badge {
            display: inline-block;
            background: rgba(192,81,58,0.1);
            border: 1px solid rgba(192,81,58,0.28);
            color: #d9705a;
            font-size: 0.62rem; letter-spacing: 0.3em;
            text-transform: uppercase; padding: 0.3rem 1rem;
            border-radius: 2px; margin-bottom: 1.2rem;
        }
        .failed-title {
            font-family: var(--font-display);
            font-size: clamp(1.8rem, 4vw, 2.4rem);
            font-weight: 300; margin-bottom: 0.5rem;
        }
        .failed-subtitle { font-size: 0.88rem; color: var(--text-secondary); line-height: 1.8; }

        .failed-body { padding: 2rem 3rem; }

        .error-reason-box {
            background: rgba(192,81,58,0.07);
            border: 1px solid rgba(192,81,58,0.2);
            border-left: 3px solid var(--error);
            border-radius: var(--radius-sm);
            padding: 1.1rem 1.4rem;
            margin-bottom: 1.8rem;
        }
        .error-reason-box__label {
            font-size: 0.6rem; letter-spacing: 0.2em;
            text-transform: uppercase; color: #d9705a;
            margin-bottom: 0.3rem;
        }
        .error-reason-box__text { font-size: 0.9rem; color: var(--text-secondary); }

        .summary-row { display:flex; justify-content:space-between; padding:0.6rem 0; font-size:0.88rem; border-bottom:1px solid rgba(255,255,255,0.04); }
        .summary-row:last-child { border-bottom:none; }
        .summary-row__label { color:var(--text-secondary); }
        .summary-row__value { color:var(--text-primary); }

        .failed-tips {
            background: var(--charcoal); border: 1px solid var(--border);
            border-radius: var(--radius-sm); padding: 1.2rem 1.5rem;
            margin: 1.5rem 0;
        }
        .failed-tips__title { font-size: 0.62rem; letter-spacing: 0.25em; text-transform: uppercase; color: var(--gold); margin-bottom: 0.8rem; }
        .failed-tips ul { display:flex; flex-direction:column; gap:0.45rem; }
        .failed-tips li { display:flex; align-items:flex-start; gap:0.6rem; font-size:0.84rem; color:var(--text-secondary); line-height:1.6; }
        .failed-tips li::before { content:''; width:5px; height:5px; border-radius:50%; background:var(--gold-muted); flex-shrink:0; margin-top:0.5em; }

        .failed-actions { display:grid; grid-template-columns:1fr 1fr; gap:0.8rem; }

        @media (max-width:560px) {
            .failed-header, .failed-body { padding:2rem 1.5rem; }
            .failed-actions { grid-template-columns:1fr; }
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
                <li><a href="booking.jsp">Book</a></li>
                <li><a href="contact.jsp">Contact</a></li>
            </ul>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="failed-page">
    <div class="failed-card">

        <div class="failed-header">
            <div class="failed-icon">
                <svg width="32" height="32" fill="none" stroke="currentColor"
                     stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="15" y1="9" x2="9" y2="15"/>
                    <line x1="9" y1="9" x2="15" y2="15"/>
                </svg>
            </div>
            <span class="failed-badge">Payment Failed</span>
            <h1 class="failed-title">Payment Unsuccessful</h1>
            <p class="failed-subtitle">
                Your booking is still reserved. No amount has been charged.<br>
                Please try again or use a different payment method.
            </p>
        </div>

        <div class="failed-body">

            <!-- Error reason -->
            <div class="error-reason-box">
                <p class="error-reason-box__label">Reason</p>
                <p class="error-reason-box__text"><%=errorDesc%></p>
                <% if (errorCode != null && !errorCode.isEmpty()) { %>
                <p style="font-size:0.72rem;color:var(--text-muted);margin-top:4px;">Code: <%=errorCode%></p>
                <% } %>
            </div>

            <!-- Booking details preserved -->
            <div style="margin-bottom:1.2rem;">
                <div class="summary-row">
                    <span class="summary-row__label">Booking Reference</span>
                    <span class="summary-row__value" style="color:var(--gold);">#<%=bookingRef%></span>
                </div>
                <div class="summary-row">
                    <span class="summary-row__label">Amount</span>
                    <span class="summary-row__value">₹<%=totalFmt%></span>
                </div>
                <div class="summary-row">
                    <span class="summary-row__label">Booking Status</span>
                    <span class="summary-row__value">
            <span class="status status--pending">Pending</span>
          </span>
                </div>
            </div>

            <!-- Tips -->
            <div class="failed-tips">
                <p class="failed-tips__title">Common reasons &amp; fixes</p>
                <ul>
                    <li>Insufficient balance — check your card or wallet balance and try again.</li>
                    <li>Card declined — try a different card or payment method (UPI / Net Banking).</li>
                    <li>OTP timeout — restart the payment process and enter OTP within 60 seconds.</li>
                    <li>Bank server error — wait a few minutes and retry.</li>
                    <li>Daily limit exceeded — use a different card or contact your bank.</li>
                </ul>
            </div>

            <!-- Actions -->
            <div class="failed-actions">
                <a href="payment.jsp" class="btn btn--primary">Try Again</a>
                <a href="booking.jsp" class="btn btn--outline">Change Booking</a>
                <a href="contact.jsp" class="btn btn--ghost">Contact Support</a>
                <a href="user-dashboard.jsp" class="btn btn--ghost">My Bookings</a>
            </div>

            <p style="text-align:center;margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">
                Need help? Call
                <a href="tel:+919321132636" style="color:var(--gold);">+91 93211 32636</a>
                or email
                <a href="mailto:stay@grandhorizon.in" style="color:var(--gold);">stay@grandhorizon.in</a>
            </p>

        </div>
    </div>
</div>
<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
    &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
    <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
