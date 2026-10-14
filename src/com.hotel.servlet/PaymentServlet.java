package com.hotel.servlet;

import com.hotel.util.DBConnection;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.NumberFormat;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * PaymentServlet — Razorpay payment gateway integration.
 *
 * <h3>URL: {@code /PaymentServlet}</h3>
 *
 * <h3>Flow overview</h3>
 * <pre>
 *   booking.jsp
 *       └─ BookingServlet (POST)
 *             Inserts booking (status=Pending)
 *             Stores pending details in session
 *             Redirects → payment.jsp
 *
 *   payment.jsp
 *       └─ JS: fetch("PaymentServlet?action=createOrder")
 *             Returns JSON { orderId: "order_XXXX" }
 *             Razorpay Checkout opens
 *             User pays → Razorpay calls handler(response)
 *             JS POSTs to PaymentServlet?action=verify
 *
 *   PaymentServlet?action=verify (POST)
 *       Verifies HMAC-SHA256 signature
 *       Inserts payment record (status=captured)
 *       Updates booking → Confirmed
 *       Marks room → Occupied
 *       Clears session attributes
 *       Forwards → payment-success.jsp
 *
 *   PaymentServlet?action=failed (POST)
 *       Inserts payment record (status=failed)
 *       Forwards → payment-failed.jsp
 * </pre>
 *
 * <h3>Setup required</h3>
 * <ol>
 *   <li>Create a Razorpay account at https://razorpay.com</li>
 *   <li>Set {@code RAZORPAY_KEY_ID} and {@code RAZORPAY_KEY_SECRET} in the
 *       server environment using a matching Razorpay key pair.</li>
 *   <li>No extra JAR required — uses only standard JDK classes
 *       ({@code HttpURLConnection}, {@code javax.crypto.Mac}).</li>
 * </ol>
 *
 * <h3>Test cards (Razorpay sandbox)</h3>
 * <pre>
 *   Success:  4111 1111 1111 1111  |  Any future expiry  |  Any CVV  |  OTP: 1234
 *   Failure:  4000 0000 0000 0002  |  Any future expiry  |  Any CVV
 *   UPI:      success@razorpay  (test VPA — always succeeds)
 * </pre>
 */
@WebServlet("/payment")
public class PaymentServlet extends HttpServlet {

    private static final long   serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(PaymentServlet.class.getName());

    // ── Razorpay credentials — replace with your actual keys ─────────────────
    private static final String RAZORPAY_KEY_ID_ENV = "RAZORPAY_KEY_ID";
    private static final String RAZORPAY_KEY_SECRET_ENV = "RAZORPAY_KEY_SECRET";

    private static final String RAZORPAY_ORDERS_URL = "https://api.razorpay.com/v1/orders";

    // ── SQL ───────────────────────────────────────────────────────────────────

    private static final String SQL_INSERT_PAYMENT =
            "INSERT INTO payments " +
                    "  (booking_id, booking_ref, razorpay_order_id, razorpay_payment_id, " +
                    "   razorpay_signature, amount_paise, currency, payment_status, " +
                    "   failure_reason, payment_method) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?)";

    private static final String SQL_FIND_CREATED_ORDER =
            "SELECT p.id, p.booking_id, p.amount_paise, p.payment_status, p.razorpay_payment_id, b.total_amount, b.status " +
                    "FROM payments p JOIN bookings b ON b.id = p.booking_id " +
                    "WHERE p.razorpay_order_id = ? AND p.booking_ref = ? " +
                    "AND p.currency = 'INR' AND p.payment_status IN ('created','captured') FOR UPDATE";

    private static final String SQL_CAPTURE_PAYMENT =
            "UPDATE payments SET razorpay_payment_id = ?, razorpay_signature = ?, " +
                    "payment_status = 'captured', captured_at = COALESCE(captured_at, NOW()), " +
                    "failure_reason = NULL, updated_at = NOW() " +
                    "WHERE id = ? AND payment_status = 'created'";

    private static final String SQL_CONFIRM_BOOKING =
            "UPDATE bookings SET status = 'Confirmed', updated_at = NOW() " +
                    "WHERE id = ? AND status = 'Pending'";

