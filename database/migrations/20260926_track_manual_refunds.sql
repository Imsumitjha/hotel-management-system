-- Apply once to an existing database before deploying the manual refund recording flow.
-- Refunds are processed and verified in the Razorpay dashboard first; the admin UI
-- records the completed Razorpay refund ID and cancels the booking.
ALTER TABLE payments
    ADD COLUMN refund_reference VARCHAR(60) DEFAULT NULL,
    ADD COLUMN refund_processed_at TIMESTAMP NULL DEFAULT NULL,
    ADD UNIQUE KEY uk_pay_refund_ref (refund_reference);
