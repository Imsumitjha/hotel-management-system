<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
      .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
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
  if (request.getAttribute("publicRoom") == null && request.getAttribute("roomLoadError") == null) {
    request.getRequestDispatcher("/room?action=detail&id=" + java.net.URLEncoder.encode(
        request.getParameter("id") == null ? "" : request.getParameter("id"), "UTF-8")
        + "&type=" + java.net.URLEncoder.encode(
        request.getParameter("type") == null ? "" : request.getParameter("type"), "UTF-8"))
        .include(request, response);
  }
  Map<String, Object> room = (Map<String, Object>) request.getAttribute("publicRoom");
  boolean roomLoadError = Boolean.TRUE.equals(request.getAttribute("roomLoadError"));
  String roomType = room == null ? "" : String.valueOf(room.get("roomType"));
  String roomNumber = room == null ? "" : String.valueOf(room.get("roomNumber"));
  String floor = room == null ? "" : String.valueOf(room.get("floor"));
  String capacity = room == null ? "" : String.valueOf(room.get("capacity"));
  String roomStatus = room == null ? "" : String.valueOf(room.get("status"));
  String description = room == null ? "" : String.valueOf(room.get("description"));
  String slug = bookingSlug(roomType);
  java.math.BigDecimal rateValue = room == null ? null : (java.math.BigDecimal) room.get("rate");
  String rate = rateValue == null ? "" : "₹" + String.format(Locale.US, "%,.0f", rateValue.doubleValue());
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= room == null ? "Room Details" : h(roomType) %> — Grand Horizon Hotel</title>
  <link rel="stylesheet" href="css/style.css">
  <style>
    .room-detail-page { padding: 7rem 0 4rem; }
    .room-detail-hero { min-height: 340px; display:flex; align-items:flex-end; padding:3rem; margin-bottom:2rem; background:linear-gradient(140deg,#101420,#1a1025 55%,#0d1010); border:1px solid var(--border); }
    .room-detail-layout { display:grid; grid-template-columns:minmax(0,1.6fr) minmax(280px,.8fr); gap:3rem; }
    .room-booking-card { padding:1.5rem; border:1px solid var(--border-light); border-radius:var(--radius-md); background:var(--surface); position:sticky; top:6rem; }
    .room-price-large { font-family:var(--font-display); font-size:2rem; color:var(--gold-light); }
    .room-facts { display:grid; grid-template-columns:1fr 1fr; gap:1rem; margin:1.5rem 0; }
    .room-fact { padding:1rem; background:var(--charcoal); border:1px solid var(--border); }
    .room-fact small { display:block; color:var(--text-muted); margin-bottom:.35rem; }
    .room-description { line-height:1.9; color:var(--text-secondary); }
    @media(max-width:760px) { .room-detail-layout{grid-template-columns:1fr}.room-booking-card{position:static}.room-detail-hero{padding:2rem} }
  </style>
</head>
<body>
<nav class="navbar scrolled"><div class="container"><div class="navbar__inner">
  <a href="index.jsp" class="navbar__logo"><span class="navbar__logo-main">Grand Horizon</span><span class="navbar__logo-sub">Luxury Hotel &amp; Suites</span></a>
  <ul class="navbar__links"><li><a href="index.jsp">Home</a></li><li><a href="rooms.jsp" class="active">Rooms</a></li><li><a href="booking.jsp">Book</a></li><li><a href="contact.jsp">Contact</a></li><li><a href="login.jsp">Sign In</a></li></ul>
  <a href="rooms.jsp" class="btn navbar__cta">All Rooms</a><div class="hamburger"><span></span><span></span><span></span></div>
</div></div></nav>
<main class="room-detail-page">
  <div class="container">
  <% if (roomLoadError) { %>
    <div class="alert alert--error" role="alert">Room details are temporarily unavailable. Please try again shortly.</div>
  <% } else if (room == null) { %>
    <section class="room-detail-hero"><div><span class="page-hero__eyebrow">Room unavailable</span><h1 class="page-hero__title">We couldn’t find that room</h1><p class="section-subtitle">It may no longer be available. Browse the current room list for other options.</p><a href="rooms.jsp" class="btn btn--primary">Browse Rooms</a></div></section>
  <% } else { %>
    <a href="rooms.jsp" class="btn btn--ghost btn--sm">← All Rooms</a>
    <section class="room-detail-hero" style="margin-top:1rem;"><div>
      <span class="page-hero__eyebrow"><%= h(floor) %> · Room <%= h(roomNumber) %></span>
      <h1 class="page-hero__title"><%= h(roomType) %></h1>
      <p class="section-subtitle"><%= h(capacity) %></p>
    </div></section>
    <div class="room-detail-layout">
      <section>
        <h2 class="auth-title">About this room</h2>
        <p class="room-description"><%= h(description.isEmpty() ? "A comfortable room prepared for your stay at Grand Horizon." : description) %></p>
        <div class="room-facts">
          <div class="room-fact"><small>Room number</small><%= h(roomNumber) %></div>
          <div class="room-fact"><small>Floor</small><%= h(floor) %></div>
          <div class="room-fact"><small>Capacity</small><%= h(capacity) %></div>
          <div class="room-fact"><small>Room status</small><%= h(roomStatus) %></div>
        </div>
        <p class="room-description">Availability is checked for your selected stay dates during booking. Check-in is from 2:00 PM and check-out is by 12:00 PM.</p>
      </section>
      <aside class="room-booking-card">
        <p class="room-price-large"><%= h(rate) %> <span style="font-size:1rem">/ night</span></p>
        <p class="room-description">Final price and availability are confirmed during booking.</p>
        <% if (!slug.isEmpty()) { %>
          <a class="btn btn--primary btn--full" href="booking.jsp?room=<%= slug %>">Check dates &amp; book</a>
        <% } else { %>
          <p class="room-description">Please contact the hotel to book this room type.</p>
        <% } %>
      </aside>
    </div>
  <% } %>
  </div>
</main>
<footer class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);background:var(--deep-navy);font-size:.78rem;color:var(--text-muted);">
  &copy; 2026 Grand Horizon Hotel · All rights reserved.
</footer>
</body>
</html>
