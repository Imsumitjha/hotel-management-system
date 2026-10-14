<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Signed Out — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
<main class="auth-page">
    <section class="auth-panel" style="margin:auto;max-width:560px;">
        <div class="auth-form-wrap" style="text-align:center;">
            <a href="index.jsp" class="auth-logo">Grand Horizon</a>
            <p class="auth-tagline">Luxury Hotel &amp; Suites</p>
            <h1 class="auth-title">You’re signed out</h1>
            <p class="auth-subtitle">Your session has ended. Sign in again whenever you’re ready.</p>
            <% if ("1".equals(request.getParameter("csrf"))) { %>
                <p class="auth-subtitle">Your session was ended. The sign-out request could not be verified.</p>
            <% } %>
            <a href="login.jsp" class="btn btn--primary btn--full">Sign In</a>
            <p class="auth-footer-text" style="margin-top:1rem;">
                <a href="index.jsp">Return to the hotel website</a>
            </p>
        </div>
    </section>
</main>
</body>
</html>
