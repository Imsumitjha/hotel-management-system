<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%! private String html(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
} %>
<%
  HttpSession userSession = request.getSession(false);
  boolean signedIn = userSession != null && userSession.getAttribute("userId") != null;
  String displayName = signedIn ? (String) userSession.getAttribute("userName") : "";
  if (displayName == null || displayName.trim().isEmpty()) displayName = "Account";
  boolean adminUser = signedIn && "admin".equalsIgnoreCase(String.valueOf(userSession.getAttribute("userRole")));
  String dashboardUrl = request.getContextPath() + (adminUser ? "/admin" : "/user-dashboard.jsp");
  String loginUrl = request.getContextPath() + "/login.jsp";
  String registerUrl = request.getContextPath() + "/register.jsp";
  String logoutUrl = request.getContextPath() + "/logout";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Grand Horizon Hotel — A Sanctuary of Refinement</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>

<!-- ── Navigation ──────────────────────────────────────────── -->
<nav class="navbar" id="navbar">
  <div class="container">
    <div class="navbar__inner">
      <a href="index.jsp" class="navbar__logo">
        <span class="navbar__logo-main">Grand Horizon</span>
        <span class="navbar__logo-sub">Luxury Hotel &amp; Suites</span>
      </a>
      <ul class="navbar__links" id="primary-navigation">
        <li><a href="index.jsp" class="active">Home</a></li>
        <li><a href="rooms.jsp">Rooms</a></li>
        <li><a href="booking.jsp">Book</a></li>
        <li><a href="contact.jsp">Contact</a></li>
        <% if (signedIn) { %>
          <li><a href="<%= dashboardUrl %>"><%= html(displayName) %>'s Account</a></li>
          <li><a href="<%= logoutUrl %>">Sign Out</a></li>
        <% } else { %>
          <li><a href="<%= loginUrl %>">Sign In</a></li>
        <% } %>
      </ul>
      <a href="booking.jsp" class="btn navbar__cta">Reserve Now</a>
      <button class="hamburger" id="hamburger" type="button" aria-label="Open navigation menu" aria-expanded="false" aria-controls="primary-navigation">
        <span></span><span></span><span></span>
      </button>
    </div>
  </div>
</nav>

<!-- ── Hero ────────────────────────────────────────────────── -->
<section class="hero">
  <div class="hero__bg"></div>
  <div class="hero__content">
    <p class="hero__eyebrow">Est. 1965 &nbsp;·&nbsp; Five Star Excellence</p>
    <h1 class="hero__title">
      Where Luxury<br>
      <em>Meets Serenity</em>
    </h1>
    <p class="hero__subtitle">
      An intimate retreat where every detail is curated for the discerning traveller.
      Timeless elegance, exceptional service, unforgettable moments.
    </p>
    <div class="hero__actions">
      <a href="rooms.jsp" class="btn btn--primary btn--lg">Explore Rooms</a>
      <a href="contact.jsp" class="btn btn--outline btn--lg">Our Story</a>
    </div>
  </div>
  <div class="hero__scroll">Discover</div>
</section>

<!-- ── Quick Book ───────────────────────────────────────────── -->
<section class="quick-book">
  <div class="container">
    <form action="booking" method="get" class="quick-book__inner">
      <div class="form-group">
        <label for="checkin">Check-In</label>
        <input type="date" id="checkin" name="checkin" class="form-control" required>
      </div>
      <div class="form-group">
        <label for="checkout">Check-Out</label>
        <input type="date" id="checkout" name="checkout" class="form-control" required>
      </div>
      <div class="form-group">
        <label for="room">Room Type</label>
        <select id="room" name="room" class="form-control form-select" required>
          <option value="">Choose a room</option>
          <option value="deluxe">Deluxe Room</option>
          <option value="twin">Twin Room</option>
          <option value="family">Family Suite</option>
          <option value="junior-suite">Junior Suite</option>
          <option value="executive">Executive Suite</option>
          <option value="presidential">Presidential Suite</option>
        </select>
      </div>
      <button type="submit" class="btn btn--primary">Check Availability</button>
    </form>
  </div>
</section>

