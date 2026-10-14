-- ================================================================
--  Grand Horizon Hotel — Complete Database Schema
--  MySQL 8.0+  |  Engine: InnoDB  |  Charset: utf8mb4
--
--  Tables (8, in FK-safe creation order):
--    1.  users
--    2.  rooms
--    3.  bookings
--    4.  payments
--    5.  contact_messages
--    6.  reviews
--    7.  audit_log
--    8.  password_reset_tokens
--
--  Sections:
--    A.  Table definitions
--    B.  Seed data
--    C.  Stored procedures
--    D.  Views  (10 total)
--    E.  Optional event scheduler
--
--  How to run:
--    mysql -u root -p < hotel.sql
--  Or import via MySQL Workbench / DBeaver / phpMyAdmin.
-- ================================================================

-- Non-destructive first-time setup. This script does not remove existing data.
CREATE DATABASE IF NOT EXISTS grand_horizon
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE grand_horizon;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ================================================================
--  A. TABLE DEFINITIONS
-- ================================================================

-- ----------------------------------------------------------------
--  1. USERS
--     Both guest accounts and admin staff.
--     Extended columns cover profile.jsp, manage-users.jsp and
--     notification preferences.
-- ----------------------------------------------------------------
CREATE TABLE users (
                       id               INT           NOT NULL AUTO_INCREMENT,

    -- Identity
                       first_name       VARCHAR(60)   NOT NULL,
                       last_name        VARCHAR(60)   NOT NULL,
                       email            VARCHAR(150)  NOT NULL,
                       phone            VARCHAR(20)   DEFAULT NULL,
                       password_hash    VARCHAR(255)  NOT NULL,          -- PBKDF2 format from PasswordUtil
                       role             ENUM('guest','admin')
                                                      NOT NULL DEFAULT 'guest',

    -- Profile (profile.jsp form fields)
                       dob              DATE          DEFAULT NULL,
                       address          VARCHAR(255)  DEFAULT NULL,
                       city             VARCHAR(80)   DEFAULT NULL,
                       country          VARCHAR(60)   NOT NULL DEFAULT 'India',

    -- Notification preferences (profile.jsp preferences tab)
                       notif_booking    TINYINT(1)    NOT NULL DEFAULT 1,
                       notif_reminder   TINYINT(1)    NOT NULL DEFAULT 1,
                       notif_promos     TINYINT(1)    NOT NULL DEFAULT 0,
                       notif_sms        TINYINT(1)    NOT NULL DEFAULT 0,

    -- Display preferences
                       language_pref    VARCHAR(20)   NOT NULL DEFAULT 'English',
                       currency_pref    VARCHAR(10)   NOT NULL DEFAULT 'INR',

    -- Account status (manage-users.jsp)
                       is_suspended     TINYINT(1)    NOT NULL DEFAULT 0,
                       suspension_note  VARCHAR(255)  DEFAULT NULL,

                       created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,

                       PRIMARY KEY (id),
                       UNIQUE KEY  uk_users_email      (email),
                       INDEX       idx_users_role      (role),
                       INDEX       idx_users_suspended (is_suspended)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  2. ROOMS
--     Master catalogue of all hotel rooms.
-- ----------------------------------------------------------------
CREATE TABLE rooms (
                       id             INT           NOT NULL AUTO_INCREMENT,
                       room_number    VARCHAR(10)   NOT NULL,
                       room_type      ENUM(
                           'Deluxe Room',
                           'Twin Room',
                           'Family Suite',
                           'Junior Suite',
                           'Executive Suite',
                           'Presidential Suite'
                           ) NOT NULL,
                       floor          VARCHAR(20)   NOT NULL,
                       capacity       VARCHAR(40)   NOT NULL DEFAULT '2 Adults',
                       rate_per_night DECIMAL(10,2) NOT NULL,
                       description    TEXT          DEFAULT NULL,
                       status         ENUM('Available','Occupied','Maintenance')
                                                    NOT NULL DEFAULT 'Available',

                       created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                           ON UPDATE CURRENT_TIMESTAMP,

                       PRIMARY KEY (id),
                       UNIQUE KEY  uk_rooms_number  (room_number),
                       INDEX       idx_rooms_status (status),
                       INDEX       idx_rooms_type   (room_type)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  3. BOOKINGS
--     One row per reservation.
--     Booking is created with status='Pending' by BookingServlet.
--     PaymentServlet updates it to 'Confirmed' after payment.
--     walk-in guests: user_id = NULL.
-- ----------------------------------------------------------------
CREATE TABLE bookings (
                          id               INT           NOT NULL AUTO_INCREMENT,
                          booking_ref      VARCHAR(20)   NOT NULL,           -- e.g. GH-2401
                          user_id          INT           DEFAULT NULL,       -- NULL = walk-in

    -- Room snapshot at time of booking
                          room_id          INT           NOT NULL,

    -- Guest contact (denormalised — supports walk-ins)
                          guest_first      VARCHAR(60)   NOT NULL,
                          guest_last       VARCHAR(60)   NOT NULL,
                          guest_email      VARCHAR(150)  NOT NULL,
                          guest_phone      VARCHAR(20)   DEFAULT NULL,

    -- Stay dates
                          checkin_date     DATE          NOT NULL,
                          checkout_date    DATE          NOT NULL,
                          adults           TINYINT       NOT NULL DEFAULT 1,
                          children         TINYINT       NOT NULL DEFAULT 0,
                          nights           TINYINT       NOT NULL,

    -- Pricing snapshot (locked at booking time)
                          rate_per_night   DECIMAL(10,2) NOT NULL,
                          subtotal         DECIMAL(10,2) NOT NULL,
                          tax_amount       DECIMAL(10,2) NOT NULL,           -- 12% / 18% GST
                          total_amount     DECIMAL(10,2) NOT NULL,

                          special_requests TEXT          DEFAULT NULL,
                          status           ENUM(
                              'Pending',      -- created, awaiting payment
                              'Confirmed',    -- payment captured
                              'Cancelled',    -- cancelled by guest or admin
                              'Checked-In',   -- guest has arrived
                              'Checked-Out'   -- stay complete
                              ) NOT NULL DEFAULT 'Pending',

                          created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          updated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,

                          PRIMARY KEY (id),
                          UNIQUE KEY  uk_booking_ref     (booking_ref),
                          INDEX       idx_booking_user   (user_id),
                          INDEX       idx_booking_room   (room_id),
                          INDEX       idx_booking_status (status),
                          INDEX       idx_booking_dates  (checkin_date, checkout_date),
                          INDEX       idx_booking_created (created_at),

                          CONSTRAINT fk_booking_user FOREIGN KEY (user_id)
                              REFERENCES users (id) ON DELETE SET NULL,
                          CONSTRAINT fk_booking_room FOREIGN KEY (room_id)
                              REFERENCES rooms (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  4. PAYMENTS
--     One row per Razorpay transaction attempt.
--     A booking may have multiple rows (e.g. one failed, one
--     captured). The successful row has status='captured' and a
--     non-null razorpay_payment_id.
--     amount_paise stores the amount in Indian paise (INR × 100)
--     to avoid floating-point rounding issues.
-- ----------------------------------------------------------------
CREATE TABLE payments (
                          id                   INT           NOT NULL AUTO_INCREMENT,
                          booking_id           INT           NOT NULL,
                          booking_ref          VARCHAR(20)   NOT NULL,

    -- Razorpay identifiers
                          razorpay_order_id    VARCHAR(60)   DEFAULT NULL,   -- order_XXXXXXXXXXXX
                          razorpay_payment_id  VARCHAR(60)   DEFAULT NULL,   -- pay_XXXXXXXXXXXX
                          razorpay_signature   VARCHAR(255)  DEFAULT NULL,   -- HMAC-SHA256 hex

    -- Amount
                          amount_paise         INT           NOT NULL,        -- e.g. 17002240 for ₹1,70,022.40
                          currency             VARCHAR(5)    NOT NULL DEFAULT 'INR',

    -- Outcome
                          payment_status       ENUM(
                              'created',    -- order created, user not yet paid
                              'attempted',  -- user attempted but not captured
                              'captured',   -- payment successful
                              'failed',     -- payment declined / timed out
                              'refunded'    -- refund processed
                              ) NOT NULL DEFAULT 'created',
                          captured_at          TIMESTAMP     NULL DEFAULT NULL,
                          failure_reason       VARCHAR(255)  DEFAULT NULL,   -- Razorpay error string
                          payment_method       VARCHAR(40)   DEFAULT NULL,   -- card/upi/netbanking/wallet
                          refund_reference     VARCHAR(60)   DEFAULT NULL,
                          refund_processed_at  TIMESTAMP     NULL DEFAULT NULL,

                          created_at           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                          updated_at           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,

                          PRIMARY KEY (id),
                          UNIQUE KEY  uk_pay_razorpay_id  (razorpay_payment_id),  -- NULL allowed, unique when set
                          UNIQUE KEY  uk_pay_refund_ref  (refund_reference),
                          INDEX       idx_pay_booking     (booking_id),
                          INDEX       idx_pay_order       (razorpay_order_id),
                          INDEX       idx_pay_captured_at (captured_at),
                          INDEX       idx_pay_refund_time (payment_status, refund_processed_at),
                          INDEX       idx_pay_ref         (booking_ref),

                          CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id)
                              REFERENCES bookings (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  5. CONTACT_MESSAGES
--     Stores contact.jsp form submissions.
--     ip_address column is required by ContactServlet's
--     SQL_RATE_CHECK_IP rate-limiting query.
-- ----------------------------------------------------------------
CREATE TABLE contact_messages (
                                  id         INT          NOT NULL AUTO_INCREMENT,
                                  name       VARCHAR(120) NOT NULL,
                                  email      VARCHAR(150) NOT NULL,
                                  phone      VARCHAR(20)  DEFAULT NULL,
                                  subject    VARCHAR(100) NOT NULL DEFAULT 'General Inquiry',
                                  message    TEXT         NOT NULL,
                                  ip_address VARCHAR(45)  DEFAULT NULL,              -- IPv4 or IPv6
                                  is_read    TINYINT(1)   NOT NULL DEFAULT 0,
                                  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                  PRIMARY KEY (id),
                                  INDEX idx_contact_read  (is_read),
                                  INDEX idx_contact_ip    (ip_address),
                                  INDEX idx_contact_email (email)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  6. REVIEWS
--     One review per booking (UNIQUE on booking_id).
--     ReviewServlet inserts with status='Pending'.
--     Admin approves/rejects via ReviewServlet?action=moderate.
-- ----------------------------------------------------------------
CREATE TABLE reviews (
                         id          INT          NOT NULL AUTO_INCREMENT,
                         booking_id  INT          NOT NULL,
                         room_id     INT          NOT NULL,
                         user_id     INT          NOT NULL,
                         rating      TINYINT      NOT NULL,                 -- 1–5 stars
                         title       VARCHAR(120) DEFAULT NULL,
                         body        TEXT         NOT NULL,
                         status      ENUM('Pending','Approved','Rejected')
                                                  NOT NULL DEFAULT 'Pending',
                         admin_note  VARCHAR(255) DEFAULT NULL,

                         created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                             ON UPDATE CURRENT_TIMESTAMP,

                         PRIMARY KEY (id),
                         UNIQUE KEY  uk_review_booking (booking_id),
                         INDEX       idx_review_room   (room_id),
                         INDEX       idx_review_user   (user_id),
                         INDEX       idx_review_status (status),

                         CONSTRAINT fk_review_booking FOREIGN KEY (booking_id)
                             REFERENCES bookings (id) ON DELETE CASCADE,
                         CONSTRAINT fk_review_room FOREIGN KEY (room_id)
                             REFERENCES rooms    (id) ON DELETE CASCADE,
                         CONSTRAINT fk_review_user FOREIGN KEY (user_id)
                             REFERENCES users    (id) ON DELETE CASCADE,

                         CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  7. AUDIT_LOG
--     Written best-effort by LogoutServlet (action=LOGOUT) and
--     LoginServlet (action=LOGIN). A DB failure here must never
--     block a login or logout.
-- ----------------------------------------------------------------
CREATE TABLE audit_log (
                           id         INT          NOT NULL AUTO_INCREMENT,
                           user_id    INT          DEFAULT NULL,
                           user_email VARCHAR(150) DEFAULT NULL,
                           action     VARCHAR(50)  NOT NULL,                  -- LOGIN | LOGOUT
                           ip_address VARCHAR(45)  DEFAULT NULL,
                           user_agent VARCHAR(255) DEFAULT NULL,
                           created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

                           PRIMARY KEY (id),
                           INDEX idx_audit_user   (user_id),
                           INDEX idx_audit_action (action),
                           INDEX idx_audit_time   (created_at)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------
--  8. PASSWORD_RESET_TOKENS
--     ForgotPasswordServlet inserts one token per user (deletes
--     any previous one first). ResetPasswordServlet validates,
--     then stamps used_at to prevent replay within expiry window.
-- ----------------------------------------------------------------
CREATE TABLE password_reset_tokens (
                                       id         INT          NOT NULL AUTO_INCREMENT,
                                       user_id    INT          NOT NULL,
                                       token      VARCHAR(64)  NOT NULL,                  -- SHA-256 hex digest of the emailed token
                                       expires_at TIMESTAMP    NOT NULL,                  -- created_at + 60 min
                                       used_at    TIMESTAMP    NULL DEFAULT NULL,         -- stamped on redemption
                                       created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                       PRIMARY KEY (id),
                                       UNIQUE KEY  uk_prt_token   (token),
                                       INDEX       idx_prt_user   (user_id),
                                       INDEX       idx_prt_expiry (expires_at),

                                       CONSTRAINT fk_prt_user FOREIGN KEY (user_id)
                                           REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
--  B. SEED DATA
-- ================================================================

-- ----------------------------------------------------------------
--  Users
--  Seed accounts use unique, random PBKDF2 hashes whose passwords are discarded.
--  They cannot authenticate. Create your real owner account through registration,
--  then promote it to admin using a secured database session before deployment.
-- ----------------------------------------------------------------
INSERT INTO users
(first_name, last_name, email, phone, password_hash,
 role, city, country)
VALUES
    -- id=1  Administrator
    ('Grand',  'Admin',
     'seed-admin@invalid.example',  NULL,
     '{PBKDF2}210000:77183e76176e38dc03e9e4e8106faed0:442318812deec4ee2a9cd8187be7eaaea598ff3b93b28596bcf7129761803517',
     'admin', 'Amritsar',   'India'),

    -- id=2  Arjun Sharma (sample guest — has confirmed bookings)
    ('Arjun',  'Sharma',
     'arjun@example.com',      '+91 98765 43210',
     '{PBKDF2}210000:cbd23ab5b30464423dd1736da642ce72:badd5d9448baf6c65cad982b840ee56ce70324e66fce3b606691e274affc09a5',
     'guest', 'Mumbai',     'India'),

    -- id=3  Priya Mehta
    ('Priya',  'Mehta',
     'priya@example.com',      '+91 97654 32109',
     '{PBKDF2}210000:89f516527c8e01be5c8dd99f822e2102:0e0a4a45927523368a3f6c17d5fec42b032156d805cbe4aa91a816d3008385e7',
     'guest', 'Delhi',      'India'),

    -- id=4  Rahul Verma
    ('Rahul',  'Verma',
     'rahul@example.com',      '+91 96543 21098',
     '{PBKDF2}210000:accfb6b9de0da5a4b181981bcdac02bf:19281312190946eed7a671a6a950329f3b2f0cf84834dc34ae424a62515d6626',
     'guest', 'Bengaluru',  'India'),

    -- id=5  Dev Patel
    ('Dev',    'Patel',
     'dev@example.com',        '+91 94321 09876',
     '{PBKDF2}210000:8c35107bcb641c3fc849422eb1eb847d:729363a4d479d1f60cf0013044e2a53cd0bb963fb32272c1a2ea804719c761cc',
     'guest', 'Ahmedabad',  'India'),

    -- id=6  Sunita Kapoor
    ('Sunita', 'Kapoor',
     'sunita@example.com',     '+91 93210 98765',
     '{PBKDF2}210000:41be8ef346544d220d5bacb3662b3433:a7f63693dc0d4084e7310ee687a0875c6098c64bdc505f76abd22e3456f068f3',
     'guest', 'Amritsar',   'India'),

    -- id=7  Neha Singh (suspended — matches manage-users.jsp demo)
    ('Neha',   'Singh',
     'neha@example.com',       '+91 95432 10987',
     '{PBKDF2}210000:89ab3a2e8d2f7108f910b7741c315c65:8e44e79534529e1a0295d0fa79c7e3e8e1468d03f853cdb2631f6deda0190ed2',
     'guest', 'Chandigarh', 'India');

-- Suspend Neha
UPDATE users
SET is_suspended    = 1,
    suspension_note = 'Repeated no-show policy violations.'
WHERE email = 'neha@example.com';

-- ----------------------------------------------------------------
--  Rooms (13 rooms — IDs 1–13 match booking seed data below)
-- ----------------------------------------------------------------
INSERT INTO rooms
(room_number, room_type, floor, capacity,
 rate_per_night, description, status)
VALUES
    -- id=1
    ('101', 'Deluxe Room',      '1st', '2 Adults',             8500.00,
     'Elegant 35 sqm room with king-size bed, premium linens, and a marble ensuite bathroom.',
     'Occupied'),
    -- id=2
    ('102', 'Deluxe Room',      '1st', '2 Adults',             8500.00,
     'Corner room with extra natural light and city views.',
     'Available'),
    -- id=3
    ('103', 'Deluxe Room',      '1st', '2 Adults',             8500.00,
     'Quiet garden-facing deluxe room on the first floor.',
     'Available'),
    -- id=4
    ('201', 'Twin Room',        '2nd', '2 Adults',             7200.00,
     'Spacious twin room with two premium single beds ideal for colleagues or friends.',
     'Available'),
    -- id=5
    ('202', 'Twin Room',        '2nd', '2 Adults',             7200.00,
     'Garden-facing twin room with soft natural light.',
     'Available'),
    -- id=6
    ('301', 'Family Suite',     '3rd', '2 Adults + 3 Children',12000.00,
     '55 sqm space with connecting rooms and bunk bed area for children.',
     'Available'),
    -- id=7
    ('302', 'Family Suite',     '3rd', '2 Adults + 3 Children',12000.00,
     'Corner family suite with separate kids lounge area.',
     'Available'),
    -- id=8
    ('401', 'Junior Suite',     '4th', '2 Adults',            15000.00,
     'Separate living area, dining nook, and private balcony overlooking the gardens.',
     'Available'),
    -- id=9
    ('402', 'Junior Suite',     '4th', '2 Adults',            15000.00,
     'Junior suite with soaking tub and rainfall shower.',
     'Available'),
    -- id=10
    ('501', 'Junior Suite',     '5th', '2 Adults',            15000.00,
     'Fifth floor junior suite with panoramic city views.',
     'Occupied'),
    -- id=11
    ('601', 'Executive Suite',  '6th', '2 Adults',            22000.00,
     'Designed for the business traveller with private meeting area and executive lounge access.',
     'Available'),
    -- id=12
    ('602', 'Executive Suite',  '7th', '2 Adults',            22000.00,
     'Executive suite with dedicated workspace and premium connectivity.',
     'Available'),
    -- id=13
    ('P01', 'Presidential Suite','Penthouse','4 Adults',      38000.00,
     '120 sqm penthouse with private butler, rooftop jacuzzi, and panoramic 270-degree city views.',
     'Occupied');

-- ----------------------------------------------------------------
--  Bookings
--  user_id map: 1=admin  2=Arjun  3=Priya  4=Rahul
--               5=Dev    6=Sunita 7=Neha
--  room_id map: matches room INSERT order above (101=1 … P01=13)
--
--  Status notes:
--    GH-2401 Confirmed  — payment captured (has payments row)
--    GH-2400 Confirmed  — payment captured (has payments row)
--    GH-2399 Pending    — booking exists, payment not yet made
--    GH-2398 Cancelled  — cancelled before payment
--    GH-2397 Confirmed  — payment captured (has payments row)
--    GH-2350 Checked-Out — completed stay, has review
--    GH-2210 Cancelled  — cancelled
--    GH-2396 Pending    — awaiting payment (Neha)
-- ----------------------------------------------------------------
INSERT INTO bookings
(booking_ref, user_id, room_id,
 guest_first, guest_last, guest_email, guest_phone,
 checkin_date, checkout_date, adults, children, nights,
 rate_per_night, subtotal, tax_amount, total_amount,
 special_requests, status)
VALUES
    -- 1. GH-2401  Arjun → Presidential Suite (room 13)
    ('GH-2401', 2, 13,
     'Arjun', 'Sharma', 'arjun@example.com', '+91 98765 43210',
     '2025-03-20', '2025-03-24', 2, 0, 4,
     38000.00, 152000.00, 18240.00, 170240.00,
     'Flowers on arrival, high floor preferred.',
     'Confirmed'),

    -- 2. GH-2400  Priya → Junior Suite (room 10)
    ('GH-2400', 3, 10,
     'Priya', 'Mehta', 'priya@example.com', '+91 97654 32109',
     '2025-03-19', '2025-03-21', 2, 0, 2,
     15000.00, 30000.00, 3600.00, 33600.00,
     NULL, 'Confirmed'),

    -- 3. GH-2399  Rahul → Deluxe Room (room 1) — pending payment
    ('GH-2399', 4, 1,
     'Rahul', 'Verma', 'rahul@example.com', '+91 96543 21098',
     '2025-03-18', '2025-03-20', 1, 0, 2,
     8500.00, 17000.00, 2040.00, 19040.00,
     NULL, 'Pending'),

    -- 4. GH-2398  Sunita → Family Suite (room 7) — cancelled
    ('GH-2398', 6, 7,
     'Sunita', 'Kapoor', 'sunita@example.com', '+91 93210 98765',
     '2025-03-17', '2025-03-19', 2, 2, 2,
     12000.00, 24000.00, 2880.00, 26880.00,
     NULL, 'Cancelled'),

    -- 5. GH-2397  Dev → Executive Suite (room 11)
    ('GH-2397', 5, 11,
     'Dev', 'Patel', 'dev@example.com', '+91 94321 09876',
     '2025-03-16', '2025-03-18', 2, 0, 2,
     22000.00, 44000.00, 5280.00, 49280.00,
     'Early check-in requested.',
     'Confirmed'),

    -- 6. GH-2350  Arjun → Deluxe Room (room 1) — checked out, has review
    ('GH-2350', 2, 1,
     'Arjun', 'Sharma', 'arjun@example.com', '+91 98765 43210',
     '2025-01-14', '2025-01-17', 2, 0, 3,
     8500.00, 25500.00, 3060.00, 28560.00,
     NULL, 'Checked-Out'),

    -- 7. GH-2210  Sunita → Family Suite (room 7) — cancelled
    ('GH-2210', 6, 7,
     'Sunita', 'Kapoor', 'sunita@example.com', '+91 93210 98765',
     '2024-11-05', '2024-11-07', 2, 2, 2,
     12000.00, 24000.00, 2880.00, 26880.00,
     NULL, 'Cancelled'),

    -- 8. GH-2396  Neha → Twin Room (room 4) — pending payment
    ('GH-2396', 7, 4,
     'Neha', 'Singh', 'neha@example.com', '+91 95432 10987',
     '2025-03-22', '2025-03-25', 2, 0, 3,
     7200.00, 21600.00, 2592.00, 24192.00,
     NULL, 'Pending');

-- ----------------------------------------------------------------
--  Payments
--  booking_id map: GH-2401=1  GH-2400=2  GH-2399=3  GH-2398=4
--                  GH-2397=5  GH-2350=6  GH-2210=7  GH-2396=8
--
--  amount_paise = total_amount × 100
--    GH-2401: 170240.00 × 100 = 17024000
--    GH-2400:  33600.00 × 100 =  3360000
--    GH-2399:  19040.00 × 100 =  1904000  (failed attempt)
--    GH-2397:  49280.00 × 100 =  4928000
--    GH-2350:  28560.00 × 100 =  2856000
-- ----------------------------------------------------------------
INSERT INTO payments
(booking_id, booking_ref,
 razorpay_order_id, razorpay_payment_id, razorpay_signature,
 amount_paise, currency, payment_status, failure_reason, payment_method)
VALUES
    -- GH-2401  captured (card)
    (1, 'GH-2401',
     'order_OFj9GHPbk1xYoA', 'pay_OFjABcdEfGhIjKl',
     'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
     17024000, 'INR', 'captured', NULL, 'card'),

    -- GH-2400  captured (upi)
    (2, 'GH-2400',
     'order_PGk0HIQcl2yZpB', 'pay_PGkBCdEfGhIjKlMn',
     'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
     3360000, 'INR', 'captured', NULL, 'upi'),

    -- GH-2399  failed attempt (netbanking — bank returned error)
    (3, 'GH-2399',
     'order_QHl1IJRdm3zAqC', NULL, NULL,
     1904000, 'INR', 'failed',
     'Payment failed due to bank server error. Please retry.',
     'netbanking'),

    -- GH-2397  captured (card)
    (5, 'GH-2397',
     'order_RIm2JKSen4aBrD', 'pay_RImBCdEfGhIjKlNo',
     'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
     4928000, 'INR', 'captured', NULL, 'card'),

    -- GH-2350  captured (upi) — checked-out stay
    (6, 'GH-2350',
     'order_SJn3KLTfo5bCsE', 'pay_SJnBCdEfGhIjKlOp',
     'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5',
     2856000, 'INR', 'captured', NULL, 'upi');

-- ----------------------------------------------------------------
--  Contact Messages
-- ----------------------------------------------------------------
INSERT INTO contact_messages
(name, email, phone, subject, message, ip_address, is_read)
VALUES
    ('Arjun Sharma', 'arjun@example.com', '+91 98765 43210',
     'Room Reservation',
     'I would like to enquire about availability for the Presidential Suite in April 2025. Could you please send me a detailed package with early check-in options?',
     '103.21.58.10', 1),

    ('Priya Mehta', 'priya@example.com', '+91 97654 32109',
     'Special Occasions',
     'We are planning our anniversary stay and would love to know what decorations and surprises you can arrange for our room upon arrival.',
     '103.21.58.11', 0),

    ('Corporate HR', 'hr@techcorp.in', '+91 80123 45678',
     'Corporate Events',
     'We need to block 8 rooms for an executive offsite from 10 to 12 April 2025. Please share your corporate rate card and conference room availability.',
     '103.21.58.12', 0),

    ('Dev Patel', 'dev@example.com', '+91 94321 09876',
     'General Inquiry',
     'Is airport transfer available from Amritsar International Airport? What is the approximate cost and travel time to the hotel?',
     '103.21.58.13', 1);

-- ----------------------------------------------------------------
--  Reviews
--  booking_id 6 = GH-2350 (Arjun, Deluxe Room 101, Checked-Out)
-- ----------------------------------------------------------------
INSERT INTO reviews
(booking_id, room_id, user_id, rating, title, body, status)
VALUES
    (6, 1, 2, 5,
     'An absolutely flawless stay',
     'Staying at Grand Horizon was not merely a visit — it was a transformation. The Deluxe Room was immaculate, the bed linen was of the highest quality, and the marble bathroom was stunning. The concierge team anticipated every need before I even had to ask. I will return without hesitation.',
     'Approved');

-- ----------------------------------------------------------------
--  Audit Log
-- ----------------------------------------------------------------
INSERT INTO audit_log
(user_id, user_email, action, ip_address, user_agent)
VALUES
    (1, 'admin@grandhorizon.in', 'LOGIN',  '127.0.0.1',      'Mozilla/5.0 (Windows NT 10.0) Chrome/122'),
    (2, 'arjun@example.com',    'LOGIN',  '103.21.58.10',    'Mozilla/5.0 (iPhone) Mobile Safari/605'),
    (2, 'arjun@example.com',    'LOGOUT', '103.21.58.10',    'Mozilla/5.0 (iPhone) Mobile Safari/605'),
    (5, 'dev@example.com',      'LOGIN',  '103.21.58.13',    'Mozilla/5.0 (Android) Chrome/121'),
    (5, 'dev@example.com',      'LOGOUT', '103.21.58.13',    'Mozilla/5.0 (Android) Chrome/121');

-- ================================================================
--  C. STORED PROCEDURES
-- ================================================================
DELIMITER $$

-- ----------------------------------------------------------------
--  generate_booking_ref()
--  Returns the next sequential booking reference (e.g. GH-2402).
--  Called by BookingServlet via SQL_NEXT_REF before INSERT.
-- ----------------------------------------------------------------
CREATE PROCEDURE generate_booking_ref(OUT ref VARCHAR(20))
BEGIN
    DECLARE last_num INT DEFAULT 2401;
    SELECT CAST(SUBSTRING(booking_ref, 4) AS UNSIGNED)
    INTO last_num
    FROM bookings
    ORDER BY id DESC
    LIMIT 1;
    SET ref = CONCAT('GH-', last_num + 1);
END$$

-- ----------------------------------------------------------------
--  cleanup_expired_tokens()
--  Deletes password reset tokens that have expired or been used.
--  Call daily or schedule via the Event Scheduler below.
-- ----------------------------------------------------------------
CREATE PROCEDURE cleanup_expired_tokens()
BEGIN
    DELETE FROM password_reset_tokens
    WHERE expires_at < NOW()
       OR used_at IS NOT NULL;
    SELECT ROW_COUNT() AS rows_deleted;
END$$

-- ----------------------------------------------------------------
--  cleanup_old_audit_log(retention_days INT)
--  Prunes audit rows older than retention_days (default: 365).
--  Prevents unbounded table growth.
-- ----------------------------------------------------------------
CREATE PROCEDURE cleanup_old_audit_log(IN retention_days INT)
BEGIN
    SET retention_days = IFNULL(retention_days, 365);
    DELETE FROM audit_log
    WHERE created_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    SELECT ROW_COUNT() AS rows_deleted;
END$$

-- ----------------------------------------------------------------
--  get_revenue_summary(p_from DATE, p_to DATE)
--  Returns daily revenue totals for the reports.jsp chart.
--  Usage: CALL get_revenue_summary('2025-03-01', '2025-03-31');
-- ----------------------------------------------------------------
CREATE PROCEDURE get_revenue_summary(IN p_from DATE, IN p_to DATE)
BEGIN
    SELECT
        DATE(p.created_at)         AS payment_date,
        COUNT(*)                   AS transaction_count,
        SUM(p.amount_paise) / 100  AS revenue_inr
    FROM  payments p
    WHERE p.payment_status = 'captured'
      AND DATE(p.created_at) BETWEEN p_from AND p_to
    GROUP BY DATE(p.created_at)
    ORDER BY payment_date;
END$$

DELIMITER ;

-- ================================================================
--  D. VIEWS  (10 total)
-- ================================================================

-- ----------------------------------------------------------------
--  v_booking_summary
--  Full booking record joined with room details.
--  Used by admin manage-bookings.jsp.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_booking_summary AS
SELECT
    b.id,
    b.booking_ref,
    CONCAT(b.guest_first, ' ', b.guest_last) AS guest_name,
    b.guest_email,
    b.guest_phone,
    r.room_number,
    r.room_type,
    b.checkin_date,
    b.checkout_date,
    b.nights,
    b.adults,
    b.children,
    b.subtotal,
    b.tax_amount,
    b.total_amount,
    b.status,
    b.special_requests,
    b.created_at
FROM  bookings b
          JOIN  rooms    r ON b.room_id = r.id
ORDER BY b.created_at DESC;

-- ----------------------------------------------------------------
--  v_room_availability
--  Rooms not occupied today — used by RoomServlet (action=available)
--  for the quick-book AJAX endpoint.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_room_availability AS
SELECT
    r.id,
    r.room_number,
    r.room_type,
    r.floor,
    r.capacity,
    r.rate_per_night,
    r.description,
    r.status,
    COUNT(b.id) AS active_bookings_today
FROM  rooms r
          LEFT  JOIN bookings b
                     ON  b.room_id = r.id
                         AND  b.status  IN ('Confirmed', 'Pending', 'Checked-In')
                         AND  CURDATE() BETWEEN b.checkin_date AND b.checkout_date
GROUP BY r.id;

-- ----------------------------------------------------------------
--  v_review_summary
--  Approved reviews with masked guest name for room-details.jsp.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_review_summary AS
SELECT
    rv.id,
    rv.room_id,
    rv.user_id,
    rv.rating,
    rv.title,
    rv.body,
    rv.status,
    rv.created_at,
    CONCAT(u.first_name, ' ', LEFT(u.last_name, 1), '.') AS guest_display_name,
    u.email                                               AS guest_email,
    r.room_number,
    r.room_type,
    b.booking_ref
FROM  reviews rv
          JOIN  users    u ON rv.user_id    = u.id
          JOIN  rooms    r ON rv.room_id    = r.id
          JOIN  bookings b ON rv.booking_id = b.id
WHERE rv.status = 'Approved'
ORDER BY rv.created_at DESC;

-- ----------------------------------------------------------------
--  v_room_ratings
--  Aggregated star ratings per room.
--  Used by rooms.jsp and room-details.jsp for the rating badge
--  and per-star breakdown bars.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_room_ratings AS
SELECT
    room_id,
    ROUND(AVG(rating), 1) AS avg_rating,
    COUNT(*)              AS review_count,
    SUM(rating = 5)       AS stars_5,
    SUM(rating = 4)       AS stars_4,
    SUM(rating = 3)       AS stars_3,
    SUM(rating = 2)       AS stars_2,
    SUM(rating = 1)       AS stars_1
FROM  reviews
WHERE status = 'Approved'
GROUP BY room_id;

-- ----------------------------------------------------------------
--  v_user_stats
--  Per-user booking statistics for manage-users.jsp modals.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_stats AS
SELECT
    u.id          AS user_id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.role,
    u.is_suspended,
    u.created_at,
    COUNT(b.id)                       AS total_bookings,
    COALESCE(SUM(b.nights),       0)  AS total_nights,
    COALESCE(SUM(b.total_amount), 0)  AS total_spent
FROM  users u
          LEFT  JOIN bookings b
                     ON  b.user_id = u.id
                         AND  b.status  NOT IN ('Cancelled')
GROUP BY u.id;

-- ----------------------------------------------------------------
--  v_pending_reviews
--  Reviews awaiting admin moderation.
--  Used for the sidebar badge count in manage-reviews.jsp.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_pending_reviews AS
SELECT
    rv.id,
    rv.rating,
    rv.title,
    rv.body,
    rv.created_at,
    CONCAT(u.first_name, ' ', u.last_name) AS guest_name,
    u.email                                AS guest_email,
    r.room_number,
    r.room_type,
    b.booking_ref
FROM  reviews rv
          JOIN  users    u ON rv.user_id    = u.id
          JOIN  rooms    r ON rv.room_id    = r.id
          JOIN  bookings b ON rv.booking_id = b.id
WHERE rv.status = 'Pending'
ORDER BY rv.created_at ASC;   -- oldest first (FIFO moderation)

-- ----------------------------------------------------------------
--  v_unread_messages
--  Unread contact messages for the admin sidebar badge counter.
--  ContactServlet?action=unreadCount queries COUNT(*) from here.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_unread_messages AS
SELECT id, name, email, subject, created_at
FROM contact_messages
WHERE is_read = 0
ORDER BY created_at DESC;

-- ----------------------------------------------------------------
--  v_payment_summary
--  Full payment history joined with booking details.
--  Used by an admin payments panel (manage-payments.jsp).
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_payment_summary AS
SELECT
    p.id                                      AS payment_id,
    p.booking_ref,
    CONCAT(b.guest_first, ' ', b.guest_last)  AS guest_name,
    b.guest_email,
    p.razorpay_order_id,
    p.razorpay_payment_id,
    p.amount_paise / 100                      AS amount_inr,
    p.currency,
    p.payment_status,
    p.payment_method,
    p.failure_reason,
    b.status                                  AS booking_status,
    p.created_at
FROM  payments p
          JOIN  bookings b ON p.booking_id = b.id
ORDER BY p.created_at DESC;

-- ----------------------------------------------------------------
--  v_booking_payment_status
--  Shows each booking with its latest payment status side by side.
--  Useful for the admin dashboard overview and reports.jsp.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_booking_payment_status AS
SELECT
    b.id                                      AS booking_id,
    b.booking_ref,
    CONCAT(b.guest_first, ' ', b.guest_last)  AS guest_name,
    b.guest_email,
    r.room_type,
    r.room_number,
    b.checkin_date,
    b.checkout_date,
    b.total_amount,
    b.status                                  AS booking_status,
    latest_pay.payment_status,
    latest_pay.razorpay_payment_id,
    latest_pay.payment_method
FROM  bookings b
          JOIN  rooms r ON b.room_id = r.id
          LEFT  JOIN (
    SELECT  p1.*
    FROM    payments p1
                INNER   JOIN (
        SELECT booking_id, MAX(created_at) AS max_ts
        FROM payments
        GROUP BY booking_id
    ) p2 ON p1.booking_id = p2.booking_id
        AND p1.created_at = p2.max_ts
) latest_pay ON latest_pay.booking_id = b.id
ORDER BY b.created_at DESC;

-- ----------------------------------------------------------------
--  v_revenue_by_room_type
--  Revenue breakdown by room type for reports.jsp donut chart.
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW v_revenue_by_room_type AS
SELECT
    r.room_type,
    COUNT(p.id)               AS payment_count,
    SUM(p.amount_paise) / 100 AS total_revenue_inr
FROM  payments  p
          JOIN  bookings  b ON p.booking_id = b.id
          JOIN  rooms     r ON b.room_id    = r.id
WHERE p.payment_status = 'captured'
GROUP BY r.room_type
ORDER BY total_revenue_inr DESC;

-- ================================================================
--  E. OPTIONAL: MySQL Event Scheduler
--  Runs cleanup_expired_tokens() nightly at 03:00 AM.
--  Requires: SET GLOBAL event_scheduler = ON;
--  (Comment out if your hosting does not support the scheduler.)
-- ================================================================
-- CREATE EVENT IF NOT EXISTS evt_cleanup_expired_tokens
--     ON SCHEDULE EVERY 1 DAY
--     STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 3 HOUR)
--     DO CALL cleanup_expired_tokens();

-- ================================================================
--  END OF FILE
--  Grand Horizon Hotel  |  hotel.sql  |  MySQL 8.0+
--  Tables: 8  |  Views: 10  |  Procedures: 4
-- ================================================================