    private static final String SQL_GET_BOOKING_DETAILS =
            "SELECT b.id, b.guest_first, b.guest_last, b.guest_email, b.guest_phone, " +
                    "       b.checkin_date, b.checkout_date, b.nights, b.total_amount, " +
                    "       r.room_type, r.room_number " +
                    "FROM   bookings b " +
                    "JOIN   rooms    r ON b.room_id = r.id " +
                    "WHERE  b.booking_ref = ? LIMIT 1";

    // ── GET — redirect to booking if called directly ──────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String action = sanitise(req.getParameter("action"));

        if ("createOrder".equals(action)) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Order creation requires POST.");
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/booking.jsp");
    }

    // ── POST ──────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = sanitise(req.getParameter("action"));

        if ("createOrder".equals(action) || "verify".equals(action)) {
            HttpSession session = req.getSession(false);
            if (session == null || !validCsrf(session, req.getParameter("_csrf"))) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or expired form token.");
                return;
            }
        }

        switch (action) {
            case "createOrder": handleCreateOrderAjax(req, resp); break;
            case "verify":      handleVerify(req, resp);          break;
            case "failed":      handleFailed(req, resp);           break;
            default:
                resp.sendRedirect(req.getContextPath() + "/booking.jsp");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ACTION: createOrder
    // Called by payment.jsp via JS fetch to get a Razorpay order_id.
    // Returns JSON: { "orderId": "order_XXXXXXXXXXXX" }
    //         or : { "error": "reason" }
    // ─────────────────────────────────────────────────────────────────────────

    private void handleCreateOrderAjax(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession(false);
        String bookingRef = sanitise(req.getParameter("bookingRef"));
        String sessionRef = session == null ? "" : String.valueOf(session.getAttribute("pendingBookingRef"));
        Integer sessionBookingId = session == null ? null : (Integer) session.getAttribute("pendingBookingId");
        if (bookingRef.isEmpty() || !bookingRef.equals(sessionRef) || sessionBookingId == null) {
            resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
            resp.getWriter().write("{\"error\":\"No pending booking is available for payment.\"}");
            return;
        }
        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                BigDecimal amount;
                try (PreparedStatement booking = conn.prepareStatement(
                        "SELECT id,total_amount FROM bookings WHERE booking_ref=? AND status='Pending' FOR UPDATE")) {
                    booking.setString(1, bookingRef);
                    try (ResultSet rs = booking.executeQuery()) {
                        if (!rs.next() || rs.getInt("id") != sessionBookingId) {
                            conn.rollback();
                            resp.setStatus(HttpServletResponse.SC_CONFLICT);
                            resp.getWriter().write("{\"error\":\"Booking is no longer pending.\"}");
                            return;
                        }
                        amount = rs.getBigDecimal("total_amount");
                    }
                }
                long amountPaise = amountToPaise(amount);
                String orderId = null;
                try (PreparedStatement existing = conn.prepareStatement(
                        "SELECT razorpay_order_id,amount_paise FROM payments " +
                        "WHERE booking_id=? AND payment_status='created' AND razorpay_order_id IS NOT NULL " +
                        "ORDER BY id DESC LIMIT 1 FOR UPDATE")) {
                    existing.setInt(1, sessionBookingId);
                    try (ResultSet rs = existing.executeQuery()) {
                        if (rs.next()) {
                            if (rs.getLong("amount_paise") != amountPaise)
                                throw new SQLException("Existing order amount does not match booking total.");
                            orderId = rs.getString("razorpay_order_id");
                        }
                    }
                }
                if (orderId == null) {
                    orderId = createRazorpayOrder(amountPaise, bookingRef);
                    try (PreparedStatement insert = conn.prepareStatement(SQL_INSERT_PAYMENT)) {
                        insert.setInt(1, sessionBookingId);
                        insert.setString(2, bookingRef);
                        insert.setString(3, orderId);
                        insert.setNull(4, java.sql.Types.VARCHAR);
                        insert.setNull(5, java.sql.Types.VARCHAR);
                        insert.setLong(6, amountPaise);
                        insert.setString(7, "INR");
                        insert.setString(8, "created");
                        insert.setNull(9, java.sql.Types.VARCHAR);
                        insert.setNull(10, java.sql.Types.VARCHAR);
                        insert.executeUpdate();
                    }
                }
                conn.commit();
                resp.getWriter().write("{\"orderId\":\"" + escJson(orderId) + "\",\"amount\":" + amountPaise + ",\"currency\":\"INR\"}");
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "createOrder failed for " + bookingRef, e);
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().write("{\"error\":\"Payment service is unavailable. Please try again later.\"}");
        }
    }


    private void handleVerify(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String orderId = sanitise(req.getParameter("razorpay_order_id"));
        String paymentId = sanitise(req.getParameter("razorpay_payment_id"));
        String signature = sanitise(req.getParameter("razorpay_signature"));
        HttpSession session = req.getSession(false);
        String bookingRef = session == null ? "" : String.valueOf(session.getAttribute("pendingBookingRef"));
        if (bookingRef.isEmpty() || orderId.isEmpty() || paymentId.isEmpty() || signature.isEmpty()
                || !verifySignature(orderId, paymentId, signature)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Payment verification failed.");
            return;
        }
        BookingDetails bd;
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);
            int paymentRowId;
            int bookingId;
            long storedPaise;
            BigDecimal bookingTotal;
            boolean alreadyCaptured;
            try (PreparedStatement ps = conn.prepareStatement(SQL_FIND_CREATED_ORDER)) {
                ps.setString(1, orderId);
                ps.setString(2, bookingRef);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new SQLException("Order is not linked to this booking.");
                    paymentRowId = rs.getInt("id");
                    bookingId = rs.getInt("booking_id");
                    storedPaise = rs.getLong("amount_paise");
                    bookingTotal = rs.getBigDecimal("total_amount");
                    alreadyCaptured = "captured".equalsIgnoreCase(rs.getString("payment_status"));
                    String bookingStatus = rs.getString("status");
                    if ((!alreadyCaptured && !"Pending".equals(bookingStatus))
                            || (alreadyCaptured && !"Confirmed".equals(bookingStatus))) {
                        throw new SQLException("Order or booking is not in a payable state.");
                    }
                    if (alreadyCaptured && !paymentId.equals(rs.getString("razorpay_payment_id"))) {
                        throw new SQLException("Order was captured with a different payment ID");
                    }
                }
            }
            if (storedPaise != amountToPaise(bookingTotal)) throw new SQLException("Payment amount mismatch");
            if (!alreadyCaptured) {
                try (PreparedStatement ps = conn.prepareStatement(SQL_CAPTURE_PAYMENT)) {
                    ps.setString(1, paymentId); ps.setString(2, signature); ps.setInt(3, paymentRowId);
                    if (ps.executeUpdate() != 1) throw new SQLException("Payment order already processed");
                }
                try (PreparedStatement ps = conn.prepareStatement(SQL_CONFIRM_BOOKING)) {
                    ps.setInt(1, bookingId);
                    if (ps.executeUpdate() != 1) throw new SQLException("Booking is no longer pending");
                }
            }
            conn.commit();
            bd = fetchBookingDetails(bookingRef);
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Payment verification DB error for " + bookingRef, e);
            if (conn != null) try { conn.rollback(); } catch (SQLException ignored) { }
            req.setAttribute("error", "Payment could not be confirmed. Contact support with payment ID: " + paymentId);
            req.getRequestDispatcher("/payment-failed.jsp").forward(req, resp);
            return;
        } finally { DBConnection.close(conn); }
        clearPendingSession(req);
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy");
        NumberFormat fmt = NumberFormat.getInstance(new Locale("en", "IN"));
        req.setAttribute("bookingRef", bookingRef);
        req.setAttribute("paymentId", paymentId);
        req.setAttribute("roomType", bd == null ? "?" : bd.roomType);
        req.setAttribute("checkinFmt", bd == null ? "?" : bd.checkin.format(dtf));
        req.setAttribute("checkoutFmt", bd == null ? "?" : bd.checkout.format(dtf));
        req.setAttribute("nights", bd == null ? 0 : bd.nights);
        req.setAttribute("guestName", bd == null ? "?" : bd.guestName);
        req.setAttribute("guestEmail", bd == null ? "?" : bd.guestEmail);
        req.setAttribute("amountFormatted", bd == null ? "?" : fmt.format(bd.totalAmount));
        req.getRequestDispatcher("/payment-success.jsp").forward(req, resp);
    }


    private void handleFailed(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        String bookingRef = session == null ? "" : String.valueOf(session.getAttribute("pendingBookingRef"));
        String errorCode = sanitise(req.getParameter("error_code"));
        String errorDesc = sanitise(req.getParameter("error_desc"));
        if (errorDesc.isEmpty()) errorDesc = "Payment was declined.";
        BookingDetails bd = bookingRef.isEmpty() ? null : fetchBookingDetails(bookingRef);
        NumberFormat fmt = NumberFormat.getInstance(new Locale("en", "IN"));
        req.setAttribute("bookingRef", bookingRef);
        req.setAttribute("errorCode", errorCode);
        req.setAttribute("errorDesc", errorDesc);
        req.setAttribute("guestEmail", bd == null ? "?" : bd.guestEmail);
        req.setAttribute("amountFormatted", bd == null ? "?" : fmt.format(bd.totalAmount));
        req.getRequestDispatcher("/payment-failed.jsp").forward(req, resp);
    }


    /**
     * Creates a Razorpay order via the REST API and returns the order_id.
     *
     * <p>Uses {@link HttpURLConnection} — no extra JAR required.
     *
     * @param amountPaise amount in Indian paise (e.g. 5040000 for ₹50,400)
     * @param receipt     booking reference used as the Razorpay receipt field
     * @return Razorpay order_id (e.g. "order_OFj93jfkslf")
     * @throws Exception if the API call fails or returns a non-200 status
     */
    private String createRazorpayOrder(long amountPaise, String receipt) throws Exception {

        String keyId = requiredCredential(RAZORPAY_KEY_ID_ENV);
        String keySecret = requiredCredential(RAZORPAY_KEY_SECRET_ENV);
        if (!keyId.matches("rzp_(test|live)_[A-Za-z0-9]+")) {
            throw new IllegalStateException("RAZORPAY_KEY_ID has an invalid format.");
        }

        URL url = new URL(RAZORPAY_ORDERS_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();

        // Basic Auth: Base64(keyId:keySecret)
        String credentials = keyId + ":" + keySecret;
        String basicAuth = "Basic " + Base64.getEncoder()
                .encodeToString(credentials.getBytes(StandardCharsets.UTF_8));

        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization",  basicAuth);
        conn.setRequestProperty("Content-Type",   "application/json");
        conn.setRequestProperty("Accept",         "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10_000);
        conn.setReadTimeout(15_000);

        // Request body
        String body = "{"
                + "\"amount\":"   + amountPaise + ","
                + "\"currency\":\"INR\","
                + "\"receipt\":\""  + escapeJson(receipt) + "\","
                + "\"payment_capture\":1"
                + "}";

        try (OutputStream os = conn.getOutputStream()) {
            os.write(body.getBytes(StandardCharsets.UTF_8));
        }

        int status = conn.getResponseCode();
        StringBuilder sb = new StringBuilder();

        try (BufferedReader br = new BufferedReader(new InputStreamReader(
                status < 400 ? conn.getInputStream() : conn.getErrorStream(),
                StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
        }

        String response = sb.toString();

        if (status != 200 && status != 201) {
            throw new Exception("Razorpay API returned HTTP " + status + ": " + response);
        }

        // Extract order id from JSON response (no library required)
        // Response: { "id": "order_XXXXXXXXXXXX", ... }
        String orderId = extractJsonString(response, "id");
        if (orderId == null || orderId.isEmpty()) {
            throw new Exception("Could not extract order id from Razorpay response: " + response);
        }

        return orderId;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Signature verification
    // Razorpay signature = HMAC_SHA256(orderId + "|" + paymentId, keySecret)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Verifies the Razorpay payment signature using HMAC-SHA256.
     *
     * <p>The payload to sign is {@code "<order_id>|<payment_id>"}.
     * The expected signature is computed using the Razorpay Key Secret and
     * compared to the signature sent by Razorpay using a constant-time
     * comparison to prevent timing attacks.
     *
     * @param orderId   razorpay_order_id
     * @param paymentId razorpay_payment_id
     * @param signature razorpay_signature from the JS response
     * @return {@code true} if signatures match; {@code false} otherwise
     */
    private boolean verifySignature(String orderId, String paymentId, String signature) {
        try {
            String keySecret = requiredCredential(RAZORPAY_KEY_SECRET_ENV);
            String payload = orderId + "|" + paymentId;

            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec keySpec = new SecretKeySpec(
                    keySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(keySpec);

            byte[] hashBytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));

            // Convert to lowercase hex
            StringBuilder hexSb = new StringBuilder(hashBytes.length * 2);
            for (byte b : hashBytes) {
                hexSb.append(String.format("%02x", b));
            }
            String expectedSignature = hexSb.toString();

            // Constant-time comparison to prevent timing attacks
            return constantTimeEquals(expectedSignature, signature);

        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Signature verification error", e);
            return false;
        }
    }

    private static String requiredCredential(String name) {
        String value = System.getenv(name);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalStateException("Required payment environment variable is not set: " + name);
        }
        return value.trim();
    }

    private static boolean validCsrf(HttpSession session, String supplied) {
        String expected = (String) session.getAttribute("csrfToken");
        return expected != null && supplied != null && java.security.MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Constant-time string comparison — prevents timing side-channel attacks.
     * Returns {@code true} only if both strings are equal in length and content.
     */
    private static boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null) return false;
        if (a.length() != b.length()) return false;
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= (a.charAt(i) ^ b.charAt(i));
        }
        return result == 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    /** Fetch booking + room details for display on success/failure pages. */
    private BookingDetails fetchBookingDetails(String bookingRef) {
        if (bookingRef == null || bookingRef.isEmpty()) return null;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_GET_BOOKING_DETAILS)) {

            ps.setString(1, bookingRef);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                BookingDetails bd = new BookingDetails();
                bd.id          = rs.getInt("id");
                bd.guestName   = rs.getString("guest_first") + " " + rs.getString("guest_last");
                bd.guestEmail  = rs.getString("guest_email");
                bd.guestPhone  = rs.getString("guest_phone");
                bd.checkin     = rs.getDate("checkin_date").toLocalDate();
                bd.checkout    = rs.getDate("checkout_date").toLocalDate();
                bd.nights      = rs.getLong("nights");
                bd.totalAmount = rs.getBigDecimal("total_amount");
                bd.roomType    = rs.getString("room_type");
                bd.roomNumber  = rs.getString("room_number");
                return bd;
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "fetchBookingDetails failed for " + bookingRef, e);
        }
        return null;
    }

    /** Redirect to payment-failed.jsp via sendRedirect (GET) with attributes via session. */
    private void redirectToFailed(HttpServletResponse resp, HttpServletRequest req,
                                  String bookingRef, String code, String desc)
            throws IOException {
        HttpSession session = req.getSession(true);
        session.setAttribute("failedBookingRef", bookingRef);
        session.setAttribute("failedCode",       code);
        session.setAttribute("failedDesc",       desc);
        resp.sendRedirect(req.getContextPath() + "/payment-failed.jsp");
    }

    /** Remove pending booking attributes from session after payment completes. */
    private void clearPendingSession(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return;
        String[] keys = {
                "pendingBookingRef", "pendingRoomType", "pendingRoomNumber",
                "pendingCheckin",    "pendingCheckout", "pendingNights",
                "pendingTotal",      "pendingGuestName","pendingGuestEmail",
                "pendingGuestPhone", "pendingBookingId"
        };
        for (String key : keys) session.removeAttribute(key);
    }

    /**
     * Extracts a JSON string value for the given key from a flat JSON object.
     * e.g. extractJsonString("{\"id\":\"order_abc\"}", "id") → "order_abc"
     * This avoids requiring org.json / Gson for a single field extraction.
     */
    private static String extractJsonString(String json, String key) {
        String search = "\"" + key + "\":\"";
        int start = json.indexOf(search);
        if (start < 0) return null;
        start += search.length();
        int end = json.indexOf("\"", start);
        if (end < 0) return null;
        return json.substring(start, end);
    }

    /** Escapes special characters for safe embedding in a JSON string value. */
    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }

    private static int parseIntSafe(String s, int fallback) {
        try { return Integer.parseInt(sanitise(s)); }
        catch (NumberFormatException e) { return fallback; }
    }

    private static long amountToPaise(BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) throw new IllegalArgumentException("Invalid booking amount");
        long paise = amount.movePointRight(2).longValueExact();
        if (paise > Integer.MAX_VALUE) throw new IllegalArgumentException("Booking amount exceeds supported limit");
        return paise;
    }

    private static String escJson(String value) {
        return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String sanitise(String s) {
        return (s == null) ? "" : s.trim();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Value object for booking details
    // ─────────────────────────────────────────────────────────────────────────

    private static class BookingDetails {
        int            id;
        String         guestName;
        String         guestEmail;
        String         guestPhone;
        java.time.LocalDate checkin;
        java.time.LocalDate checkout;
        long           nights;
        BigDecimal     totalAmount;
        String         roomType;
        String         roomNumber;
    }
}
