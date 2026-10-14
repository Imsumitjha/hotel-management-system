-- Run once on an existing database before deploying payment-event reports.
-- Existing successful payments can only be approximated using updated_at;
-- refunded legacy rows have no reliable capture timestamp and remain NULL.
ALTER TABLE payments
    ADD COLUMN captured_at TIMESTAMP NULL DEFAULT NULL AFTER payment_status,
    ADD INDEX idx_pay_captured_at (captured_at),
    ADD INDEX idx_pay_refund_time (payment_status, refund_processed_at),
    DROP INDEX idx_pay_status;

ALTER TABLE bookings
    ADD INDEX idx_booking_created (created_at);

UPDATE payments
SET captured_at = updated_at
WHERE payment_status = 'captured'
  AND captured_at IS NULL;
