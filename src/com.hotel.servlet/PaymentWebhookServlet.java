package com.hotel.servlet;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hotel.util.DBConnection;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Confirms captured Razorpay payments from signed provider webhooks. */
@WebServlet("/payment-webhook")
public class PaymentWebhookServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final Logger LOG = Logger.getLogger(PaymentWebhookServlet.class.getName());
    private static final ObjectMapper JSON = new ObjectMapper();
    private static final int MAX_BODY_BYTES = 1_048_576;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        byte[] body;
        try {
            body = readBody(request);
        } catch (IOException tooLarge) {
            response.sendError(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
            return;
        }
        String secret = System.getenv("RAZORPAY_WEBHOOK_SECRET");
        String signature = request.getHeader("X-Razorpay-Signature");
        if (secret == null || secret.isEmpty() || !validSignature(body, signature, secret)) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        JsonNode root;
        try {
            root = JSON.readTree(body);
        } catch (Exception malformed) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        if (!"payment.captured".equals(root.path("event").asText())) {
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return;
        }
        JsonNode payment = root.path("payload").path("payment").path("entity");
        String orderId = payment.path("order_id").asText("");
        String paymentId = payment.path("id").asText("");
        String currency = payment.path("currency").asText("");
        long amount = payment.path("amount").asLong(-1L);
        if (orderId.isEmpty() || paymentId.isEmpty() || amount < 0 || !"INR".equals(currency)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            reconcile(orderId, paymentId, amount);
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
        } catch (SQLException e) {
            LOG.log(Level.SEVERE, "Could not reconcile signed Razorpay event for order " + orderId, e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    private static void reconcile(String orderId, String paymentId, long amount) throws SQLException {
        try (Connection connection = DBConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                int paymentRowId;
                int bookingId;
                long expectedAmount;
                String paymentStatus;
                String storedPaymentId;
                String bookingStatus;
                try (PreparedStatement query = connection.prepareStatement(
                        "SELECT p.id,p.booking_id,p.amount_paise,p.payment_status,p.razorpay_payment_id,b.status " +
                        "FROM payments p JOIN bookings b ON b.id=p.booking_id " +
                        "WHERE p.razorpay_order_id=? FOR UPDATE")) {
                    query.setString(1, orderId);
                    try (ResultSet row = query.executeQuery()) {
                        if (!row.next()) throw new SQLException("Webhook order is not present in the application.");
                        paymentRowId = row.getInt("id");
                        bookingId = row.getInt("booking_id");
                        expectedAmount = row.getLong("amount_paise");
                        paymentStatus = row.getString("payment_status");
                        storedPaymentId = row.getString("razorpay_payment_id");
                        bookingStatus = row.getString("status");
                    }
                }
                if (expectedAmount != amount) throw new SQLException("Webhook amount does not match stored order amount.");
                if ("captured".equalsIgnoreCase(paymentStatus)) {
                    if (!paymentId.equals(storedPaymentId)) throw new SQLException("Captured order has a different payment id.");
                    connection.commit();
                    return;
                }
                if (!"created".equalsIgnoreCase(paymentStatus))
                    throw new SQLException("Payment row is not in a capturable state.");
                try (PreparedStatement update = connection.prepareStatement(
                        "UPDATE payments SET razorpay_payment_id=?,payment_status='captured',failure_reason=NULL,updated_at=NOW() " +
                        "WHERE id=? AND payment_status='created'")) {
                    update.setString(1, paymentId);
                    update.setInt(2, paymentRowId);
                    if (update.executeUpdate() != 1) throw new SQLException("Payment row changed during reconciliation.");
                }
                if ("Pending".equals(bookingStatus)) {
                    try (PreparedStatement update = connection.prepareStatement(
                            "UPDATE bookings SET status='Confirmed',updated_at=NOW() WHERE id=? AND status='Pending'")) {
                        update.setInt(1, bookingId);
                        if (update.executeUpdate() != 1) throw new SQLException("Booking changed during reconciliation.");
                    }
                } else {
                    LOG.severe("Captured payment " + paymentId + " belongs to booking " + bookingId +
                            " in status " + bookingStatus + "; manual refund/review may be required.");
                }
                connection.commit();
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        }
    }

    private static boolean validSignature(byte[] body, String supplied, String secret) {
        if (supplied == null || !supplied.matches("[0-9a-fA-F]{64}")) return false;
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] expected = toHex(mac.doFinal(body)).getBytes(StandardCharsets.US_ASCII);
            return MessageDigest.isEqual(expected, supplied.toLowerCase(java.util.Locale.ROOT)
                    .getBytes(StandardCharsets.US_ASCII));
        } catch (Exception e) {
            return false;
        }
    }

    private static byte[] readBody(HttpServletRequest request) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int count;
        while ((count = request.getInputStream().read(buffer)) != -1) {
            if (output.size() + count > MAX_BODY_BYTES) throw new IOException("Webhook body too large");
            output.write(buffer, 0, count);
        }
        return output.toByteArray();
    }

    private static String toHex(byte[] bytes) {
        StringBuilder value = new StringBuilder(bytes.length * 2);
        for (byte item : bytes) value.append(String.format("%02x", item & 0xff));
        return value.toString();
    }
}
