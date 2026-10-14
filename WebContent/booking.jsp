<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  String bookingCsrfToken = (String) session.getAttribute("csrfToken");
  if (bookingCsrfToken == null) {
    bookingCsrfToken = java.util.UUID.randomUUID().toString();
    session.setAttribute("csrfToken", bookingCsrfToken);
  }
  String preCheckin = String.valueOf(request.getAttribute("preCheckin") == null ? "" : request.getAttribute("preCheckin"));
  String preCheckout = String.valueOf(request.getAttribute("preCheckout") == null ? "" : request.getAttribute("preCheckout"));
  if (!preCheckin.matches("\\d{4}-\\d{2}-\\d{2}")) preCheckin = "";
  if (!preCheckout.matches("\\d{4}-\\d{2}-\\d{2}")) preCheckout = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reserve Your Stay — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="css/style.css">
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
        <li><a href="login.jsp">Sign In</a></li>
      </ul>
      <div class="hamburger"><span></span><span></span><span></span></div>
    </div>
  </div>
</nav>

<div class="booking-page">
  <div class="container">

    <div style="margin-bottom:3rem;">
      <span class="page-hero__eyebrow">Reservation</span>
      <h1 style="font-family:var(--font-display);font-size:clamp(2rem,4vw,3rem);font-weight:300;margin-top:0.5rem;">
        Reserve Your <em style="font-style:italic;color:var(--gold-light);">Stay</em>
      </h1>
    </div>

    <!-- Steps -->
    <div class="booking-steps">
      <div class="step active"><span class="step__number">01</span>Dates &amp; Room</div>
      <div class="step"><span class="step__number">02</span>Guest Details</div>
      <div class="step"><span class="step__number">03</span>Review</div>
      <div class="step"><span class="step__number">04</span>Confirm</div>
    </div>

    <div class="booking-layout">

      <!-- Main Form -->
      <div class="booking-form-card">
        <h2>Your Reservation</h2>
        <p style="font-size:0.88rem;color:var(--text-muted);margin-bottom:2.5rem;">Please fill in your details below to complete your booking.</p>

        <% String roomParam = request.getParameter("room"); if (roomParam == null) roomParam = ""; %>
        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %><div class="alert alert--error"><%= error %></div><% } %>

        <form action="booking" method="post" id="bookingForm">
          <input type="hidden" name="_csrf" value="<%= bookingCsrfToken %>">

          <!-- Room Selection -->
          <div class="form-group">
            <label for="roomType">Room Type</label>
            <select id="roomType" name="roomType" class="form-control form-select" required onchange="updatePrice()">
              <option value="">— Select a room —</option>
              <option value="deluxe"      data-price="8500"  <%= "deluxe".equals(roomParam)       ? "selected" : "" %>>Deluxe Room — ₹8,500/night</option>
              <option value="twin"        data-price="7200"  <%= "twin".equals(roomParam)         ? "selected" : "" %>>Deluxe Twin Room — ₹7,200/night</option>
              <option value="family"      data-price="12000" <%= "family".equals(roomParam)       ? "selected" : "" %>>Family Suite — ₹12,000/night</option>
              <option value="junior-suite" data-price="15000" <%= "junior-suite".equals(roomParam) ? "selected" : "" %>>Junior Suite — ₹15,000/night</option>
              <option value="executive"   data-price="22000" <%= "executive".equals(roomParam)    ? "selected" : "" %>>Executive Suite — ₹22,000/night</option>
              <option value="presidential" data-price="38000" <%= "presidential".equals(roomParam) ? "selected" : "" %>>Presidential Suite — ₹38,000/night</option>
            </select>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="checkin">Check-In Date</label>
              <input type="date" id="checkin" name="checkin" class="form-control" value="<%= preCheckin %>" required>
            </div>
            <div class="form-group">
              <label for="checkout">Check-Out Date</label>
              <input type="date" id="checkout" name="checkout" class="form-control" value="<%= preCheckout %>" required>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="adults">Adults</label>
              <select id="adults" name="adults" class="form-control form-select">
                <option>1</option>
                <option selected>2</option>
                <option>3</option>
                <option>4</option>
              </select>
            </div>
            <div class="form-group">
              <label for="children">Children</label>
              <select id="children" name="children" class="form-control form-select">
                <option selected>0</option>
                <option>1</option>
                <option>2</option>
                <option>3</option>
              </select>
            </div>
          </div>

          <div style="height:1px;background:var(--border);margin:2rem 0;"></div>
          <h3 style="font-family:var(--font-display);font-size:1.3rem;font-weight:400;margin-bottom:1.5rem;">Guest Information</h3>

          <div class="form-row">
            <div class="form-group">
              <label for="guestFirst">First Name</label>
              <input type="text" id="guestFirst" name="guestFirst" class="form-control" placeholder="Arjun" required>
            </div>
            <div class="form-group">
              <label for="guestLast">Last Name</label>
              <input type="text" id="guestLast" name="guestLast" class="form-control" placeholder="Sharma" required>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="guestEmail">Email</label>
              <input type="email" id="guestEmail" name="guestEmail" class="form-control" placeholder="arjun@example.com" required>
            </div>
            <div class="form-group">
              <label for="guestPhone">Phone</label>
              <input type="tel" id="guestPhone" name="guestPhone" class="form-control" placeholder="+91 98765 43210" required>
            </div>
          </div>

          <div class="form-group">
            <label for="specialReq">Special Requests <span style="text-transform:none;letter-spacing:0;color:var(--text-muted);font-size:0.75rem;">(optional)</span></label>
            <textarea id="specialReq" name="specialReq" class="form-control" rows="3" placeholder="Flowers on arrival, high floor, dietary needs..."></textarea>
          </div>

          <div style="height:1px;background:var(--border);margin:2rem 0;"></div>

          <div style="margin-bottom:1.5rem;display:flex;align-items:flex-start;gap:0.8rem;">
            <input type="checkbox" id="terms" name="terms" style="margin-top:3px;accent-color:var(--gold);" required>
            <label for="terms" style="font-size:0.82rem;color:var(--text-secondary);text-transform:none;letter-spacing:0;">
              I agree to the <a href="cancellation-policy.jsp">Cancellation Policy</a> and <a href="terms-of-service.jsp">Terms &amp; Conditions</a>.
            </label>
          </div>

          <button type="submit" class="btn btn--primary btn--full btn--lg">Confirm Reservation</button>

        </form>
      </div>

      <!-- Summary Sidebar -->
      <div class="booking-summary">
        <div class="booking-summary__header">Booking Summary</div>

        <div id="selectedRoom" style="background:var(--charcoal);border:1px solid var(--border);border-radius:var(--radius-sm);padding:1.2rem;margin-bottom:1.5rem;">
          <p style="font-size:0.65rem;letter-spacing:0.2em;text-transform:uppercase;color:var(--gold);margin-bottom:0.4rem;">Selected Room</p>
          <p id="summaryRoom" style="font-family:var(--font-display);font-size:1.1rem;">Not selected</p>
        </div>

        <div class="summary-row">
          <span class="summary-row__label">Check-In</span>
          <span class="summary-row__value" id="summaryCheckin">—</span>
        </div>
        <div class="summary-row">
          <span class="summary-row__label">Check-Out</span>
          <span class="summary-row__value" id="summaryCheckout">—</span>
        </div>
        <div class="summary-row">
          <span class="summary-row__label">Nights</span>
          <span class="summary-row__value" id="summaryNights">—</span>
        </div>
        <div class="summary-row">
          <span class="summary-row__label">Rate / Night</span>
          <span class="summary-row__value" id="summaryRate">—</span>
        </div>
        <div class="summary-row">
          <span class="summary-row__label">Taxes &amp; Fees (12%)</span>
          <span class="summary-row__value" id="summaryTax">—</span>
        </div>
        <div class="summary-row summary-total">
          <span class="summary-row__label" style="font-size:0.82rem;color:var(--text-primary);">Total</span>
          <span class="summary-row__value" id="summaryTotal">—</span>
        </div>

        <div style="margin-top:1.5rem;padding:1rem;background:var(--gold-glow);border:1px solid var(--border-light);border-radius:var(--radius-sm);">
          <p style="font-size:0.75rem;color:var(--gold);display:flex;align-items:center;gap:0.5rem;">
            <svg width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            Free cancellation up to 48 hrs before check-in
          </p>
        </div>

        <div style="margin-top:1rem;padding:1rem;background:rgba(255,255,255,0.02);border:1px solid var(--border);border-radius:var(--radius-sm);">
          <p style="font-size:0.75rem;color:var(--text-muted);line-height:1.7;">Need assistance?<br>
          Call us at <a href="tel:+91 93211 32636" style="color:var(--gold);">+91 93211 32636</a> or email<br>
          <a href="mailto:stay@grandhorizon.in" style="color:var(--gold);">stay@grandhorizon.in</a></p>
        </div>
      </div>

    </div><!-- /booking-layout -->
  </div><!-- /container -->
