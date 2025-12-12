<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List,java.util.Map,javax.servlet.http.HttpSession" %>
<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";
        return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    HttpSession adminSession = request.getSession(false);
    if (adminSession == null || !"admin".equals(adminSession.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/admin/admin-login.jsp");
        return;
    }
    List<Map<String, Object>> messages = (List<Map<String, Object>>) request.getAttribute("contactMessages");
    if (messages == null) {
        response.sendRedirect(request.getContextPath() + "/contact?action=list");
        return;
    }
    String csrfToken = String.valueOf(request.getAttribute("csrfToken"));
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Contact messages | Grand Horizon Admin</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        body { padding: 2rem; background: #101522; color: #f1eee6; font-family: Arial, sans-serif; }
        main { max-width: 1100px; margin: auto; }
        article { margin: 1rem 0; padding: 1.25rem; border: 1px solid #343b49; border-radius: 8px; background: #191f2c; }
        .muted { color: #b3b7c0; font-size: .9rem; }
        .message { white-space: pre-wrap; overflow-wrap: anywhere; }
        form { display: inline-block; margin: .5rem .5rem 0 0; }
        button { cursor: pointer; padding: .5rem .8rem; }
    </style>
</head>
<body>
<main>
    <p><a href="dashboard.jsp">Admin dashboard</a></p>
    <h1>Contact messages</h1>
    <p><%= request.getAttribute("unreadCount") %> unread</p>
    <% if (messages.isEmpty()) { %><p>No contact messages.</p><% } %>
    <% for (Map<String, Object> message : messages) { %>
        <article>
            <h2><%= escapeHtml(message.get("subject")) %></h2>
            <p class="muted">
                <%= escapeHtml(message.get("name")) %> ·
                <a href="mailto:<%= escapeHtml(message.get("email")) %>"><%= escapeHtml(message.get("email")) %></a>
                <% if (message.get("phone") != null) { %> · <%= escapeHtml(message.get("phone")) %><% } %>
                · <%= escapeHtml(message.get("createdAt")) %>
            </p>
            <div class="message"><%= escapeHtml(message.get("message")) %></div>
            <form method="post" action="<%= request.getContextPath() %>/contact">
                <input type="hidden" name="_csrf" value="<%= escapeHtml(csrfToken) %>">
                <input type="hidden" name="id" value="<%= escapeHtml(message.get("id")) %>">
                <input type="hidden" name="action" value="<%= Boolean.TRUE.equals(message.get("isRead")) ? "unread" : "read" %>">
                <button type="submit"><%= Boolean.TRUE.equals(message.get("isRead")) ? "Mark unread" : "Mark read" %></button>
            </form>
            <form method="post" action="<%= request.getContextPath() %>/contact" onsubmit="return confirm('Delete this message?')">
                <input type="hidden" name="_csrf" value="<%= escapeHtml(csrfToken) %>">
                <input type="hidden" name="id" value="<%= escapeHtml(message.get("id")) %>">
                <input type="hidden" name="action" value="delete">
                <button type="submit">Delete</button>
            </form>
        </article>
    <% } %>
</main>
</body>
</html>
