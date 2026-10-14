<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Reuses all styles from privacy-policy.jsp — identical layout ── */
        .legal-page { padding-top: 5rem; min-height: 100vh; }

        .legal-hero {
            position: relative;
            padding: 6rem 0 4rem;
            text-align: center;
            overflow: hidden;
            background: var(--deep-navy);
            border-bottom: 1px solid var(--border);
        }
        .legal-hero::before {
            content: '';
            position: absolute;
            inset: 0;
            background: radial-gradient(ellipse 55% 60% at 50% 0%,
            rgba(200,170,100,0.07) 0%, transparent 65%);
            pointer-events: none;
        }
        .legal-hero__eyebrow {
            display: block;
            font-size: 0.62rem;
            letter-spacing: 0.45em;
            text-transform: uppercase;
            color: var(--gold);
            margin-bottom: 1rem;
        }
        .legal-hero__title {
            font-family: var(--font-display);
            font-size: clamp(2.2rem, 5vw, 3.6rem);
            font-weight: 300;
            line-height: 1.15;
            margin-bottom: 1rem;
        }
        .legal-hero__title em { font-style: italic; color: var(--gold-light); }
        .legal-hero__meta {
            font-size: 0.8rem;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 1.5rem;
            flex-wrap: wrap;
            margin-top: 1.2rem;
        }
        .legal-hero__meta-item {
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }
        .legal-hero__meta-item svg { width: 13px; height: 13px; color: var(--gold-muted); }

        .legal-layout {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 4rem;
            align-items: start;
            padding: 4rem 0 6rem;
        }

        .legal-toc {
            position: sticky;
            top: 7rem;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            overflow: hidden;
        }
        .legal-toc__header {
            padding: 1rem 1.4rem;
            background: var(--charcoal);
            border-bottom: 1px solid var(--border);
            font-size: 0.62rem;
            letter-spacing: 0.3em;
            text-transform: uppercase;
            color: var(--gold);
        }
        .legal-toc__list { padding: 0.6rem 0; }
        .legal-toc__item {
            display: block;
            padding: 0.55rem 1.4rem;
            font-size: 0.8rem;
            color: var(--text-secondary);
            text-decoration: none;
            transition: var(--transition);
            border-left: 2px solid transparent;
            line-height: 1.4;
        }
        .legal-toc__item:hover {
            color: var(--gold);
            background: var(--gold-glow);
            border-left-color: var(--gold-muted);
        }
        .legal-toc__item.active {
            color: var(--gold);
            background: var(--gold-glow);
            border-left-color: var(--gold);
        }

        .legal-article { max-width: 780px; }

        .legal-section {
            margin-bottom: 3.5rem;
            scroll-margin-top: 7rem;
        }
        .legal-section__number {
            display: inline-block;
            font-size: 0.6rem;
            letter-spacing: 0.35em;
            text-transform: uppercase;
            color: var(--gold);
            margin-bottom: 0.6rem;
        }
        .legal-section__title {
            font-family: var(--font-display);
            font-size: 1.55rem;
            font-weight: 400;
            color: var(--text-primary);
            margin-bottom: 1.2rem;
            padding-bottom: 0.8rem;
            border-bottom: 1px solid var(--border);
        }
        .legal-section__body {
            font-size: 0.93rem;
            color: var(--text-secondary);
            line-height: 1.95;
        }
        .legal-section__body p { margin-bottom: 1rem; }
        .legal-section__body p:last-child { margin-bottom: 0; }

        .legal-sub {
            font-size: 0.75rem;
            letter-spacing: 0.18em;
            text-transform: uppercase;
            color: var(--text-primary);
            font-weight: 500;
            margin: 1.5rem 0 0.6rem;
        }

        .legal-list {
            list-style: none;
            margin: 0.6rem 0 1rem;
            padding: 0;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        .legal-list li {
            display: flex;
            align-items: flex-start;
            gap: 0.8rem;
            font-size: 0.93rem;
            color: var(--text-secondary);
            line-height: 1.7;
        }
        .legal-list li::before {
            content: '';
            width: 5px;
            height: 5px;
            border-radius: 50%;
            background: var(--gold-muted);
            flex-shrink: 0;
            margin-top: 0.55em;
        }

        .legal-highlight {
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-left: 3px solid var(--gold-muted);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem;
            margin: 1.2rem 0;
            font-size: 0.88rem;
            color: var(--text-secondary);
            line-height: 1.8;
        }
        .legal-highlight strong { color: var(--gold); font-weight: 500; }

        /* Warning / notice box */
        .legal-notice {
            background: rgba(192,81,58,0.07);
            border: 1px solid rgba(192,81,58,0.22);
            border-left: 3px solid var(--error);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem;
            margin: 1.2rem 0;
            font-size: 0.88rem;
            color: var(--text-secondary);
            line-height: 1.8;
        }
        .legal-notice strong { color: #d9705a; font-weight: 500; }

        /* Rate table */
        .legal-table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
            font-size: 0.87rem;
        }
        .legal-table th {
            padding: 0.7rem 1rem;
            background: var(--charcoal);
            border: 1px solid var(--border);
            font-size: 0.65rem;
            letter-spacing: 0.18em;
            text-transform: uppercase;
            color: var(--text-muted);
            font-weight: 500;
            text-align: left;
        }
        .legal-table td {
            padding: 0.75rem 1rem;
            border: 1px solid var(--border);
            color: var(--text-secondary);
            vertical-align: top;
        }
        .legal-table tr:nth-child(even) td { background: rgba(255,255,255,0.015); }

        .legal-contact-card {
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            padding: 2rem;
            margin-top: 3rem;
            display: flex;
            align-items: flex-start;
            gap: 1.5rem;
        }
        .legal-contact-card__icon {
            width: 44px; height: 44px;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--gold);
            flex-shrink: 0;
        }
        .legal-contact-card__title {
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 400;
            margin-bottom: 0.4rem;
        }
        .legal-contact-card__text {
            font-size: 0.85rem;
            color: var(--text-secondary);
            line-height: 1.75;
        }
        .legal-contact-card__text a { color: var(--gold); }

        .legal-sibling {
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem;
            margin-top: 2rem;
            text-decoration: none;
            transition: var(--transition);
        }
        .legal-sibling:hover {
            border-color: var(--border-light);
            background: var(--surface);
        }
        .legal-sibling__label {
            font-size: 0.65rem;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 0.25rem;
        }
        .legal-sibling__title { font-family: var(--font-display); font-size: 1.1rem; color: var(--gold-light); }
        .legal-sibling__arrow { color: var(--gold-muted); font-size: 1.4rem; }

        @media (max-width: 900px) {
            .legal-layout { grid-template-columns: 1fr; gap: 2rem; }
            .legal-toc {
                position: static;
                display: flex;
                flex-wrap: wrap;
            }
            .legal-toc__list { display: flex; flex-wrap: wrap; padding: 0.4rem; }
            .legal-toc__item {
                border-left: none;
                border-bottom: 2px solid transparent;
                padding: 0.4rem 0.9rem;
                white-space: nowrap;
                font-size: 0.75rem;
            }
            .legal-toc__item.active { border-left: none; border-bottom-color: var(--gold); }
        }
    </style>
