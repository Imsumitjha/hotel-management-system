<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
      .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
  }
  private String roomCategory(String type) {
    if (type == null) return "standard";
    String t = type.toLowerCase(Locale.ROOT);
    if (t.contains("family")) return "family";
    if (t.contains("suite") && !t.contains("presidential")) return "suite";
    if (t.contains("presidential")) return "signature";
    return "standard";
  }
  private String bookingSlug(String type) {
    if (type == null) return "";
    String t = type.toLowerCase(Locale.ROOT);
    if (t.equals("deluxe room")) return "deluxe";
    if (t.equals("twin room")) return "twin";
    if (t.equals("family suite")) return "family";
    if (t.equals("junior suite")) return "junior-suite";
    if (t.equals("executive suite")) return "executive";
    if (t.equals("presidential suite")) return "presidential";
    return "";
  }
%>
<%
  if (request.getAttribute("publicRooms") == null && request.getAttribute("roomLoadError") == null) {
    request.getRequestDispatcher("/room?action=public-list").include(request, response);
  }
  List<Map<String, Object>> rooms = (List<Map<String, Object>>) request.getAttribute("publicRooms");
  boolean roomLoadError = Boolean.TRUE.equals(request.getAttribute("roomLoadError"));
  if (rooms == null) rooms = Collections.emptyList();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rooms &amp; Suites — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<nav class="navbar scrolled" id="navbar">
  <div class="container"><div class="navbar__inner">
    <a href="index.jsp" class="navbar__logo"><span class="navbar__logo-main">Grand Horizon</span><span class="navbar__logo-sub">Luxury Hotel &amp; Suites</span></a>
    <ul class="navbar__links"><li><a href="index.jsp">Home</a></li><li><a href="rooms.jsp" class="active">Rooms</a></li><li><a href="booking.jsp">Book</a></li><li><a href="contact.jsp">Contact</a></li><li><a href="login.jsp">Sign In</a></li></ul>
    <a href="booking.jsp" class="btn navbar__cta">Reserve Now</a><div class="hamburger"><span></span><span></span><span></span></div>
  </div></div>
</nav>
<header class="page-hero"><div class="container">
  <span class="page-hero__eyebrow">Accommodations</span><h1 class="page-hero__title">Rooms &amp; <em>Suites</em></h1>
  <div class="section-divider"></div><p class="section-subtitle">Explore every room and suite at Grand Horizon. Availability is confirmed for your selected dates.</p>
</div></header>
<section class="room-filters"><div class="container"><div class="room-filters__inner">
  <span style="font-size:.7rem;letter-spacing:.2em;text-transform:uppercase;color:var(--text-muted);margin-right:.5rem;">Filter:</span>
  <button class="filter-btn active" data-filter="all">All Rooms</button><button class="filter-btn" data-filter="standard">Standard</button><button class="filter-btn" data-filter="suite">Suite</button><button class="filter-btn" data-filter="family">Family</button><button class="filter-btn" data-filter="signature">Signature</button>
</div></div></section>
<main class="container">
  <% if (roomLoadError) { %>
    <div class="alert alert--error" role="alert">Rooms are temporarily unavailable. Please try again shortly.</div>
  <% } else if (rooms.isEmpty()) { %>
    <p class="section-subtitle">There are no rooms to display right now. Please check back soon.</p>
  <% } else { %>
  <div class="rooms-page-grid" id="roomsGrid">
    <% for (Map<String, Object> room : rooms) {
         String type = String.valueOf(room.get("roomType"));
         Object rawRate = room.get("rate");
         String rate = rawRate == null ? "Price on request" : "₹" + String.format(Locale.US, "%,.0f", ((java.math.BigDecimal) rawRate).doubleValue());
         String category = roomCategory(type);
         String slug = bookingSlug(type);
         String roomStatus = String.valueOf(room.get("status"));
    %>
    <article class="card" data-category="<%= category %>">
      <div style="aspect-ratio:16/10;background:linear-gradient(135deg,#1c2230,#2a3347);display:flex;align-items:center;justify-content:center;position:relative;">
        <span style="font-family:var(--font-display);font-size:1.2rem;color:var(--gold);"><%= h(type) %></span>
        <span style="position:absolute;top:1rem;left:1rem;background:var(--gold);color:var(--obsidian);font-size:.6rem;padding:.2rem .7rem;text-transform:uppercase;"><%= h(category) %></span>
      </div>
      <div class="card__body">
        <p class="card__category"><%= h(room.get("floor")) %> · Room <%= h(room.get("roomNumber")) %></p>
        <h2 class="card__title"><%= h(type) %></h2>
        <p class="card__desc"><%= h(room.get("description")) %></p>
        <div class="card__features">
          <span class="badge"><%= h(room.get("capacity")) %></span>
          <span class="badge">Room status: <%= h(roomStatus) %></span>
        </div>
        <p class="card__price"><%= h(rate) %> <span>/ night</span></p>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:.75rem;">
          <a href="room-details.jsp?id=<%= h(room.get("id")) %>" class="btn btn--ghost btn--sm">View Details</a>
          <% if (!slug.isEmpty()) { %><a href="booking.jsp?room=<%= slug %>" class="btn btn--outline btn--sm">Book Now</a><% } %>
        </div>
      </div>
    </article>
    <% } %>
  </div>
  <% } %>
</main>
<footer class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);background:var(--deep-navy);font-size:.78rem;color:var(--text-muted);">
  &copy; 2026 Grand Horizon Hotel · All rights reserved.
</footer>
<script>
  document.querySelectorAll('.filter-btn').forEach(function(button) {
    button.addEventListener('click', function() {
      document.querySelectorAll('.filter-btn').forEach(function(item) { item.classList.remove('active'); });
      button.classList.add('active');
      var filter = button.getAttribute('data-filter');
      document.querySelectorAll('#roomsGrid .card').forEach(function(card) {
        card.hidden = filter !== 'all' && card.getAttribute('data-category') !== filter;
      });
    });
  });
</script>
</body>
</html>