<!-- ── Features ─────────────────────────────────────────────── -->
<section class="features-strip">
  <div class="container">
    <div class="features-grid">

      <div class="feature-item">
        <svg class="feature-icon" fill="none" stroke="currentColor" stroke-width="1.2" viewBox="0 0 24 24">
          <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>
        </svg>
        <h3 class="feature-title">Opulent Suites</h3>
        <p class="feature-desc">Hand-selected furnishings, private terraces, and panoramic views of the city skyline.</p>
      </div>

      <div class="feature-item">
        <svg class="feature-icon" fill="none" stroke="currentColor" stroke-width="1.2" viewBox="0 0 24 24">
          <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
        </svg>
        <h3 class="feature-title">White Glove Service</h3>
        <p class="feature-desc">Our concierge team is at your service around the clock, anticipating every need.</p>
      </div>

      <div class="feature-item">
        <svg class="feature-icon" fill="none" stroke="currentColor" stroke-width="1.2" viewBox="0 0 24 24">
          <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
        </svg>
        <h3 class="feature-title">24/7 Availability</h3>
        <p class="feature-desc">Late arrivals, early departures — your schedule is our schedule. Always open, always ready.</p>
      </div>

      <div class="feature-item">
        <svg class="feature-icon" fill="none" stroke="currentColor" stroke-width="1.2" viewBox="0 0 24 24">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/>
        </svg>
        <h3 class="feature-title">Prime Location</h3>
        <p class="feature-desc">Nestled in the heart of the city, moments from culture, cuisine, and commerce.</p>
      </div>

    </div>
  </div>
</section>

<!-- ── Featured Rooms ───────────────────────────────────────── -->
<section class="rooms-section">
  <div class="container">
    <div class="section-header">
      <span class="section-label">Accommodations</span>
      <h2 class="section-title">Rooms &amp; <em>Suites</em></h2>
      <div class="section-divider"></div>
      <p class="section-subtitle">Each room is a private world — thoughtfully designed to offer rest, inspiration, and absolute comfort.</p>
    </div>

    <div class="rooms-grid">

      <div class="card">
        <div style="aspect-ratio:16/10;background:linear-gradient(135deg,#1c2230,#2a3347);display:flex;align-items:center;justify-content:center;color:var(--gold);font-family:var(--font-display);font-size:1.1rem;letter-spacing:0.1em;">Deluxe Room</div>
        <div class="card__body">
          <p class="card__category">Standard</p>
          <h3 class="card__title">Deluxe Room</h3>
          <p class="card__desc">Refined comfort with king-size bed, premium linens, and an ensuite marble bathroom.</p>
          <div class="card__features">
            <span class="badge">King Bed</span>
            <span class="badge">City View</span>
            <span class="badge">Marble Bath</span>
          </div>
          <p class="card__price">₹8,500 <span>/ night</span></p>
          <a href="booking.jsp?room=deluxe" class="btn btn--outline btn--full">Book This Room</a>
        </div>
      </div>

      <div class="card">
        <div style="aspect-ratio:16/10;background:linear-gradient(135deg,#1e1a2c,#2e2440);display:flex;align-items:center;justify-content:center;color:var(--gold);font-family:var(--font-display);font-size:1.1rem;letter-spacing:0.1em;">Junior Suite</div>
        <div class="card__body">
          <p class="card__category">Suite</p>
          <h3 class="card__title">Junior Suite</h3>
          <p class="card__desc">A separate living area, dining nook, and a private balcony overlooking the gardens.</p>
          <div class="card__features">
            <span class="badge">King Bed</span>
            <span class="badge">Balcony</span>
            <span class="badge">Lounge Area</span>
          </div>
          <p class="card__price">₹15,000 <span>/ night</span></p>
          <a href="booking.jsp?room=junior-suite" class="btn btn--outline btn--full">Book This Room</a>
        </div>
      </div>

      <div class="card">
        <div style="aspect-ratio:16/10;background:linear-gradient(135deg,#1a1c18,#2a2e20);display:flex;align-items:center;justify-content:center;color:var(--gold);font-family:var(--font-display);font-size:1.1rem;letter-spacing:0.1em;">Presidential Suite</div>
        <div class="card__body">
          <p class="card__category">Signature</p>
          <h3 class="card__title">Presidential Suite</h3>
          <p class="card__desc">Our crown jewel. A 120 sqm sanctuary with a private butler, jacuzzi, and panoramic views.</p>
          <div class="card__features">
            <span class="badge">Butler</span>
            <span class="badge">Jacuzzi</span>
            <span class="badge">Panoramic</span>
          </div>
          <p class="card__price">₹38,000 <span>/ night</span></p>
          <a href="booking.jsp?room=presidential" class="btn btn--primary btn--full">Book This Room</a>
        </div>
      </div>

    </div>

    <div style="text-align:center;margin-top:3rem;">
      <a href="rooms.jsp" class="btn btn--outline">View All Rooms</a>
    </div>
  </div>