</head>
<body>

<!-- ── Navbar ───────────────────────────────────────────────── -->
<nav class="navbar scrolled" id="navbar">
    <div class="container">
        <div class="navbar__inner">
            <a href="index.jsp" class="navbar__logo">
                <span class="navbar__logo-main">Grand Horizon</span>
                <span class="navbar__logo-sub">Luxury Hotel &amp; Suites</span>
            </a>
            <ul class="navbar__links">
                <li><a href="index.jsp">Home</a></li>
                <li><a href="rooms.jsp">Rooms</a></li>
                <li><a href="booking.jsp">Book</a></li>
                <li><a href="contact.jsp">Contact</a></li>
                <li><a href="login.jsp">Sign In</a></li>
            </ul>
            <a href="booking.jsp" class="btn navbar__cta">Reserve Now</a>
            <div class="hamburger"><span></span><span></span><span></span></div>
        </div>
    </div>
</nav>

<div class="legal-page">

    <!-- ── Hero ─────────────────────────────────────────────────── -->
    <div class="legal-hero">
        <div class="container">
            <span class="legal-hero__eyebrow">Legal &amp; Compliance</span>
            <h1 class="legal-hero__title">Terms of <em>Service</em></h1>
            <div class="section-divider"></div>
            <div class="legal-hero__meta">
        <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <rect x="3" y="4" width="18" height="18" rx="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/>
            <line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
          Effective Date: 1 January 2025
        </span>
                <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10"/>
            <polyline points="12 6 12 12 16 14"/>
          </svg>
          Last Updated: 1 March 2025
        </span>
                <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
          </svg>
          Governed by Indian Law
        </span>
            </div>
        </div>
    </div>

    <!-- ── Body ──────────────────────────────────────────────────── -->
    <div class="container">
        <div class="legal-layout">

            <!-- Table of Contents -->
            <aside class="legal-toc" id="toc">
                <div class="legal-toc__header">Contents</div>
                <nav class="legal-toc__list">
                    <a href="#acceptance"     class="legal-toc__item active">1. Acceptance</a>
                    <a href="#definitions"    class="legal-toc__item">2. Definitions</a>
                    <a href="#accounts"       class="legal-toc__item">3. User Accounts</a>
                    <a href="#reservations"   class="legal-toc__item">4. Reservations</a>
                    <a href="#payments"       class="legal-toc__item">5. Payments &amp; GST</a>
                    <a href="#cancellation"   class="legal-toc__item">6. Cancellation Policy</a>
                    <a href="#checkin"        class="legal-toc__item">7. Check-In / Out</a>
                    <a href="#guest-conduct"  class="legal-toc__item">8. Guest Conduct</a>
                    <a href="#liability"      class="legal-toc__item">9. Liability</a>
                    <a href="#ip"             class="legal-toc__item">10. Intellectual Property</a>
                    <a href="#reviews"        class="legal-toc__item">11. Reviews</a>
                    <a href="#termination"    class="legal-toc__item">12. Termination</a>
                    <a href="#disputes"       class="legal-toc__item">13. Disputes</a>
                    <a href="#changes"        class="legal-toc__item">14. Changes</a>
                    <a href="#contact-legal"  class="legal-toc__item">15. Contact</a>
                </nav>
            </aside>

            <!-- Article -->
            <article class="legal-article">

                <!-- Preamble -->
                <div class="legal-highlight" style="margin-bottom:2.5rem;">
                    <strong>Please read these Terms carefully before using this website
                        or making a reservation.</strong> By accessing the Grand Horizon Hotel
                    website, creating an account, or completing a booking, you agree to be
                    bound by these Terms of Service and our
                    <a href="privacy-policy.jsp" style="color:var(--gold);">Privacy Policy</a>.
                    If you do not agree, you must not use our Service.
                </div>

                <!-- 1 -->
                <div class="legal-section" id="acceptance">
                    <span class="legal-section__number">Section 01</span>
                    <h2 class="legal-section__title">Acceptance of Terms</h2>
                    <div class="legal-section__body">
                        <p>These Terms of Service ("Terms") constitute a legally binding
                            agreement between you ("Guest", "User", "you") and Grand Horizon Hotel,
                            a registered hospitality establishment located at 12, Palace Road,
                            Amritsar, Punjab — 143001, India ("Hotel", "we", "us", "our").</p>
                        <p>Your use of this website, mobile interface, or related digital
                            service (the "Service"), or your stay at the Hotel, constitutes
                            acceptance of these Terms in their entirety.  These Terms apply to
                            all visitors, registered users, and guests who complete a booking
                            through the Service.</p>
                        <p>If you are making a booking on behalf of another person, you
                            confirm that you have the authority to accept these Terms on their
                            behalf, and you accept personal liability for ensuring they comply
                            with these Terms during their stay.</p>
                    </div>
                </div>

                <!-- 2 -->
                <div class="legal-section" id="definitions">
                    <span class="legal-section__number">Section 02</span>
                    <h2 class="legal-section__title">Definitions</h2>
                    <div class="legal-section__body">
                        <ul class="legal-list">
                            <li><strong>"Booking"</strong> — a confirmed reservation of a room or suite at the Hotel made through the Service or directly with our reservations team.</li>
                            <li><strong>"Check-In Date"</strong> — the calendar date on which the Guest's booked stay is scheduled to begin, as stated in the booking confirmation.</li>
                            <li><strong>"Check-Out Date"</strong> — the calendar date on which the Guest's stay is scheduled to end.</li>
                            <li><strong>"Booking Reference"</strong> — the unique alphanumeric code (e.g. GH-2401) assigned to each confirmed booking and included in the confirmation email.</li>
                            <li><strong>"Total Amount"</strong> — the room rate multiplied by the number of nights, plus applicable taxes and fees as shown at the time of booking.</li>
                            <li><strong>"Service"</strong> — the Grand Horizon Hotel website, booking system, user account portal, and all related digital features.</li>
                        </ul>
                    </div>
                </div>

                <!-- 3 -->
                <div class="legal-section" id="accounts">
                    <span class="legal-section__number">Section 03</span>
                    <h2 class="legal-section__title">User Accounts</h2>
                    <div class="legal-section__body">
                        <p>You may browse the Service without creating an account. However,
                            making an online reservation and accessing booking history requires
                            registration.</p>

                        <p class="legal-sub">Registration requirements</p>
                        <ul class="legal-list">
                            <li>You must be at least 18 years of age to register.</li>
                            <li>You must provide accurate, current, and complete information.</li>
                            <li>You are responsible for maintaining the confidentiality of your password and for all activity that occurs under your account.</li>
                            <li>You must notify us immediately at <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a> if you suspect unauthorised use of your account.</li>
                        </ul>

                        <p class="legal-sub">Account security</p>
                        <p>We store passwords as salted PBKDF2-HMAC-SHA-256 hashes and will never ask you to share
                            your password with our staff.  If you forget your password, use the
                            "Forgot Password" link on the login page.</p>

                        <p class="legal-sub">Account termination by you</p>
                        <p>You may request account deletion through the Profile page after
                            cancelling or completing upcoming bookings. The account is removed
                            and associated booking and audit records are anonymised by the
                            application. Contact messages and transaction records may be retained
                            for support, accounting, and other legal requirements.</p>
                    </div>
                </div>

                <!-- 4 -->
                <div class="legal-section" id="reservations">
                    <span class="legal-section__number">Section 04</span>
                    <h2 class="legal-section__title">Reservations &amp; Booking Process</h2>
                    <div class="legal-section__body">
                        <p>All reservations are subject to room availability at the time of
                            booking.  Submitting a booking form does not constitute a confirmed
                            reservation; confirmation occurs when you receive a booking confirmation
                            email containing your Booking Reference.</p>

                        <p class="legal-sub">Accuracy of booking details</p>
                        <p>You are responsible for ensuring that all booking details — including
                            dates, number of guests, room type, and contact information — are
                            correct before submitting.  Errors in dates or guest count that are
                            discovered after confirmation may incur amendment fees or be treated
                            as a cancellation and re-booking at the then-current rate.</p>

                        <p class="legal-sub">Room allocation</p>
                        <p>We reserve the right to allocate a room of equivalent or higher
                            category if the specific room number chosen is unavailable due to
                            unforeseen circumstances (e.g. maintenance).  In such cases no
                            additional charge will apply.</p>

                        <p class="legal-sub">Special requests</p>
                        <p>Special requests (e.g. high floor, specific view, early arrival)
                            are noted in your booking but cannot be guaranteed.  Fulfilment of
                            special requests is subject to availability at the time of check-in
                            and does not form part of the contract.</p>

                        <div class="legal-notice">
                            <strong>Group bookings.</strong> Reservations of 5 or more rooms
                            simultaneously are classified as group bookings and are subject to
                            separate terms and pricing.  Please contact our reservations team
                            directly at <a href="mailto:groups@grandhorizon.in"
                                           style="color:#d9705a;">groups@grandhorizon.in</a>.
                        </div>
                    </div>
                </div>

                <!-- 5 -->
                <div class="legal-section" id="payments">
                    <span class="legal-section__number">Section 05</span>
                    <h2 class="legal-section__title">Payments, Taxes &amp; GST</h2>
                    <div class="legal-section__body">
                        <p>All prices displayed on the Service are in Indian Rupees (INR).
                            The Total Amount shown at checkout includes all applicable taxes.</p>

                        <p class="legal-sub">GST applicability (as per GST Council rates)</p>
                        <table class="legal-table">
                            <thead>
                            <tr>
                                <th>Room Tariff (per night)</th>
                                <th>GST Rate</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td>Up to ₹7,500</td>
                                <td>12% (6% CGST + 6% SGST)</td>
                            </tr>
                            <tr>
                                <td>Above ₹7,500</td>
                                <td>18% (9% CGST + 9% SGST)</td>
                            </tr>
                            </tbody>
                        </table>

                        <p>A GST-compliant invoice will be issued at check-in or via email.
                            If you require an invoice with a company GST number (B2B), you must
                            provide your GSTIN at the time of booking.</p>

                        <p class="legal-sub">Payment timing</p>
                        <p>For online bookings, full payment is due at check-in unless a
                            pre-payment option is selected at checkout.  We accept major debit and
                            credit cards, UPI, and cash at the front desk.  Card payments are
                            processed through our PCI-DSS-compliant payment gateway.</p>

                        <p class="legal-sub">Currency</p>
                        <p>All charges are billed in INR.  If your card is denominated in
                            a foreign currency, your bank's exchange rate and any applicable
                            conversion fees apply.</p>
                    </div>
                </div>

                <!-- 6 -->
                <div class="legal-section" id="cancellation">
                    <span class="legal-section__number">Section 06</span>
                    <h2 class="legal-section__title">Cancellation &amp; Modification Policy</h2>
                    <div class="legal-section__body">

                        <p class="legal-sub">Standard cancellation policy</p>
                        <table class="legal-table">
                            <thead>
                            <tr>
                                <th>Notice Given Before Check-In</th>
                                <th>Charge</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td>More than 48 hours</td>
                                <td>No charge — full refund</td>
                            </tr>
                            <tr>
                                <td>24 – 48 hours</td>
                                <td>1 night's room rate + applicable GST</td>
                            </tr>
                            <tr>
                                <td>Less than 24 hours / No-show</td>
                                <td>100% of Total Amount — no refund</td>
                            </tr>
                            </tbody>
                        </table>

                        <p class="legal-sub">How to cancel</p>
                        <ul class="legal-list">
                            <li>Log in to your account and navigate to My Dashboard → Your Booking → Cancel Booking.</li>
                            <li>Alternatively, email <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a> with your Booking Reference and a cancellation request.</li>
                            <li>Cancellations are effective from the date and time received, not from the date of your request email.</li>
                        </ul>

                        <p class="legal-sub">Modifications</p>
                        <p>Amendments to check-in date, check-out date, or room type are
                            treated as a cancellation and re-booking at the then-current rate,
                            subject to availability.  Contact us at least 48 hours before check-in
                            to avoid cancellation charges on the original booking.</p>

                        <p class="legal-sub">Refund processing</p>
                        <p>Eligible refunds are processed to the original payment method
                            within 7–10 business days of the cancellation being confirmed.
                            Processing times may vary depending on your bank.</p>

                        <div class="legal-highlight">
                            <strong>Force Majeure.</strong> We will not apply cancellation
                            charges for bookings cancelled due to government-declared natural
                            disasters, pandemics, or travel restrictions that directly prevent
                            the Guest from travelling.  Documentary evidence may be required.
                        </div>
                    </div>
                </div>

                <!-- 7 -->
                <div class="legal-section" id="checkin">
                    <span class="legal-section__number">Section 07</span>
                    <h2 class="legal-section__title">Check-In &amp; Check-Out</h2>
                    <div class="legal-section__body">
                        <ul class="legal-list">
                            <li><strong>Check-in time:</strong> 2:00 PM on the Check-In Date. Early check-in before 10:00 AM is subject to availability and may attract a half-day charge.</li>
                            <li><strong>Check-out time:</strong> 12:00 PM (noon) on the Check-Out Date. Late check-out beyond 2:00 PM is subject to availability and may attract an additional full-night charge at the prevailing rate.</li>
                            <li><strong>Valid ID required:</strong> All guests must present a valid government-issued photo ID (Aadhaar card, Passport, Driving Licence, or Voter ID) at check-in as required by the Foreigners Act, 1946 and the Hotel Registration of Guests Rules.</li>
                            <li><strong>Foreign nationals</strong> must present a valid Passport and, where applicable, a Visa. We are required to record foreign-guest information in Form C and submit it to the local police authority within 24 hours of check-in.</li>
                        </ul>
                    </div>
                </div>

                <!-- 8 -->
                <div class="legal-section" id="guest-conduct">
                    <span class="legal-section__number">Section 08</span>
                    <h2 class="legal-section__title">Guest Conduct &amp; House Rules</h2>
                    <div class="legal-section__body">
                        <p>To ensure an exceptional experience for all guests, the following
                            rules apply throughout the Hotel premises:</p>
                        <ul class="legal-list">
                            <li><strong>Noise:</strong> Quiet hours are observed from 11:00 PM to 7:00 AM. Disruptive noise at any hour that disturbs other guests may result in immediate eviction without refund.</li>
                            <li><strong>Smoking:</strong> The Hotel is a smoke-free property. Smoking is prohibited in all rooms, corridors, and indoor common areas. A deep-cleaning fee of ₹5,000 will be levied if evidence of smoking in a room is found.</li>
                            <li><strong>Pets:</strong> Pets are not permitted on the Hotel premises.</li>
                            <li><strong>Visitors:</strong> Non-resident visitors must be registered at the front desk and are not permitted in guest rooms after 10:00 PM.</li>
                            <li><strong>Damage:</strong> Guests are financially liable for any damage to Hotel property caused during their stay. Costs will be charged to the registered payment method.</li>
                            <li><strong>Illegal activity:</strong> Any conduct that is unlawful under Indian law — including but not limited to drug use, illegal gambling, or trafficking — will result in immediate eviction and referral to law enforcement.</li>
                            <li><strong>Mini-bar / in-room dining:</strong> Charges for mini-bar consumption and room service orders are automatically added to your bill and settled at check-out.</li>
                        </ul>
                        <p>We reserve the right to remove any guest from the premises for
                            violation of these rules, without refund of any unused portion of
                            their stay.</p>
                    </div>
                </div>

                <!-- 9 -->
                <div class="legal-section" id="liability">
                    <span class="legal-section__number">Section 09</span>
                    <h2 class="legal-section__title">Liability &amp; Disclaimers</h2>
                    <div class="legal-section__body">
                        <p class="legal-sub">Hotel's liability</p>
                        <p>To the maximum extent permitted by the Consumer Protection Act, 2019,
                            and other applicable Indian law, our total liability to you in connection
                            with any stay or use of the Service shall not exceed the Total Amount
                            paid for the booking in question.</p>

                        <p class="legal-sub">Guest valuables</p>
                        <p>The Hotel provides in-room electronic safes for the storage of
                            valuables.  The Hotel is not liable for the loss or theft of cash,
                            jewellery, or other valuables left unsecured in guest rooms.  Safe-deposit
                            facilities are available at the front desk for items of significant
                            value.</p>

                        <p class="legal-sub">Service availability</p>
                        <p>We will use reasonable efforts to maintain uninterrupted access to
                            the Service.  However, we do not warrant that the Service will be
                            available at all times, and we accept no liability for losses resulting
                            from temporary outages, maintenance windows, or circumstances outside
                            our control.</p>

                        <div class="legal-notice">
                            <strong>Limitation of liability.</strong> We are not liable for any
                            indirect, incidental, special, or consequential losses (including
                            loss of profit, loss of business, or loss of data) arising from your
                            use of the Service or your stay, even if we have been advised of the
                            possibility of such losses.
                        </div>
                    </div>
                </div>

                <!-- 10 -->
                <div class="legal-section" id="ip">
                    <span class="legal-section__number">Section 10</span>
                    <h2 class="legal-section__title">Intellectual Property</h2>
                    <div class="legal-section__body">
                        <p>All content on this website — including text, photographs, graphics,
                            logos, room descriptions, pricing information, the "Grand Horizon" name
                            and trade dress — is the exclusive property of Grand Horizon Hotel or
                            its licensors and is protected by the Copyright Act, 1957, the Trade
                            Marks Act, 1999, and other applicable Indian and international
                            intellectual property law.</p>

                        <p>You may not reproduce, distribute, modify, publicly display, or
                            create derivative works from any content on this website without our
                            prior written consent.  Limited personal, non-commercial use (e.g.
                            printing a booking confirmation for your own records) is permitted.</p>
                    </div>
                </div>

                <!-- 11 -->
                <div class="legal-section" id="reviews">
                    <span class="legal-section__number">Section 11</span>
                    <h2 class="legal-section__title">Guest Reviews</h2>
                    <div class="legal-section__body">
                        <p>By submitting a review through the Service, you grant Grand Horizon
                            Hotel a non-exclusive, royalty-free, perpetual licence to display,
                            reproduce, and adapt your review text and star rating on our website
                            and in our promotional materials.</p>

                        <p class="legal-sub">Review guidelines</p>
                        <ul class="legal-list">
                            <li>Reviews must relate to an actual stay completed at the Hotel via a verified booking.</li>
                            <li>Reviews must not contain defamatory, false, or misleading statements.</li>
                            <li>Reviews must not include personal attacks on individual staff members by name.</li>
                            <li>Reviews must not contain offensive language, hate speech, or discriminatory content.</li>
                            <li>Reviews must not include personal data of third parties (e.g. other guests).</li>
                        </ul>

                        <p>We reserve the right to moderate, edit, or remove reviews that
                            violate these guidelines without prior notice.  All submitted reviews
                            enter a moderation queue and appear publicly only after approval.</p>
                    </div>
                </div>

                <!-- 12 -->
                <div class="legal-section" id="termination">
                    <span class="legal-section__number">Section 12</span>
                    <h2 class="legal-section__title">Account Termination</h2>
                    <div class="legal-section__body">
                        <p>We reserve the right to suspend or permanently terminate your
                            account and deny access to the Service, at our discretion and without
                            prior notice, if we believe you have:</p>
                        <ul class="legal-list">
                            <li>Violated any provision of these Terms.</li>
                            <li>Provided false or misleading information during registration or booking.</li>
                            <li>Used the Service to commit fraud, including chargeback abuse or false reservation of rooms.</li>
                            <li>Engaged in conduct that is harmful to other guests, Hotel staff, or the Hotel's reputation.</li>
                        </ul>
                        <p>Upon termination, any pending bookings associated with your account
                            will be cancelled and the standard cancellation policy (Section 6) will
                            apply.  You may appeal a termination decision by writing to
                            <a href="mailto:legal@grandhorizon.in">legal@grandhorizon.in</a>.</p>
                    </div>
                </div>

                <!-- 13 -->
                <div class="legal-section" id="disputes">
                    <span class="legal-section__number">Section 13</span>
                    <h2 class="legal-section__title">Dispute Resolution &amp; Governing Law</h2>
                    <div class="legal-section__body">
                        <p class="legal-sub">Informal resolution</p>
                        <p>If you have a complaint about the Service or your stay, please
                            contact us first at <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a>
                            or call <a href="tel:+919321132636">+91 93211 32636</a>.  We will
                            endeavour to resolve all complaints within 14 working days.</p>

                        <p class="legal-sub">Consumer forum</p>
                        <p>If we are unable to resolve your complaint informally, you have the
                            right to file a complaint with the District Consumer Disputes Redressal
                            Forum, Amritsar, under the Consumer Protection Act, 2019.</p>

                        <p class="legal-sub">Governing law &amp; jurisdiction</p>
                        <p>These Terms are governed by and construed in accordance with the
                            laws of India.  Any dispute, claim, or controversy arising out of or
                            relating to these Terms or your use of the Service that is not resolved
                            informally shall be subject to the exclusive jurisdiction of the courts
                            of Amritsar, Punjab, India.</p>
                    </div>
                </div>

                <!-- 14 -->
                <div class="legal-section" id="changes">
                    <span class="legal-section__number">Section 14</span>
                    <h2 class="legal-section__title">Changes to These Terms</h2>
                    <div class="legal-section__body">
                        <p>We may update these Terms at any time.  When we make material changes
                            we will update the "Last Updated" date at the top of this page and, for
                            registered users, send a notification email at least 14 days before the
                            new Terms take effect.</p>
                        <p>Your continued use of the Service after the effective date of
                            revised Terms constitutes your acceptance.  If you do not agree with
                            the changes, you must stop using the Service and cancel any future
                            bookings before the new Terms take effect.</p>
                    </div>
                </div>

                <!-- 15 -->
                <div class="legal-section" id="contact-legal">
                    <span class="legal-section__number">Section 15</span>
                    <h2 class="legal-section__title">Contact Us</h2>
                    <div class="legal-section__body">
                        <p>For questions about these Terms, to exercise your legal rights, or
                            to report a concern, please contact our Legal &amp; Compliance team:</p>
                    </div>
                    <div class="legal-contact-card">
                        <div class="legal-contact-card__icon">
                            <svg width="20" height="20" fill="none" stroke="currentColor"
                                 stroke-width="1.8" viewBox="0 0 24 24">
                                <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
                                <polyline points="14 2 14 8 20 8"/>
                                <line x1="16" y1="13" x2="8" y2="13"/>
                                <line x1="16" y1="17" x2="8" y2="17"/>
                            </svg>
                        </div>
                        <div>
                            <p class="legal-contact-card__title">Legal &amp; Compliance</p>
                            <p class="legal-contact-card__text">
                                Grand Horizon Hotel<br>
                                12, Palace Road, Near Golden Temple<br>
                                Amritsar, Punjab — 143001, India<br><br>
                                Email: <a href="mailto:legal@grandhorizon.in">legal@grandhorizon.in</a><br>
                                Phone: <a href="tel:+919321132636">+91 93211 32636</a><br>
                                Response time: within 14 working days
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Sibling page link -->
                <a href="privacy-policy.jsp" class="legal-sibling">
                    <div>
                        <p class="legal-sibling__label">Also Read</p>
                        <p class="legal-sibling__title">← Privacy Policy</p>
                    </div>
                    <span class="legal-sibling__arrow">‹</span>
                </a>

            </article>
        </div><!-- /legal-layout -->
    </div><!-- /container -->
