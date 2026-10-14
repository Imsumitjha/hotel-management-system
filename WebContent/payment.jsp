<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal" %>
<%
    /* ─────────────────────────────────────────────────────────────────
       Attributes set by BookingServlet after inserting the booking row.
       If accessed directly (missing attrs) we redirect to booking.jsp.
    ───────────────────────────────────────────────────────────────── */
    String     bookingRef  = (String)     session.getAttribute("pendingBookingRef");
    String     roomType    = (String)     session.getAttribute("pendingRoomType");
    String     roomNumber  = (String)     session.getAttribute("pendingRoomNumber");
    String     checkin     = (String)     session.getAttribute("pendingCheckin");
    String     checkout    = (String)     session.getAttribute("pendingCheckout");
    Object     nightsObj   = session.getAttribute("pendingNights");
    BigDecimal totalAmount = (BigDecimal) session.getAttribute("pendingTotal");
    String     guestName   = (String)     session.getAttribute("pendingGuestName");
    String     guestEmail  = (String)     session.getAttribute("pendingGuestEmail");
    String     guestPhone  = (String)     session.getAttribute("pendingGuestPhone");
    Integer    bookingId   = (Integer)    session.getAttribute("pendingBookingId");
    String paymentCsrfToken = (String) session.getAttribute("csrfToken");
    if (paymentCsrfToken == null) {
        paymentCsrfToken = java.util.UUID.randomUUID().toString();
        session.setAttribute("csrfToken", paymentCsrfToken);
    }

    if (bookingRef == null || totalAmount == null) {
        response.sendRedirect(request.getContextPath() + "/booking.jsp");
        return;
    }

    long nights = (nightsObj instanceof Long) ? (Long) nightsObj : Long.parseLong(nightsObj.toString());

    /* Pretty-format dates */
    java.time.LocalDate ciDate = java.time.LocalDate.parse(checkin);
    java.time.LocalDate coDate = java.time.LocalDate.parse(checkout);
    java.time.format.DateTimeFormatter dtf =
            java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy");
    String checkinFmt  = ciDate.format(dtf);
    String checkoutFmt = coDate.format(dtf);

    /* Tax breakdown (already included in totalAmount) */
    BigDecimal subtotal = totalAmount.divide(new BigDecimal("1.12"), 2, java.math.RoundingMode.HALF_UP);
    BigDecimal tax      = totalAmount.subtract(subtotal);

    /* The public key ID is safe to expose to Checkout; never expose the secret. */
    String configuredKeyId = System.getenv("RAZORPAY_KEY_ID");
    boolean razorpayConfigured = configuredKeyId != null
            && configuredKeyId.matches("rzp_(test|live)_[A-Za-z0-9]+");
    String razorpayKeyId = razorpayConfigured ? configuredKeyId : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Payment — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <!-- Razorpay Checkout SDK -->
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
    <style>
        .payment-page {
            min-height: 100vh;
            padding: 7rem 0 5rem;
            background: var(--obsidian);
        }
        .payment-layout {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 2.5rem;
            align-items: start;
        }

        /* ── Order summary card ─────────────────────────────── */
        .order-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            overflow: hidden;
        }
        .order-card__header {
            background: var(--charcoal);
            border-bottom: 1px solid var(--border);
            padding: 1.4rem 2rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .order-card__title {
            font-family: var(--font-display);
            font-size: 1.3rem;
            font-weight: 400;
        }
        .order-ref {
            font-size: 0.75rem;
            color: var(--gold);
            letter-spacing: 0.1em;
        }
        .order-card__body { padding: 2rem; }

        .order-room-block {
            display: flex;
            align-items: center;
            gap: 1.2rem;
            padding: 1.2rem;
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            margin-bottom: 1.8rem;
        }
        .order-room-icon {
            width: 44px; height: 44px;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            display: flex; align-items: center; justify-content: center;
            color: var(--gold);
            flex-shrink: 0;
        }
        .order-room-type {
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 400;
            color: var(--text-primary);
        }
        .order-room-sub { font-size: 0.78rem; color: var(--text-muted); margin-top: 2px; }

        .order-dates {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 1rem;
            margin-bottom: 1.8rem;
        }
        .order-date-cell {
            text-align: center;
            padding: 1rem;
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
        }
        .order-date-cell__label {
            font-size: 0.6rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 0.4rem;
        }
        .order-date-cell__value {
            font-size: 0.9rem;
            color: var(--text-primary);
            font-weight: 400;
        }
        .order-date-cell__nights {
            font-family: var(--font-display);
            font-size: 1.6rem;
            color: var(--gold-light);
            line-height: 1;
        }

        .order-line {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0.65rem 0;
            font-size: 0.88rem;
            border-bottom: 1px solid rgba(255,255,255,0.04);
        }
        .order-line:last-child { border-bottom: none; }
        .order-line__key   { color: var(--text-secondary); }
        .order-line__value { color: var(--text-primary); font-weight: 400; }
        .order-total {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1rem 0 0;
            margin-top: 0.5rem;
            border-top: 1px solid var(--border-light);
        }
        .order-total__key {
            font-size: 0.82rem;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--text-primary);
        }
        .order-total__value {
            font-family: var(--font-display);
            font-size: 1.8rem;
            color: var(--gold-light);
        }

        .guest-block {
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 1.2rem;
            margin-top: 1.5rem;
        }
        .guest-block__label {
            font-size: 0.6rem; letter-spacing: 0.25em; text-transform: uppercase;
            color: var(--text-muted); margin-bottom: 0.7rem;
        }
        .guest-block__name  { font-size: 0.95rem; color: var(--text-primary); font-weight: 400; }
        .guest-block__email { font-size: 0.82rem; color: var(--text-muted); margin-top: 2px; }

        /* ── Payment card ─────────────────────────────────── */
        .payment-card {
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            overflow: hidden;
            position: sticky;
            top: 7rem;
            box-shadow: 0 0 40px rgba(200,170,100,0.08);
        }
        .payment-card__header {
            background: var(--charcoal);
            padding: 1.4rem 1.8rem;
            border-bottom: 1px solid var(--border);
        }
        .payment-card__title {
            font-family: var(--font-display);
            font-size: 1.3rem;
            font-weight: 400;
            margin-bottom: 0.3rem;
        }
        .payment-card__subtitle { font-size: 0.78rem; color: var(--text-muted); }
        .payment-card__body { padding: 1.8rem; }

        /* Amount display */
        .pay-amount-display {
            text-align: center;
            padding: 1.5rem;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            margin-bottom: 1.5rem;
        }
        .pay-amount-label { font-size: 0.65rem; letter-spacing: 0.25em; text-transform: uppercase; color: var(--text-muted); margin-bottom: 0.4rem; }
        .pay-amount-value { font-family: var(--font-display); font-size: 2.4rem; font-weight: 300; color: var(--gold-light); }

        /* Pay button */
        .pay-btn {
            width: 100%;
            padding: 1.1rem;
            background: var(--gold);
            color: var(--obsidian);
            border: none;
            border-radius: var(--radius-sm);
            font-family: var(--font-body);
            font-size: 0.82rem;
            font-weight: 600;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            cursor: pointer;
            transition: var(--transition);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.6rem;
            margin-bottom: 1rem;
        }
        .pay-btn:hover { background: var(--gold-light); transform: translateY(-2px); box-shadow: 0 8px 24px rgba(200,170,100,0.3); }
        .pay-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none !important; }
        .pay-btn__spinner {
            width: 16px; height: 16px;
            border: 2px solid rgba(10,10,15,0.3);
            border-top-color: var(--obsidian);
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
            display: none;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* Accepted payment methods */
        .pay-methods {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.6rem;
            margin-bottom: 1.2rem;
            flex-wrap: wrap;
        }
        .pay-method-badge {
            font-size: 0.62rem;
            letter-spacing: 0.08em;
            color: var(--text-muted);
            border: 1px solid var(--border);
            padding: 0.2rem 0.6rem;
            border-radius: 2px;
        }

        /* Security note */
        .pay-security {
            display: flex;
            align-items: flex-start;
            gap: 0.6rem;
            font-size: 0.75rem;
            color: var(--text-muted);
            line-height: 1.6;
        }
        .pay-security svg { flex-shrink: 0; margin-top: 1px; color: var(--success); }

        /* Razorpay branding */
        .rzp-brand {
            text-align: center;
            margin-top: 1.2rem;
            padding-top: 1.2rem;
            border-top: 1px solid var(--border);
            font-size: 0.72rem;
            color: var(--text-muted);
        }
        .rzp-brand a { color: #3395FF; text-decoration: none; }

        @media (max-width: 900px) {
            .payment-layout { grid-template-columns: 1fr; }
            .payment-card { position: static; }
        }
        @media (max-width: 580px) {
            .order-dates { grid-template-columns: 1fr; }
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
                <li><a href="booking.jsp" class="active">Book</a></li>
                <li><a href="contact.jsp">Contact</a></li>
            </ul>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="payment-page">
    <div class="container">

        <!-- Breadcrumb -->
        <div style="margin-bottom:2rem;display:flex;align-items:center;gap:0.5rem;font-size:0.78rem;color:var(--text-muted);">
            <a href="booking.jsp" style="color:var(--text-muted);">Booking</a>
            <span>›</span>
            <span style="color:var(--gold);">Secure Payment</span>
        </div>

        <div class="payment-layout">

            <!-- ── ORDER SUMMARY ──────────────────────────────────── -->
            <div>
                <div class="order-card">
                    <div class="order-card__header">
                        <h2 class="order-card__title">Order Summary</h2>
                        <span class="order-ref">#<%= bookingRef %></span>
                    </div>
                    <div class="order-card__body">

                        <!-- Room -->
                        <div class="order-room-block">
                            <div class="order-room-icon">
                                <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24">
                                    <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                                    <polyline points="9 22 9 12 15 12 15 22"/>
                                </svg>
                            </div>
                            <div>
                                <p class="order-room-type"><%= roomType %></p>
                                <p class="order-room-sub">Room No. <%= roomNumber %> &nbsp;·&nbsp; Grand Horizon, Amritsar</p>
                            </div>
                        </div>

                        <!-- Dates -->
                        <div class="order-dates">
                            <div class="order-date-cell">
                                <p class="order-date-cell__label">Check-In</p>
                                <p class="order-date-cell__value"><%= checkinFmt %></p>
                            </div>
                            <div class="order-date-cell">
                                <p class="order-date-cell__label">Nights</p>
                                <p class="order-date-cell__nights"><%= nights %></p>
                            </div>
                            <div class="order-date-cell">
                                <p class="order-date-cell__label">Check-Out</p>
                                <p class="order-date-cell__value"><%= checkoutFmt %></p>
                            </div>
                        </div>

                        <!-- Pricing breakdown -->
                        <div class="order-line">
                            <span class="order-line__key">Room rate</span>
                            <span class="order-line__value">₹<%= String.format("%,.2f", subtotal.doubleValue() / nights) %> × <%= nights %> nights</span>
                        </div>
                        <div class="order-line">
                            <span class="order-line__key">Subtotal</span>
                            <span class="order-line__value">₹<%= String.format("%,.2f", subtotal.doubleValue()) %></span>
                        </div>
                        <div class="order-line">
                            <span class="order-line__key">GST (18%)</span>
                            <span class="order-line__value">₹<%= String.format("%,.2f", tax.doubleValue()) %></span>
                        </div>
                        <div class="order-total">
                            <span class="order-total__key">Total Due</span>
                            <span class="order-total__value">₹<%= String.format("%,.2f", totalAmount.doubleValue()) %></span>
                        </div>

                        <!-- Guest -->
                        <div class="guest-block">
                            <p class="guest-block__label">Guest</p>
                            <p class="guest-block__name"><%= guestName %></p>
                            <p class="guest-block__email"><%= guestEmail %></p>
                        </div>

                    </div>
                </div>

                <!-- Cancellation note -->
                <div style="margin-top:1.2rem;padding:1rem 1.5rem;background:var(--gold-glow);border:1px solid var(--border-light);border-radius:var(--radius-sm);display:flex;align-items:center;gap:0.8rem;font-size:0.82rem;color:var(--text-secondary);">
                    <svg width="15" height="15" fill="none" stroke="var(--gold)" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    Free cancellation up to 48 hours before check-in. Full refund guaranteed.
                </div>
            </div>

            <!-- ── PAYMENT CARD ───────────────────────────────────── -->
            <div>
                <div class="payment-card">
                    <div class="payment-card__header">
                        <h3 class="payment-card__title">Secure Checkout</h3>
                        <p class="payment-card__subtitle">Powered by Razorpay · 256-bit SSL</p>
                    </div>
                    <div class="payment-card__body">

                        <div class="pay-amount-display">
                            <p class="pay-amount-label">Amount to Pay</p>
                            <p class="pay-amount-value">₹<%= String.format("%,.2f", totalAmount.doubleValue()) %></p>
                        </div>

                        <!-- Accepted methods -->
                        <div class="pay-methods">
                            <span class="pay-method-badge">💳 Cards</span>
                            <span class="pay-method-badge">📱 UPI</span>
                            <span class="pay-method-badge">🏦 Net Banking</span>
                            <span class="pay-method-badge">👛 Wallets</span>
                        </div>

                        <!-- Pay button — triggers Razorpay after fetching order_id -->
                        <% if (!razorpayConfigured) { %>
                        <p role="alert" style="color:var(--error);margin-bottom:1rem;">
                            Online payment is temporarily unavailable. Please contact the hotel.
                        </p>
                        <% } %>
                        <button class="pay-btn" id="payBtn" onclick="initiatePayment()"
                                <%= razorpayConfigured ? "" : "disabled" %>>
                            <div class="pay-btn__spinner" id="spinner"></div>
                            <svg id="lockIcon" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                                <rect x="3" y="11" width="18" height="11" rx="2"/>
                                <path d="M7 11V7a5 5 0 0110 0v4"/>
                            </svg>
                            Pay ₹<%= String.format("%,.2f", totalAmount.doubleValue()) %>
                        </button>

                        <!-- Security badges -->
                        <div class="pay-security">
                            <svg width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            </svg>
                            Your payment is encrypted and processed securely by Razorpay.
                            Grand Horizon never stores your card details.
                        </div>

                        <div class="rzp-brand">
                            Secured by <a href="https://razorpay.com" target="_blank">Razorpay</a>
                        </div>
                    </div>
                </div>

                <!-- Back link -->
                <div style="text-align:center;margin-top:1.2rem;">
                    <a href="booking.jsp"
                       style="font-size:0.8rem;color:var(--text-muted);">
                        ← Cancel and return to booking
                    </a>
                </div>
            </div>

        </div><!-- /payment-layout -->
    </div><!-- /container -->
</div><!-- /payment-page -->

<script>
    /* ── Razorpay checkout initiator ── */
    async function initiatePayment() {
        if (!<%= razorpayConfigured %>) return;
        const btn     = document.getElementById('payBtn');
        const spinner = document.getElementById('spinner');
        const lock    = document.getElementById('lockIcon');

        // Show loading state
        btn.disabled    = true;
        spinner.style.display = 'block';
        lock.style.display    = 'none';
        btn.childNodes[btn.childNodes.length - 1].textContent = 'Processing…';

        try {
            // Step 1: Ask our servlet to create a Razorpay order
            const res = await fetch('<%= request.getContextPath() %>/payment?action=createOrder', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'bookingRef=<%= java.net.URLEncoder.encode(bookingRef, "UTF-8") %>&_csrf=<%= paymentCsrfToken %>'
            });

            if (!res.ok) throw new Error('Order creation failed (HTTP ' + res.status + ')');
            const data = await res.json();

            if (!data.orderId) throw new Error(data.error || 'No order ID returned');

            // Step 2: Open Razorpay Checkout
            const options = {
                key:         '<%= razorpayKeyId %>',
                amount:      data.amount,
                currency:    'INR',
                name:        'Grand Horizon Hotel',
                description: 'Booking <%= bookingRef %>',
                order_id:    data.orderId,

                prefill: {
                    name:    '<%= guestName %>',
                    email:   '<%= guestEmail %>',
                    contact: '<%= guestPhone != null ? guestPhone : "" %>'
                },

                theme: { color: '#c8aa64' },

                modal: {
                    ondismiss: function() {
                        btn.disabled          = false;
                        spinner.style.display = 'none';
                        lock.style.display    = 'block';
                        btn.childNodes[btn.childNodes.length - 1].textContent =
                            'Pay ₹<%= String.format("%,.2f", totalAmount.doubleValue()) %>';
                    }
                },

                handler: function(response) {
                    // Step 3: Send payment IDs to servlet for signature verification
                    const form = document.createElement('form');
                    form.method = 'POST';
                    form.action = '<%= request.getContextPath() %>/payment?action=verify';

                    const fields = {
                        razorpay_order_id:   response.razorpay_order_id,
                        razorpay_payment_id: response.razorpay_payment_id,
                        razorpay_signature:  response.razorpay_signature,
                        bookingRef:          '<%= bookingRef %>',
                        _csrf:               '<%= paymentCsrfToken %>'
                    };

                    Object.entries(fields).forEach(([name, value]) => {
                        const input = document.createElement('input');
                        input.type  = 'hidden';
                        input.name  = name;
                        input.value = value;
                        form.appendChild(input);
                    });

                    document.body.appendChild(form);
                    form.submit();
                }
            };

            const rzp = new Razorpay(options);

            rzp.on('payment.failed', function(response) {
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = '<%= request.getContextPath() %>/payment?action=failed';

                const fields = {
                    bookingRef:     '<%= bookingRef %>',
                    bookingId:      '<%= bookingId %>',
                    razorpay_order_id: response.error.metadata.order_id   || '',
                    razorpay_payment_id: response.error.metadata.payment_id || '',
                    error_code:     response.error.code        || '',
                    error_desc:     response.error.description || 'Payment failed'
                };

                Object.entries(fields).forEach(([name, value]) => {
                    const input = document.createElement('input');
                    input.type = 'hidden'; input.name = name; input.value = value;
                    form.appendChild(input);
                });

                document.body.appendChild(form);
                form.submit();
            });

            rzp.open();

        } catch (err) {
            console.error('Payment initiation error:', err);
            btn.disabled          = false;
            spinner.style.display = 'none';
            lock.style.display    = 'block';
            btn.childNodes[btn.childNodes.length - 1].textContent =
                'Pay ₹<%= String.format("%,.2f", totalAmount.doubleValue()) %>';

            // Show inline error
            const alertDiv = document.createElement('div');
            alertDiv.className = 'alert alert--error';
            alertDiv.style.marginTop = '1rem';
            alertDiv.textContent = 'Could not initialise payment: ' + err.message +
                '. Please refresh and try again.';
            document.getElementById('payBtn').insertAdjacentElement('afterend', alertDiv);
        }
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