</section>

<!-- ── Testimonial ──────────────────────────────────────────── -->
<section class="testimonials">
  <div class="container">
    <span class="section-label">Guest Voices</span>
    <div class="ornament" style="margin:1rem 0 2.5rem;"><span>✦</span></div>
    <blockquote class="testimonial-quote">
      "Staying at Grand Horizon was not merely a visit — it was a transformation.
      Every moment felt choreographed to perfection."
    </blockquote>
    <p class="testimonial-author">— Priya Sharma &nbsp;·&nbsp; Mumbai</p>
  </div>
</section>

<!-- ── Footer ───────────────────────────────────────────────── -->
<footer class="footer">
  <div class="container">
    <div class="footer__grid">
      <div>
        <p class="footer__brand">Grand Horizon</p>
        <p class="footer__tagline">A sanctuary of refined luxury, where every stay becomes a cherished memory.</p>
      </div>
      <div>
        <p class="footer__heading">Navigation</p>
        <ul class="footer__links">
          <li><a href="index.jsp">Home</a></li>
          <li><a href="rooms.jsp">Rooms &amp; Suites</a></li>
          <li><a href="booking.jsp">Reservations</a></li>
          <li><a href="contact.jsp">Contact Us</a></li>
        </ul>
      </div>
      <div>
        <p class="footer__heading">Account</p>
        <ul class="footer__links">
          <% if (signedIn) { %>
            <li><a href="<%= dashboardUrl %>">My Account</a></li>
            <li><a href="<%= logoutUrl %>">Sign Out</a></li>
          <% } else { %>
            <li><a href="<%= loginUrl %>">Sign In</a></li>
            <li><a href="<%= registerUrl %>">Register</a></li>
          <% } %>
        </ul>
      </div>
      <div>
        <p class="footer__heading">Contact</p>
        <ul class="footer__links">
          <li><a href="tel:+919321132636">+91 93211 32636</a></li>
          <li><a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a></li>
          <li><a href="#">12, Palace Road, Amritsar</a></li>
        </ul>
      </div>
    </div>
    <div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
      &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
      <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
    </div>
  </div>
</footer>

<script>
  // Navbar scroll effect
  const navbar = document.getElementById('navbar');
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.querySelector('.navbar__links');
  window.addEventListener('scroll', () => {
    navbar.classList.toggle('scrolled', window.scrollY > 60);
  });

  hamburger.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('is-open');
    hamburger.setAttribute('aria-expanded', String(isOpen));
    hamburger.setAttribute('aria-label', isOpen ? 'Close navigation menu' : 'Open navigation menu');
  });
  navLinks.addEventListener('click', event => {
    if (event.target.closest('a')) {
      navLinks.classList.remove('is-open');
      hamburger.setAttribute('aria-expanded', 'false');
      hamburger.setAttribute('aria-label', 'Open navigation menu');
    }
  });

  // Set min date for date inputs
  const formatLocalDate = date => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };
  const today = formatLocalDate(new Date());
  document.getElementById('checkin').min = today;
  const firstCheckout = new Date();
  firstCheckout.setDate(firstCheckout.getDate() + 1);
  document.getElementById('checkout').min = formatLocalDate(firstCheckout);

  document.getElementById('checkin').addEventListener('change', e => {
    const checkout = document.getElementById('checkout');
    const earliestCheckout = new Date(`${e.target.value}T00:00:00`);
    earliestCheckout.setDate(earliestCheckout.getDate() + 1);
    checkout.min = formatLocalDate(earliestCheckout);
    if (checkout.value && checkout.value < checkout.min) checkout.value = '';
  });
</script>
</body>
</html>