</div><!-- /legal-page -->

<!-- ── Footer ───────────────────────────────────────────────── -->
<footer class="footer">
    <div class="container">
        <div class="footer__grid">
            <div>
                <p class="footer__brand">Grand Horizon</p>
                <p class="footer__tagline">A sanctuary of refined luxury, where every stay becomes a cherished memory.</p>
            </div>
            <div>
                <p class="footer__heading">Navigation</p>
                <ul class="footer__links">
                    <li><a href="index.jsp">Home</a></li>
                    <li><a href="rooms.jsp">Rooms &amp; Suites</a></li>
                    <li><a href="booking.jsp">Reservations</a></li>
                    <li><a href="contact.jsp">Contact Us</a></li>
                </ul>
            </div>
            <div>
                <p class="footer__heading">Account</p>
                <ul class="footer__links">
                    <li><a href="login.jsp">Sign In</a></li>
                    <li><a href="register.jsp">Register</a></li>
                    <li><a href="user-dashboard.jsp">My Bookings</a></li>
                </ul>
            </div>
            <div>
                <p class="footer__heading">Legal</p>
                <ul class="footer__links">
                    <li><a href="privacy-policy.jsp">Privacy Policy</a></li>
                    <li><a href="terms-of-service.jsp" style="color:var(--gold);">Terms of Service</a></li>
                    <li><a href="contact.jsp">Contact Us</a></li>
                </ul>
            </div>
        </div>
        <div class="footer__bottom">
            <span>&copy; 2026 Grand Horizon Hotel. All rights reserved.</span>
            <span>
        <a href="privacy-policy.jsp">Privacy Policy</a>
        &nbsp;·&nbsp;
        <a href="terms-of-service.jsp" style="color:var(--gold);">Terms of Service</a>
      </span>
        </div>
    </div>
</footer>

<script>
    /* ── Scroll spy for table of contents ── */
    const sections = document.querySelectorAll('.legal-section');
    const tocLinks = document.querySelectorAll('.legal-toc__item');

    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                tocLinks.forEach(link => {
                    link.classList.toggle('active',
                        link.getAttribute('href') === '#' + entry.target.id);
                });
            }
        });
    }, { rootMargin: '-20% 0px -70% 0px' });

    sections.forEach(s => observer.observe(s));

    /* ── Smooth TOC click ── */
    tocLinks.forEach(link => {
        link.addEventListener('click', e => {
            e.preventDefault();
            const target = document.querySelector(link.getAttribute('href'));
            if (target) target.scrollIntoView({ behavior: 'smooth' });
        });
    });
</script>
</body>
</html>
