<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  String contactCsrfToken = (String) session.getAttribute("csrfToken");
  if (contactCsrfToken == null) {
    contactCsrfToken = java.util.UUID.randomUUID().toString();
    session.setAttribute("csrfToken", contactCsrfToken);
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Contact Us — Grand Horizon Hotel</title>
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
        <li><a href="booking.jsp">Book</a></li>
        <li><a href="contact.jsp" class="active">Contact</a></li>
        <li><a href="login.jsp">Sign In</a></li>
      </ul>
      <a href="booking.jsp" class="btn navbar__cta">Reserve Now</a>
      <div class="hamburger"><span></span><span></span><span></span></div>
    </div>
  </div>
</nav>

<div class="contact-page">
  <div class="container">

    <div class="contact-layout">

      <!-- Info Column -->
      <div>
        <span class="page-hero__eyebrow" style="display:block;margin-bottom:1rem;">Get In Touch</span>
        <h1 class="contact-info__title">
          We'd Love to<br>
          <em>Hear From You</em>
        </h1>
        <div class="section-divider" style="margin:1.5rem 0;"></div>
        <p class="contact-info__text">
          Whether you're planning a stay, celebrating a milestone, or simply curious about
          our services — our team is always ready to assist with warmth and precision.
        </p>

        <div class="contact-details">
          <div class="contact-detail-item">
            <div class="contact-detail-icon">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/>
              </svg>
            </div>
            <div>
              <p class="contact-detail-label">Address</p>
              <p class="contact-detail-value">12, Palace Road, Near Golden Temple<br>Amritsar, Punjab — 143001</p>
            </div>
          </div>

          <div class="contact-detail-item">
            <div class="contact-detail-icon">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013 6.18 2 2 0 015 4h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L9.09 11.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 18v-.08z"/>
              </svg>
            </div>
            <div>
              <p class="contact-detail-label">Telephone</p>
              <p class="contact-detail-value"><a href="tel:+911234567890">+91 12345 67890</a></p>
            </div>
          </div>

          <div class="contact-detail-item">
            <div class="contact-detail-icon">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/>
              </svg>
            </div>
            <div>
              <p class="contact-detail-label">Email</p>
              <p class="contact-detail-value"><a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a></p>
            </div>
          </div>

          <div class="contact-detail-item">
            <div class="contact-detail-icon">
              <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
              </svg>
            </div>
            <div>
              <p class="contact-detail-label">Hours</p>
              <p class="contact-detail-value">Reception: 24 / 7<br>Concierge: 08:00 — 22:00</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Form Column -->
      <div class="contact-form-card">
        <h2 style="font-family:var(--font-display);font-size:1.8rem;font-weight:300;margin-bottom:0.5rem;">Send a Message</h2>
        <p style="font-size:0.88rem;color:var(--text-muted);margin-bottom:2rem;">Our concierge team will respond within 4 business hours.</p>

        <% String successMsg = (String) request.getAttribute("success"); %>
        <% if (successMsg != null) { %>
          <div class="alert alert--success">
            <svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
            <%= successMsg %>
          </div>
        <% } %>

        <form action="contact" method="post" id="contactForm">
          <input type="hidden" name="_csrf" value="<%= contactCsrfToken %>">
          <input type="hidden" name="action" value="submit">

          <div class="form-row">
            <div class="form-group">
              <label for="cfName">Full Name</label>
              <input type="text" id="cfName" name="name" class="form-control" placeholder="Arjun Sharma" required>
            </div>
            <div class="form-group">
              <label for="cfEmail">Email Address</label>
              <input type="email" id="cfEmail" name="email" class="form-control" placeholder="arjun@example.com" required>
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="cfPhone">Phone Number</label>
              <input type="tel" id="cfPhone" name="phone" class="form-control" placeholder="+91 98765 43210">
            </div>
            <div class="form-group">
              <label for="cfSubject">Subject</label>
              <select id="cfSubject" name="subject" class="form-control form-select">
                <option>General Inquiry</option>
                <option>Room Reservation</option>
                <option>Special Occasions</option>
                <option>Corporate Events</option>
                <option>Feedback</option>
                <option>Other</option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label for="cfMessage">Message</label>
            <textarea id="cfMessage" name="message" class="form-control" rows="5"
                      placeholder="Tell us how we can help you..." required></textarea>
          </div>

          <button type="submit" class="btn btn--primary btn--full">Send Message</button>

        </form>
      </div>

    </div><!-- /contact-layout -->

  </div>
</div>

<!-- Footer -->
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
          <li><a href="login.jsp">Sign In</a></li>
          <li><a href="register.jsp">Register</a></li>
        </ul>
      </div>
      <div>
        <p class="footer__heading">Contact</p>
        <ul class="footer__links">
          <li><a href="tel:+919321132636">+91 93211 32636</a></li>
          <li><a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a></li>
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
</body>
</html>