</div><!-- /booking-page -->

<script>
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('checkin').min  = today;
  document.getElementById('checkout').min = today;

  function fmt(dateStr) {
    if (!dateStr) return '—';
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { day:'2-digit', month:'short', year:'numeric' });
  }

  function updatePrice() {
    const roomSel  = document.getElementById('roomType');
    const checkin  = document.getElementById('checkin').value;
    const checkout = document.getElementById('checkout').value;

    const roomName  = roomSel.options[roomSel.selectedIndex].text.split('—')[0].trim();
    const pricePerNight = parseInt(roomSel.options[roomSel.selectedIndex].dataset.price) || 0;

    document.getElementById('summaryRoom').textContent = roomName || 'Not selected';
    document.getElementById('summaryCheckin').textContent  = fmt(checkin);
    document.getElementById('summaryCheckout').textContent = fmt(checkout);

    if (checkin && checkout && pricePerNight) {
      const nights = Math.round((new Date(checkout) - new Date(checkin)) / 86400000);
      if (nights > 0) {
        const base  = pricePerNight * nights;
        const tax   = Math.round(base * 0.12);
        const total = base + tax;
        document.getElementById('summaryNights').textContent = nights + (nights === 1 ? ' night' : ' nights');
        document.getElementById('summaryRate').textContent   = '₹' + pricePerNight.toLocaleString('en-IN');
        document.getElementById('summaryTax').textContent    = '₹' + tax.toLocaleString('en-IN');
        document.getElementById('summaryTotal').textContent  = '₹' + total.toLocaleString('en-IN');
        return;
      }
    }
    document.getElementById('summaryNights').textContent = '—';
    document.getElementById('summaryRate').textContent   = pricePerNight ? '₹' + pricePerNight.toLocaleString('en-IN') : '—';
    document.getElementById('summaryTax').textContent    = '—';
    document.getElementById('summaryTotal').textContent  = '—';
  }

  document.getElementById('roomType').addEventListener('change', updatePrice);
  document.getElementById('checkin').addEventListener('change', function() {
    document.getElementById('checkout').min = this.value;
    updatePrice();
  });
  document.getElementById('checkout').addEventListener('change', updatePrice);

  // Trigger on load if room param pre-selected
  updatePrice();
</script>
<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
  &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
  <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
