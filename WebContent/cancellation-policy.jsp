<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cancellation Policy — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Reuses all .legal-* classes from privacy-policy.jsp ── */

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
            position: absolute; inset: 0;
            background: radial-gradient(ellipse 55% 60% at 50% 0%,
            rgba(200,170,100,0.07) 0%, transparent 65%);
            pointer-events: none;
        }
        .legal-hero__eyebrow {
            display: block;
            font-size: 0.62rem; letter-spacing: 0.45em;
            text-transform: uppercase; color: var(--gold); margin-bottom: 1rem;
        }
        .legal-hero__title {
            font-family: var(--font-display);
            font-size: clamp(2.2rem, 5vw, 3.6rem);
            font-weight: 300; line-height: 1.15; margin-bottom: 1rem;
        }
        .legal-hero__title em { font-style: italic; color: var(--gold-light); }
        .legal-hero__meta {
            font-size: 0.8rem; color: var(--text-muted);
            display: flex; align-items: center; justify-content: center;
            gap: 1.5rem; flex-wrap: wrap; margin-top: 1.2rem;
        }
        .legal-hero__meta-item { display: flex; align-items: center; gap: 0.4rem; }
        .legal-hero__meta-item svg { width: 13px; height: 13px; color: var(--gold-muted); }

        .legal-layout {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 4rem; align-items: start;
            padding: 4rem 0 6rem;
        }

        /* ── Sticky TOC ── */
        .legal-toc {
            position: sticky; top: 7rem;
            background: var(--surface); border: 1px solid var(--border);
            border-radius: var(--radius-md); overflow: hidden;
        }
        .legal-toc__header {
            padding: 1rem 1.4rem; background: var(--charcoal);
            border-bottom: 1px solid var(--border);
            font-size: 0.62rem; letter-spacing: 0.3em;
            text-transform: uppercase; color: var(--gold);
        }
        .legal-toc__list { padding: 0.6rem 0; }
        .legal-toc__item {
            display: block; padding: 0.55rem 1.4rem;
            font-size: 0.8rem; color: var(--text-secondary);
            text-decoration: none; transition: var(--transition);
            border-left: 2px solid transparent; line-height: 1.4;
        }
        .legal-toc__item:hover {
            color: var(--gold); background: var(--gold-glow);
            border-left-color: var(--gold-muted);
        }
        .legal-toc__item.active {
            color: var(--gold); background: var(--gold-glow);
            border-left-color: var(--gold);
        }

        /* ── Article ── */
        .legal-article { max-width: 780px; }

        .legal-section { margin-bottom: 3.5rem; scroll-margin-top: 7rem; }
        .legal-section__number {
            display: inline-block; font-size: 0.6rem;
            letter-spacing: 0.35em; text-transform: uppercase;
            color: var(--gold); margin-bottom: 0.6rem;
        }
        .legal-section__title {
            font-family: var(--font-display); font-size: 1.55rem;
            font-weight: 400; color: var(--text-primary);
            margin-bottom: 1.2rem; padding-bottom: 0.8rem;
            border-bottom: 1px solid var(--border);
        }
        .legal-section__body {
            font-size: 0.93rem; color: var(--text-secondary); line-height: 1.95;
        }
        .legal-section__body p { margin-bottom: 1rem; }
        .legal-section__body p:last-child { margin-bottom: 0; }

        .legal-sub {
            font-size: 0.75rem; letter-spacing: 0.18em;
            text-transform: uppercase; color: var(--text-primary);
            font-weight: 500; margin: 1.5rem 0 0.6rem;
        }

        .legal-list {
            list-style: none; margin: 0.6rem 0 1rem; padding: 0;
            display: flex; flex-direction: column; gap: 0.5rem;
        }
        .legal-list li {
            display: flex; align-items: flex-start; gap: 0.8rem;
            font-size: 0.93rem; color: var(--text-secondary); line-height: 1.7;
        }
        .legal-list li::before {
            content: ''; width: 5px; height: 5px; border-radius: 50%;
            background: var(--gold-muted); flex-shrink: 0; margin-top: 0.55em;
        }

        /* ── Info highlight box (gold) ── */
        .legal-highlight {
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-left: 3px solid var(--gold-muted);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem; margin: 1.2rem 0;
            font-size: 0.88rem; color: var(--text-secondary); line-height: 1.8;
        }
        .legal-highlight strong { color: var(--gold); font-weight: 500; }

        /* ── Warning box (red) ── */
        .legal-notice {
            background: rgba(192,81,58,0.07);
            border: 1px solid rgba(192,81,58,0.22);
            border-left: 3px solid var(--error);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem; margin: 1.2rem 0;
            font-size: 0.88rem; color: var(--text-secondary); line-height: 1.8;
        }
        .legal-notice strong { color: #d9705a; font-weight: 500; }

        /* ── Success box (green) ── */
        .legal-success {
            background: rgba(74,140,106,0.08);
            border: 1px solid rgba(74,140,106,0.25);
            border-left: 3px solid var(--success);
            border-radius: var(--radius-sm);
            padding: 1.2rem 1.5rem; margin: 1.2rem 0;
            font-size: 0.88rem; color: var(--text-secondary); line-height: 1.8;
        }
        .legal-success strong { color: #5ebd8a; font-weight: 500; }

        /* ── Cancellation table ── */
        .cancel-table {
            width: 100%; border-collapse: collapse;
            margin: 1rem 0; font-size: 0.87rem;
        }
        .cancel-table th {
            padding: 0.8rem 1.2rem;
            background: var(--charcoal);
            border: 1px solid var(--border);
            font-size: 0.65rem; letter-spacing: 0.18em;
            text-transform: uppercase; color: var(--text-muted);
            font-weight: 500; text-align: left;
        }
        .cancel-table td {
            padding: 0.9rem 1.2rem;
            border: 1px solid var(--border);
            color: var(--text-secondary); vertical-align: middle;
            line-height: 1.6;
        }
        .cancel-table tbody tr:nth-child(even) td {
            background: rgba(255,255,255,0.015);
        }
        .cancel-table tbody tr:hover td {
            background: rgba(200,170,100,0.03);
            color: var(--text-primary);
        }
        /* Colour-coded charge column */
        .charge-free    { color: #4a8c6a; font-weight: 500; }
        .charge-partial { color: var(--warning); font-weight: 500; }
        .charge-full    { color: var(--error); font-weight: 500; }

        /* ── Step-by-step how-to ── */
        .how-to-steps {
            display: flex; flex-direction: column; gap: 1.2rem;
            margin-top: 1.2rem;
        }
        .how-to-step {
            display: flex; align-items: flex-start; gap: 1.2rem;
            padding: 1.2rem 1.4rem;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            transition: var(--transition);
        }
        .how-to-step:hover {
            border-color: var(--border-light);
            background: var(--surface-2);
        }
        .how-to-step__num {
            width: 32px; height: 32px; border-radius: 50%;
            border: 1px solid var(--gold-muted);
            background: var(--gold-glow);
            color: var(--gold); font-weight: 600; font-size: 0.78rem;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .how-to-step__title {
            font-size: 0.88rem; font-weight: 500;
            color: var(--text-primary); margin-bottom: 0.3rem;
        }
        .how-to-step__desc {
            font-size: 0.83rem; color: var(--text-secondary); line-height: 1.7;
        }

        /* ── Contact card ── */
        .legal-contact-card {
            background: var(--surface);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-md);
            padding: 2rem; margin-top: 3rem;
            display: flex; align-items: flex-start; gap: 1.5rem;
        }
        .legal-contact-card__icon {
            width: 44px; height: 44px;
            background: var(--gold-glow); border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            display: flex; align-items: center; justify-content: center;
            color: var(--gold); flex-shrink: 0;
        }
        .legal-contact-card__title {
            font-family: var(--font-display); font-size: 1.1rem;
            font-weight: 400; margin-bottom: 0.4rem;
        }
        .legal-contact-card__text {
            font-size: 0.85rem; color: var(--text-secondary); line-height: 1.75;
        }
        .legal-contact-card__text a { color: var(--gold); }

        /* ── Sibling page links ── */
        .legal-siblings {
            display: grid; grid-template-columns: 1fr 1fr;
            gap: 0.75rem; margin-top: 2rem;
        }
        .legal-sibling {
            display: flex; align-items: center; justify-content: space-between;
            background: var(--charcoal); border: 1px solid var(--border);
            border-radius: var(--radius-sm); padding: 1.2rem 1.5rem;
            text-decoration: none; transition: var(--transition);
        }
        .legal-sibling:hover {
            border-color: var(--border-light); background: var(--surface);
        }
        .legal-sibling__label {
            font-size: 0.65rem; letter-spacing: 0.2em;
            text-transform: uppercase; color: var(--text-muted); margin-bottom: 0.25rem;
        }
        .legal-sibling__title {
            font-family: var(--font-display); font-size: 1rem; color: var(--gold-light);
        }
        .legal-sibling__arrow { color: var(--gold-muted); font-size: 1.2rem; }

        @media (max-width: 900px) {
            .legal-layout { grid-template-columns: 1fr; gap: 2rem; }
            .legal-toc    { position: static; display: flex; flex-wrap: wrap; }
            .legal-toc__list { display: flex; flex-wrap: wrap; padding: 0.4rem; }
            .legal-toc__item {
                border-left: none; border-bottom: 2px solid transparent;
                padding: 0.4rem 0.9rem; white-space: nowrap; font-size: 0.75rem;
            }
            .legal-toc__item.active { border-left: none; border-bottom-color: var(--gold); }
            .legal-siblings { grid-template-columns: 1fr; }
        }
        @media (max-width: 580px) {
            .legal-hero { padding: 5rem 0 3rem; }
            .cancel-table { display: block; overflow-x: auto; }
        }
    </style>
</head>
<body>

<!-- ── Navbar ───────────────────────────────────────────────── -->
<nav class="navbar scrolled">
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
            <span class="legal-hero__eyebrow">Guest Policies</span>
            <h1 class="legal-hero__title">Cancellation <em>Policy</em></h1>
            <div class="section-divider"></div>
            <div class="legal-hero__meta">
        <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <rect x="3" y="4" width="18" height="18" rx="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8"  y1="2" x2="8"  y2="6"/>
            <line x1="3"  y1="10" x2="21" y2="10"/>
          </svg>
          Effective Date: 1 January 2026
        </span>
                <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10"/>
            <polyline points="12 6 12 12 16 14"/>
          </svg>
          Last Updated: 1 March 2026
        </span>
                <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
            <circle cx="12" cy="10" r="3"/>
          </svg>
          Grand Horizon, Amritsar
        </span>
            </div>
        </div>
    </div>

    <!-- ── Body ──────────────────────────────────────────────────── -->
    <div class="container">
        <div class="legal-layout">

            <!-- ── Table of Contents ── -->
            <aside class="legal-toc" id="toc">
                <div class="legal-toc__header">Contents</div>
                <nav class="legal-toc__list">
                    <a href="#overview"     class="legal-toc__item active">1. Overview</a>
                    <a href="#standard"     class="legal-toc__item">2. Standard Policy</a>
                    <a href="#non-refund"   class="legal-toc__item">3. Non-Refundable Rates</a>
                    <a href="#group"        class="legal-toc__item">4. Group Bookings</a>
                    <a href="#noshow"       class="legal-toc__item">5. No-Show Policy</a>
                    <a href="#modify"       class="legal-toc__item">6. Modifications</a>
                    <a href="#refunds"      class="legal-toc__item">7. Refund Process</a>
                    <a href="#force"        class="legal-toc__item">8. Force Majeure</a>
                    <a href="#howto"        class="legal-toc__item">9. How to Cancel</a>
                    <a href="#disputes"     class="legal-toc__item">10. Disputes</a>
                    <a href="#contact-cp"   class="legal-toc__item">11. Contact Us</a>
                </nav>
            </aside>

            <!-- ── Article ── -->
            <article class="legal-article">

                <!-- Preamble -->
                <div class="legal-highlight" style="margin-bottom:2.5rem;">
                    <strong>Free cancellation is available on most bookings</strong>
                    when cancelled more than 48 hours before the check-in date.
                    Please read this policy carefully before making a reservation.
                    By completing a booking you agree to the terms set out below.
                </div>

                <!-- ── 1. Overview ── -->
                <div class="legal-section" id="overview">
                    <span class="legal-section__number">Section 01</span>
                    <h2 class="legal-section__title">Overview</h2>
                    <div class="legal-section__body">
                        <p>This Cancellation Policy governs all reservations made through the
                            Grand Horizon Hotel website, mobile application, front desk, or telephone
                            reservation line. It applies to all room types, including Deluxe Rooms,
                            Twin Rooms, Family Suites, Junior Suites, Executive Suites, and the
                            Presidential Suite.</p>

                        <p>The policy applicable to your booking is the one in effect on the
                            date your reservation is confirmed. Grand Horizon reserves the right to
                            update this policy; changes will not apply to bookings already confirmed
                            before the update date.</p>

                        <div class="legal-success">
                            <strong>Quick summary.</strong> Cancel more than 48 hours before
                            check-in → full refund, no charge.
                            Cancel within 48 hours → one night's charge.
                            No-show → full booking amount charged.
                        </div>
                    </div>
                </div>

                <!-- ── 2. Standard Policy ── -->
                <div class="legal-section" id="standard">
                    <span class="legal-section__number">Section 02</span>
                    <h2 class="legal-section__title">Standard Cancellation Policy</h2>
                    <div class="legal-section__body">
                        <p>The following charges apply to cancellations of standard-rate
                            bookings. Notice is measured from the date and time the cancellation
                            request is <em>received and confirmed</em> by Grand Horizon — not from
                            the date the request is sent.</p>

                        <table class="cancel-table">
                            <thead>
                            <tr>
                                <th>Notice Given Before Check-In</th>
                                <th>Cancellation Charge</th>
                                <th>Refund</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td><strong>More than 48 hours</strong></td>
                                <td class="charge-free">No charge</td>
                                <td>100% refund of total amount paid</td>
                            </tr>
                            <tr>
                                <td><strong>24 to 48 hours</strong></td>
                                <td class="charge-partial">1 night's room rate + GST</td>
                                <td>Remaining nights refunded</td>
                            </tr>
                            <tr>
                                <td><strong>Less than 24 hours</strong></td>
                                <td class="charge-full">100% of total booking amount</td>
                                <td>No refund</td>
                            </tr>
                            <tr>
                                <td><strong>No-show</strong></td>
                                <td class="charge-full">100% of total booking amount</td>
                                <td>No refund</td>
                            </tr>
                            </tbody>
                        </table>

                        <p class="legal-sub">Example</p>
                        <p>A guest books a Junior Suite for 3 nights at ₹15,000/night
                            (total ₹50,400 including 12% GST). If they cancel 30 hours before
                            check-in, one night's charge of ₹16,800 (₹15,000 + ₹1,800 GST)
                            is retained and ₹33,600 is refunded to the original payment method.</p>

                        <div class="legal-highlight">
                            <strong>Time zone.</strong> All cancellation deadlines are calculated
                            in Indian Standard Time (IST, UTC+5:30). Check-in is at 2:00 PM IST.
                            For example, a guest checking in on 20 March must cancel by 2:00 PM
                            IST on 18 March to receive a full refund.
                        </div>
                    </div>
                </div>

                <!-- ── 3. Non-Refundable Rates ── -->
                <div class="legal-section" id="non-refund">
                    <span class="legal-section__number">Section 03</span>
                    <h2 class="legal-section__title">Non-Refundable Rates</h2>
                    <div class="legal-section__body">
                        <p>Certain promotional rates, advance-purchase deals, and packages
                            offered on our website are marked as <strong>"Non-Refundable"</strong>
                            at the time of booking. These rates are offered at a discount precisely
                            because they cannot be cancelled or modified after confirmation.</p>

                        <div class="legal-notice">
                            <strong>Non-refundable bookings are charged in full at the time of
                                confirmation</strong> and no refund will be issued under any
                            circumstances, including early check-out, illness, or change of plans.
                            Please book non-refundable rates only when your plans are certain.
                        </div>

                        <p>Non-refundable rates will be clearly labelled before you complete
                            checkout. If the rate label is not visible during the booking process,
                            the standard cancellation policy in Section 2 applies.</p>

                        <p class="legal-sub">Upgrade exception</p>
                        <p>If you hold a non-refundable booking and wish to upgrade to a
                            higher room category, the upgrade fee is charged separately at the
                            prevailing rate. The original non-refundable payment remains
                            non-refundable.</p>
                    </div>
                </div>

                <!-- ── 4. Group Bookings ── -->
                <div class="legal-section" id="group">
                    <span class="legal-section__number">Section 04</span>
                    <h2 class="legal-section__title">Group Bookings</h2>
                    <div class="legal-section__body">
                        <p>A <strong>group booking</strong> is defined as a simultaneous
                            reservation of 5 or more rooms for overlapping dates. Group bookings
                            are subject to a separate cancellation policy agreed in the group
                            contract signed at the time of confirmation.</p>

                        <p class="legal-sub">Standard group cancellation schedule</p>
                        <p>In the absence of a specific group contract, the following default
                            schedule applies:</p>

                        <table class="cancel-table">
                            <thead>
                            <tr>
                                <th>Notice Given Before Check-In</th>
                                <th>Cancellation Charge</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td><strong>More than 30 days</strong></td>
                                <td class="charge-free">No charge</td>
                            </tr>
                            <tr>
                                <td><strong>15 to 30 days</strong></td>
                                <td class="charge-partial">25% of total group booking value</td>
                            </tr>
                            <tr>
                                <td><strong>7 to 14 days</strong></td>
                                <td class="charge-partial">50% of total group booking value</td>
                            </tr>
                            <tr>
                                <td><strong>Less than 7 days</strong></td>
                                <td class="charge-full">100% of total group booking value</td>
                            </tr>
                            </tbody>
                        </table>

                        <p>For group bookings, cancellation of individual rooms within the
                            group block is permitted up to 15 days before check-in without charge,
                            provided the remaining block is at least 5 rooms. Reductions below
                            5 rooms convert the remaining reservation to the standard individual
                            cancellation policy in Section 2.</p>

                        <p>To enquire about group bookings or review your group contract,
                            contact our events team at
                            <a href="mailto:groups@grandhorizon.in">groups@grandhorizon.in</a>.</p>
                    </div>
                </div>

                <!-- ── 5. No-Show Policy ── -->
                <div class="legal-section" id="noshow">
                    <span class="legal-section__number">Section 05</span>
                    <h2 class="legal-section__title">No-Show Policy</h2>
                    <div class="legal-section__body">
                        <p>A <strong>no-show</strong> occurs when a guest fails to arrive at
                            the Hotel on the confirmed check-in date without prior cancellation.
                            In all cases, the full booking amount will be charged to the registered
                            payment method and no refund will be issued.</p>

                        <ul class="legal-list">
                            <li>The room will be held until <strong>12:00 midnight IST</strong> on the check-in date. After this time, the room may be released and re-sold at the Hotel's discretion.</li>
                            <li>If you anticipate a late arrival, please notify our front desk at <a href="tel:+911234567890">+91 12345 67890</a> before 6:00 PM on your check-in date. We will make every effort to hold the room, subject to availability.</li>
                            <li>Notifying us of a late arrival does not constitute a cancellation or modification of your booking and does not waive the no-show charge if you subsequently fail to arrive.</li>
                        </ul>

                        <div class="legal-notice">
                            <strong>Important.</strong> Failure to check in does not automatically
                            cancel subsequent nights in a multi-night booking. Charges for all
                            reserved nights will apply unless cancelled in advance in accordance
                            with Section 2.
                        </div>
                    </div>
                </div>

                <!-- ── 6. Modifications ── -->
                <div class="legal-section" id="modify">
                    <span class="legal-section__number">Section 06</span>
                    <h2 class="legal-section__title">Booking Modifications</h2>
                    <div class="legal-section__body">

                        <p class="legal-sub">Date changes</p>
                        <p>A request to change your check-in or check-out date is treated as a
                            cancellation of the original booking and creation of a new booking at
                            the rate available at the time of the change. If the new dates are not
                            available, the original booking remains in force.</p>

                        <p>If a date change is requested more than 48 hours before the original
                            check-in date, no cancellation charge applies to the original booking.
                            Within 48 hours, Section 2 charges apply.</p>

                        <p class="legal-sub">Room type changes</p>
                        <p>A request to change the room type is subject to availability. An
                            upgrade is charged at the difference in rate for the remaining nights.
                            A downgrade may be granted at the discretion of the Hotel; the difference
                            is not refunded on non-refundable bookings.</p>

                        <p class="legal-sub">Early check-out</p>
                        <p>If you check out before your confirmed checkout date, the unused
                            nights will be charged at the full rate per night unless:</p>
                        <ul class="legal-list">
                            <li>You provide at least 24 hours' written notice to the front desk, <strong>and</strong></li>
                            <li>The early departure falls within the free-cancellation window (more than 48 hours before the original checkout date).</li>
                        </ul>
                        <p>Otherwise, the full booking amount for all reserved nights is
                            retained.</p>

                        <p class="legal-sub">Adding nights</p>
                        <p>To extend your stay, contact the front desk or reservations team
                            at least 24 hours before your current checkout date. Extension is subject
                            to room availability and will be charged at the prevailing rate for the
                            additional nights.</p>
                    </div>
                </div>

                <!-- ── 7. Refund Process ── -->
                <div class="legal-section" id="refunds">
                    <span class="legal-section__number">Section 07</span>
                    <h2 class="legal-section__title">Refund Process</h2>
                    <div class="legal-section__body">

                        <p>Where a refund is due under this policy, it will be processed as
                            follows:</p>

                        <table class="cancel-table">
                            <thead>
                            <tr>
                                <th>Payment Method</th>
                                <th>Refund Timeline</th>
                                <th>Refund Route</th>
                            </tr>
                            </thead>
                            <tbody>
                            <tr>
                                <td>Credit / Debit Card (Razorpay)</td>
                                <td>5 – 7 business days</td>
                                <td>Original card</td>
                            </tr>
                            <tr>
                                <td>UPI</td>
                                <td>1 – 3 business days</td>
                                <td>Original UPI VPA / bank account</td>
                            </tr>
                            <tr>
                                <td>Net Banking</td>
                                <td>5 – 7 business days</td>
                                <td>Original bank account</td>
                            </tr>
                            <tr>
                                <td>Wallet (Paytm, PhonePe, etc.)</td>
                                <td>1 – 3 business days</td>
                                <td>Original wallet</td>
                            </tr>
                            <tr>
                                <td>Cash (paid at front desk)</td>
                                <td>Same day at front desk</td>
                                <td>Cash refund at property</td>
                            </tr>
                            </tbody>
                        </table>

                        <p>Refund timelines begin from the date the cancellation is confirmed
                            by Grand Horizon. Processing times may vary depending on your bank or
                            payment provider.</p>

                        <ul class="legal-list">
                            <li>Refunds are always issued in Indian Rupees (INR). If your original payment was made in a foreign currency, your bank's exchange rate at the time of refund applies.</li>
                            <li>Any foreign currency conversion fees or bank charges levied by your card issuer are not the responsibility of Grand Horizon.</li>
                            <li>If you have not received your refund within the stated timeline, first check with your bank, then contact us at <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a> with your Booking Reference.</li>
                            <li>GST included in the original charge will be refunded proportionally. We will issue a revised GST invoice within 7 business days of the refund.</li>
                        </ul>

                        <div class="legal-highlight">
                            <strong>Razorpay refunds.</strong> Online payments processed through
                            Razorpay are refunded directly by Razorpay to your original payment
                            instrument. Your refund status can be tracked at
                            <a href="https://razorpay.com" target="_blank" rel="noopener">razorpay.com</a>
                            using your Payment ID (visible in your booking confirmation email).
                        </div>
                    </div>
                </div>

                <!-- ── 8. Force Majeure ── -->
                <div class="legal-section" id="force">
                    <span class="legal-section__number">Section 08</span>
                    <h2 class="legal-section__title">Force Majeure &amp; Exceptional Circumstances</h2>
                    <div class="legal-section__body">
                        <p>Grand Horizon will waive cancellation charges — including on
                            non-refundable bookings — where the cancellation is directly caused
                            by an event beyond the guest's reasonable control, provided that the
                            guest supplies documentary evidence within 7 days of the cancellation.
                            Qualifying events include:</p>

                        <ul class="legal-list">
                            <li><strong>Natural disasters</strong> — earthquakes, floods, cyclones, or other declared natural calamities affecting either the guest's place of origin or Amritsar.</li>
                            <li><strong>Government-declared emergencies</strong> — lockdowns, curfews, or travel restrictions issued by Central or State Government authorities that directly prevent travel.</li>
                            <li><strong>Public health emergencies</strong> — pandemics or epidemics declared by the World Health Organisation or the Indian Government that prevent domestic travel.</li>
                            <li><strong>Bereavement</strong> — death of an immediate family member (spouse, child, parent, or sibling) occurring within 7 days of the check-in date. A copy of the death certificate is required.</li>
                            <li><strong>Serious illness or hospitalisation</strong> — where the guest or their travelling companion is hospitalised and medically unfit to travel. A doctor's certificate on letterhead is required.</li>
                        </ul>

                        <p>Grand Horizon may, at its sole discretion, offer a credit note valid
                            for 12 months as an alternative to a cash refund in force-majeure
                            situations. The credit note can be used for any future booking at the
                            Hotel.</p>

                        <p>Minor inconveniences, change of plans, work commitments, or financial
                            circumstances do not qualify as force majeure events.</p>
                    </div>
                </div>

                <!-- ── 9. How to Cancel ── -->
                <div class="legal-section" id="howto">
                    <span class="legal-section__number">Section 09</span>
                    <h2 class="legal-section__title">How to Cancel Your Booking</h2>
                    <div class="legal-section__body">
                        <p>You may cancel your booking through any of the following methods.
                            The cancellation is effective from the date and time Grand Horizon
                            <strong>confirms receipt</strong> of your cancellation — not from when
                            you sent it.</p>

                        <div class="how-to-steps">

                            <div class="how-to-step">
                                <div class="how-to-step__num">1</div>
                                <div>
                                    <p class="how-to-step__title">Online — My Dashboard (Fastest)</p>
                                    <p class="how-to-step__desc">
                                        Sign in to your account at
                                        <a href="login.jsp">grandhorizon.in</a>,
                                        go to <strong>My Dashboard → My Bookings</strong>, find your
                                        booking and click <em>Cancel Booking</em>. You will receive an
                                        immediate on-screen confirmation and an email receipt.
                                        Available 24 hours a day, 7 days a week.
                                    </p>
                                </div>
                            </div>

                            <div class="how-to-step">
                                <div class="how-to-step__num">2</div>
                                <div>
                                    <p class="how-to-step__title">Email</p>
                                    <p class="how-to-step__desc">
                                        Send your cancellation request to
                                        <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a>
                                        with your <strong>Booking Reference</strong> (e.g. GH-2401)
                                        in the subject line. Our reservations team will confirm within
                                        2 business hours during operating hours (8:00 AM – 10:00 PM IST).
                                        Keep the confirmation email as proof of cancellation.
                                    </p>
                                </div>
                            </div>

                            <div class="how-to-step">
                                <div class="how-to-step__num">3</div>
                                <div>
                                    <p class="how-to-step__title">Telephone</p>
                                    <p class="how-to-step__desc">
                                        Call our reservations desk at
                                        <a href="tel:+919321132636">+91 93211 32636</a>
                                        (available 24 / 7). Quote your Booking Reference and ask for a
                                        cancellation confirmation number. We strongly recommend following
                                        up with a confirmation email to
                                        <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a>
                                        for your records.
                                    </p>
                                </div>
                            </div>

                            <div class="how-to-step">
                                <div class="how-to-step__num">4</div>
                                <div>
                                    <p class="how-to-step__title">Front Desk (In Person)</p>
                                    <p class="how-to-step__desc">
                                        Visit the Grand Horizon front desk at 12, Palace Road, Amritsar.
                                        Reception is open 24 hours. Bring a valid photo ID and your
                                        Booking Reference. A written cancellation confirmation will be
                                        issued on the spot.
                                    </p>
                                </div>
                            </div>

                        </div><!-- /how-to-steps -->

                        <div class="legal-notice" style="margin-top:1.5rem;">
                            <strong>Important.</strong> Cancellations requested via social media
                            direct messages, WhatsApp, or any channel other than those listed above
                            are not accepted and will not be processed. Always use the above
                            channels and retain written confirmation.
                        </div>
                    </div>
                </div>

                <!-- ── 10. Disputes ── -->
                <div class="legal-section" id="disputes">
                    <span class="legal-section__number">Section 10</span>
                    <h2 class="legal-section__title">Disputes &amp; Complaints</h2>
                    <div class="legal-section__body">
                        <p>If you disagree with a cancellation charge applied to your booking,
                            please follow this process:</p>

                        <ul class="legal-list">
                            <li><strong>Step 1 — Contact us directly.</strong> Email <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a> with your Booking Reference and a clear description of the dispute. We will respond within 5 business days.</li>
                            <li><strong>Step 2 — Escalate.</strong> If unsatisfied with our response, write to our General Manager at <a href="mailto:gm@grandhorizon.in">gm@grandhorizon.in</a>. The General Manager will personally review and respond within 10 business days.</li>
                            <li><strong>Step 3 — Consumer Forum.</strong> If the matter remains unresolved, you may file a complaint with the District Consumer Disputes Redressal Forum, Amritsar, under the Consumer Protection Act, 2019.</li>
                        </ul>

                        <p>Raising a dispute with your payment provider (chargeback) before
                            exhausting the above steps may delay resolution and could result in
                            the booking being treated as a no-show for future reservations.</p>
                    </div>
                </div>

                <!-- ── 11. Contact ── -->
                <div class="legal-section" id="contact-cp">
                    <span class="legal-section__number">Section 11</span>
                    <h2 class="legal-section__title">Contact Us</h2>
                    <div class="legal-section__body">
                        <p>For any questions about this Cancellation Policy or to submit a
                            cancellation request, please contact our Reservations team:</p>
                    </div>

                    <div class="legal-contact-card">
                        <div class="legal-contact-card__icon">
                            <svg width="20" height="20" fill="none" stroke="currentColor"
                                 stroke-width="1.8" viewBox="0 0 24 24">
                                <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013 6.18 2 2 0 015 4h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L9.09 11.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 18v-.08z"/>
                            </svg>
                        </div>
                        <div>
                            <p class="legal-contact-card__title">Reservations &amp; Cancellations</p>
                            <p class="legal-contact-card__text">
                                Grand Horizon Hotel<br>
                                12, Palace Road, Near Golden Temple<br>
                                Amritsar, Punjab — 143001, India<br><br>
                                Phone: <a href="tel:+919321132636">+91 93211 32636</a>
                                &nbsp;(24 / 7)<br>
                                Email: <a href="mailto:stay@grandhorizon.in">stay@grandhorizon.in</a><br>
                                Groups: <a href="mailto:groups@grandhorizon.in">groups@grandhorizon.in</a><br>
                                Response time: within 2 business hours
                            </p>
                        </div>
                    </div>
                </div><!-- /contact -->

                <!-- ── Sibling links ── -->
                <div class="legal-siblings">
                    <a href="privacy-policy.jsp" class="legal-sibling">
                        <div>
                            <p class="legal-sibling__label">Also Read</p>
                            <p class="legal-sibling__title">Privacy Policy</p>
                        </div>
                        <span class="legal-sibling__arrow">›</span>
                    </a>
                    <a href="terms-of-service.jsp" class="legal-sibling">
                        <div>
                            <p class="legal-sibling__label">Also Read</p>
                            <p class="legal-sibling__title">Terms of Service</p>
                        </div>
                        <span class="legal-sibling__arrow">›</span>
                    </a>
                </div>

            </article><!-- /legal-article -->
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
                    <li><a href="terms-of-service.jsp">Terms of Service</a></li>
                    <li><a href="cancellation-policy.jsp" style="color:var(--gold);">Cancellation Policy</a></li>
                </ul>
            </div>
        </div>
        <div class="footer__bottom">
            <span>&copy; 2025 Grand Horizon Hotel. All rights reserved.</span>
            <span>
        <a href="privacy-policy.jsp">Privacy Policy</a>
        &nbsp;·&nbsp;
        <a href="terms-of-service.jsp">Terms of Service</a>
        &nbsp;·&nbsp;
        <a href="cancellation-policy.jsp" style="color:var(--gold);">Cancellation Policy</a>
      </span>
        </div>
    </div>
</footer>

<script>
    /* ── Scroll spy ── */
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
