package com.hotel.servlet;

import com.hotel.util.DBConnection;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Releases unpaid reservations after 30 minutes so they cannot block inventory forever. */
@WebListener
public class PendingBookingExpiryListener implements ServletContextListener {
    private static final Logger LOG = Logger.getLogger(PendingBookingExpiryListener.class.getName());
    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent event) {
        scheduler = Executors.newSingleThreadScheduledExecutor(task -> {
            Thread thread = new Thread(task, "pending-booking-expiry");
            thread.setDaemon(true);
            return thread;
        });
        scheduler.scheduleWithFixedDelay(this::expire, 1, 5, TimeUnit.MINUTES);
        LOG.info("Pending booking expiry scheduler started; database connections use the configured DBConnection provider.");
    }

    private void expire() {
        try (Connection connection = DBConnection.getConnection()) {
            connection.setAutoCommit(false);
            try {
                try (PreparedStatement payments = connection.prepareStatement(
                        "UPDATE payments p JOIN bookings b ON b.id=p.booking_id " +
                        "SET p.payment_status='failed',p.failure_reason='Booking payment window expired',p.updated_at=NOW() " +
                        "WHERE b.status='Pending' AND b.created_at < DATE_SUB(NOW(), INTERVAL 30 MINUTE) " +
                        "AND p.payment_status='created'")) {
                    payments.executeUpdate();
                }
                int expired;
                try (PreparedStatement bookings = connection.prepareStatement(
                        "UPDATE bookings SET status='Cancelled',updated_at=NOW() " +
                        "WHERE status='Pending' AND created_at < DATE_SUB(NOW(), INTERVAL 30 MINUTE)")) {
                    expired = bookings.executeUpdate();
                }
                connection.commit();
                if (expired > 0) LOG.info("Expired " + expired + " unpaid booking(s).");
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            }
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "Could not expire pending bookings; will retry on next run.", e);
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        if (scheduler != null) scheduler.shutdownNow();
    }
}
