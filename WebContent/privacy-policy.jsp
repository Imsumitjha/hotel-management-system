<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Legal page layout ───────────────────────────────── */
        .legal-page {
            padding-top: 5rem;
            min-height: 100vh;
        }

        /* ── Hero banner ─────────────────────────────────────── */
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
            background:
                    radial-gradient(ellipse 55% 60% at 50% 0%,
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
        .legal-hero__title em {
            font-style: italic;
            color: var(--gold-light);
        }
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
        .legal-hero__meta-item svg {
            width: 13px;
            height: 13px;
            color: var(--gold-muted);
        }

        /* ── Body layout ─────────────────────────────────────── */
        .legal-layout {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 4rem;
            align-items: start;
            padding: 4rem 0 6rem;
        }

        /* ── Sticky table of contents ────────────────────────── */
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
        .legal-toc__list {
            padding: 0.6rem 0;
        }
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

        /* ── Article body ────────────────────────────────────── */
        .legal-article {
            max-width: 780px;
        }

        /* Section blocks */
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
        .legal-section__body p {
            margin-bottom: 1rem;
        }
        .legal-section__body p:last-child {
            margin-bottom: 0;
        }

        /* Sub-headings within a section */
        .legal-sub {
            font-size: 0.75rem;
            letter-spacing: 0.18em;
            text-transform: uppercase;
            color: var(--text-primary);
            font-weight: 500;
            margin: 1.5rem 0 0.6rem;
        }

        /* Bullet list */
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

        /* Highlight box */
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
        .legal-highlight strong {
            color: var(--gold);
            font-weight: 500;
        }

        /* Contact card at bottom */
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
            width: 44px;
            height: 44px;
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
        .legal-contact-card__text a {
            color: var(--gold);
        }

        /* Sibling-page link */
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
        .legal-sibling__title {
            font-family: var(--font-display);
            font-size: 1.1rem;
            color: var(--gold-light);
        }
        .legal-sibling__arrow {
            color: var(--gold-muted);
            font-size: 1.4rem;
        }

        @media (max-width: 900px) {
            .legal-layout {
                grid-template-columns: 1fr;
                gap: 2rem;
            }
            .legal-toc {
                position: static;
                display: flex;
                flex-wrap: wrap;
                overflow-x: auto;
                border-radius: var(--radius-sm);
            }
            .legal-toc__list {
                display: flex;
                flex-wrap: wrap;
                padding: 0.4rem;
            }
            .legal-toc__item {
                border-left: none;
                border-bottom: 2px solid transparent;
                padding: 0.4rem 0.9rem;
                white-space: nowrap;
                font-size: 0.75rem;
            }
            .legal-toc__item.active {
                border-left: none;
                border-bottom-color: var(--gold);
            }
        }
        @media (max-width: 580px) {
            .legal-hero { padding: 5rem 0 3rem; }
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
            <h1 class="legal-hero__title">Privacy <em>Policy</em></h1>
            <div class="section-divider"></div>
            <div class="legal-hero__meta">
        <span class="legal-hero__meta-item">
          <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
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
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
            <circle cx="12" cy="10" r="3"/>
          </svg>
          Amritsar, Punjab, India
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
                    <a href="#overview"       class="legal-toc__item active">1. Overview</a>
                    <a href="#data-collect"   class="legal-toc__item">2. Data We Collect</a>
                    <a href="#how-we-use"     class="legal-toc__item">3. How We Use It</a>
                    <a href="#sharing"        class="legal-toc__item">4. Data Sharing</a>
                    <a href="#cookies"        class="legal-toc__item">5. Cookies</a>
                    <a href="#retention"      class="legal-toc__item">6. Data Retention</a>
                    <a href="#security"       class="legal-toc__item">7. Security</a>
                    <a href="#your-rights"    class="legal-toc__item">8. Your Rights</a>
                    <a href="#children"       class="legal-toc__item">9. Children</a>
                    <a href="#third-party"    class="legal-toc__item">10. Third-Party Links</a>
                    <a href="#changes"        class="legal-toc__item">11. Policy Changes</a>
                    <a href="#contact-dpo"    class="legal-toc__item">12. Contact Us</a>
                </nav>
            </aside>

            <!-- Article -->
            <article class="legal-article">

                <!-- 1 -->
                <div class="legal-section" id="overview">
                    <span class="legal-section__number">Section 01</span>
                    <h2 class="legal-section__title">Overview</h2>
                    <div class="legal-section__body">
                        <p>Grand Horizon Hotel ("we", "us", "our") is committed to protecting the
                            privacy of every guest, visitor, and user who interacts with our website,
                            mobile interface, or any related digital service (collectively, the
                            "Service"). This Privacy Policy explains what personal data we collect,
                            why we collect it, how we store and protect it, and the rights available
                            to you under applicable Indian law.</p>

                        <p>By using our Service — including browsing our website, creating an
                            account, or making a reservation — you acknowledge that you have read and
                            understood this policy.  If you do not agree with any part of it, please
                            do not use the Service.</p>

                        <div class="legal-highlight">
                            <strong>Governing law.</strong> This policy is governed by the
                            <em>Information Technology Act, 2000</em> (IT Act), the
                            <em>Information Technology (Reasonable Security Practices and
                                Procedures and Sensitive Personal Data or Information) Rules, 2011</em>
                            (SPDI Rules), and, where applicable, the
                            <em>Digital Personal Data Protection Act, 2023</em> (DPDPA).
                        </div>
                    </div>
                </div>

                <!-- 2 -->
                <div class="legal-section" id="data-collect">
                    <span class="legal-section__number">Section 02</span>
                    <h2 class="legal-section__title">Data We Collect</h2>
                    <div class="legal-section__body">

                        <p class="legal-sub">Information you provide directly</p>
                        <ul class="legal-list">
                            <li><strong>Account data</strong> — first name, last name, email address, phone number, and password (stored as a salted PBKDF2-HMAC-SHA-256 hash, never in plain text).</li>
                            <li><strong>Booking data</strong> — room type, check-in and check-out dates, number of guests, special requests, and payment confirmation reference.</li>
                            <li><strong>Contact data</strong> — name, email, phone, subject, and message body submitted through the contact form.</li>
                            <li><strong>Review data</strong> — star rating, review title, and written review text you submit for a completed stay.</li>
                        </ul>

                        <p class="legal-sub">Information collected automatically</p>
                        <ul class="legal-list">
                            <li><strong>Log data</strong> — IP address, browser type and version, operating system, referring URL, pages visited, and timestamps of requests to our server.</li>
                            <li><strong>Session data</strong> — a server-side session identifier stored in a secure, HTTP-only cookie to keep you logged in during your visit.</li>
                            <li><strong>Device data</strong> — screen resolution and browser capabilities, used solely to optimise page rendering.</li>
                        </ul>

                        <p class="legal-sub">Information we do not collect</p>
                        <ul class="legal-list">
                            <li>Full credit or debit card numbers — payment processing is handled by our payment gateway partner; we only store the transaction reference.</li>
                            <li>Government-issued identification numbers (Aadhaar, PAN) unless required by law for extended stays.</li>
                            <li>Biometric data of any kind.</li>
                        </ul>
                    </div>
                </div>

                <!-- 3 -->
                <div class="legal-section" id="how-we-use">
                    <span class="legal-section__number">Section 03</span>
                    <h2 class="legal-section__title">How We Use Your Data</h2>
                    <div class="legal-section__body">
                        <p>We use the data we collect for the following purposes, all of which
                            are necessary to deliver the Service or are carried out with your
                            consent:</p>
                        <ul class="legal-list">
                            <li><strong>Reservation management</strong> — creating, confirming, modifying, and cancelling bookings; issuing invoices and GST receipts.</li>
                            <li><strong>Account services</strong> — authenticating your login, enabling password reset, and maintaining your booking history.</li>
                            <li><strong>Guest communications</strong> — sending booking confirmations, check-in reminders, and responses to contact form enquiries to the email address you provided.</li>
                            <li><strong>Service improvement</strong> — analysing aggregated, anonymised usage patterns to improve website performance, room offerings, and the booking experience.</li>
                            <li><strong>Review moderation</strong> — displaying approved guest reviews on room detail pages and removing reviews that violate our content guidelines.</li>
                            <li><strong>Legal compliance</strong> — retaining records required by the Companies Act, GST Act, and Tourism regulations applicable to registered hotels in India.</li>
                            <li><strong>Security</strong> — detecting fraudulent submissions, rate-limiting repeated form abuse, and logging authentication events in our audit trail.</li>
                        </ul>

                        <div class="legal-highlight">
                            <strong>We do not use your data for targeted advertising</strong>
                            and we do not sell, rent, or trade your personal information to
                            any third party for marketing purposes.
                        </div>
                    </div>
                </div>

                <!-- 4 -->
                <div class="legal-section" id="sharing">
                    <span class="legal-section__number">Section 04</span>
                    <h2 class="legal-section__title">Data Sharing</h2>
                    <div class="legal-section__body">
                        <p>We share personal data only in the following limited circumstances:</p>
                        <ul class="legal-list">
                            <li><strong>Service providers</strong> — trusted third-party vendors who process data on our behalf (e.g. payment gateway, email delivery service, web hosting). These partners are contractually bound to use your data solely to provide services to us and not for any independent purpose.</li>
                            <li><strong>Legal obligations</strong> — government authorities, tax bodies (GST Council), or courts when we are required to disclose information by law, court order, or enforceable governmental request.</li>
                            <li><strong>Hotel operations</strong> — relevant booking details (name, room, dates) are shared with our front-desk and housekeeping teams solely to prepare your stay.</li>
                            <li><strong>Business transfer</strong> — in the event of a merger, acquisition, or sale of assets, your data may be transferred to the successor entity, subject to equivalent privacy protections.</li>
                        </ul>
                        <p>In all cases we share only the minimum data necessary for the stated
                            purpose and require recipients to keep it confidential.</p>
                    </div>
                </div>

                <!-- 5 -->
                <div class="legal-section" id="cookies">
                    <span class="legal-section__number">Section 05</span>
                    <h2 class="legal-section__title">Cookies &amp; Session Storage</h2>
                    <div class="legal-section__body">
                        <p>We use a small number of strictly necessary cookies to operate the
                            Service.  We do not use advertising or tracking cookies.</p>

                        <p class="legal-sub">Cookies we set</p>
                        <ul class="legal-list">
                            <li><strong>JSESSIONID</strong> — a server-generated session token that keeps you authenticated between page requests. It is HTTP-only (not accessible to JavaScript), expires when you close your browser or click "Sign Out", and is never shared with third parties.</li>
                            <li><strong>gh_remember</strong> — an optional "remember me" cookie set only if you explicitly check the relevant box at login. It expires after 30 days and is deleted immediately when you log out.</li>
                        </ul>

                        <p>Because we only set strictly necessary cookies, no cookie consent
                            banner is required under current Indian law.  If we introduce
                            non-essential cookies in future we will update this policy and seek
                            your consent beforehand.</p>
                    </div>
                </div>

                <!-- 6 -->
                <div class="legal-section" id="retention">
                    <span class="legal-section__number">Section 06</span>
                    <h2 class="legal-section__title">Data Retention</h2>
                    <div class="legal-section__body">
                        <ul class="legal-list">
                            <li><strong>Account data</strong> — retained for as long as your account is active. If you delete your account, personal details are removed within 30 days; anonymised booking statistics may be retained for analytical purposes.</li>
                            <li><strong>Booking records</strong> — retained for 7 years from the date of the stay to comply with the GST Act, 2017 (Section 36) and the Companies Act, 2013.</li>
                            <li><strong>Contact messages</strong> — retained for up to 2 years, after which they are permanently deleted.</li>
                            <li><strong>Audit logs</strong> — retained for 1 year for security and fraud-prevention purposes.</li>
                            <li><strong>Server access logs</strong> — retained for 90 days, then purged automatically.</li>
                        </ul>
                    </div>
                </div>

                <!-- 7 -->
                <div class="legal-section" id="security">
                    <span class="legal-section__number">Section 07</span>
                    <h2 class="legal-section__title">Security Measures</h2>
                    <div class="legal-section__body">
                        <p>The application uses the following security measures. Production
                            operators must configure and verify the hosting protections described below:</p>
                        <ul class="legal-list">
                            <li>Passwords are stored as salted PBKDF2-HMAC-SHA-256 hashes with 210,000 iterations — never in plain text or reversible encryption.</li>
                            <li>Production deployments must use HTTPS with TLS 1.2 or higher to protect data in transit.</li>
                            <li>Database connections use parameterised SQL statements (PreparedStatement) to prevent injection attacks.</li>
                            <li>Session cookies are configured as HTTP-only. Production deployments must also configure the Secure cookie attribute and serve the site only over HTTPS.</li>
                            <li>An audit log records every login and logout event, including IP address and timestamp.</li>
                            <li>Admin functions are protected by a separate login with role-based access control.</li>
                        </ul>
                        <p>No system is perfectly secure. While we take every reasonable
                            precaution, we cannot guarantee absolute security. In the event of a
                            data breach that is likely to harm your interests, we will notify you
                            and the relevant authority as required by applicable law.</p>
                    </div>
                </div>

                <!-- 8 -->
                <div class="legal-section" id="your-rights">
                    <span class="legal-section__number">Section 08</span>
                    <h2 class="legal-section__title">Your Rights</h2>
                    <div class="legal-section__body">
                        <p>Under the Digital Personal Data Protection Act, 2023, and the SPDI
                            Rules, 2011, you have the following rights regarding your personal
                            data:</p>
                        <ul class="legal-list">
                            <li><strong>Right of access</strong> — you may request a copy of the personal data we hold about you at any time.</li>
                            <li><strong>Right to correction</strong> — you may update inaccurate or incomplete data at any time via the Profile page in your account dashboard.</li>
                            <li><strong>Right to erasure</strong> — you may request deletion of your account and personal data. We will comply within 30 days, subject to retention obligations described in Section 6.</li>
                            <li><strong>Right to withdraw consent</strong> — where processing is based on your consent (e.g. marketing emails), you may withdraw it at any time without affecting the lawfulness of prior processing.</li>
                            <li><strong>Right to grievance redressal</strong> — if you believe your data has been mishandled, you may contact our Data Protection Officer (see Section 12) or file a complaint with the Data Protection Board of India once it is constituted under the DPDPA.</li>
                        </ul>
                        <p>To exercise any of these rights, contact us at
                            <a href="mailto:privacy@grandhorizon.in">privacy@grandhorizon.in</a>.
                            We will respond within 30 days of receipt of your request.</p>
                    </div>
                </div>

                <!-- 9 -->
                <div class="legal-section" id="children">
                    <span class="legal-section__number">Section 09</span>
                    <h2 class="legal-section__title">Children's Privacy</h2>
                    <div class="legal-section__body">
                        <p>Our Service is not directed at children under the age of 18 and we do
                            not knowingly collect personal data from minors. Account registration
                            requires users to be 18 years or older.  If we become aware that we have
                            inadvertently collected personal data from a child, we will delete it
                            promptly.  Parents or guardians who believe their child has provided us
                            with personal data may contact us at
                            <a href="mailto:privacy@grandhorizon.in">privacy@grandhorizon.in</a>.</p>
                    </div>
                </div>

                <!-- 10 -->
                <div class="legal-section" id="third-party">
                    <span class="legal-section__number">Section 10</span>
                    <h2 class="legal-section__title">Third-Party Links</h2>
                    <div class="legal-section__body">
                        <p>Our website may contain links to third-party websites (e.g. map
                            providers, review platforms, or travel guides).  This Privacy Policy
                            applies only to our Service.  We have no control over, and accept no
                            responsibility for, the privacy practices of any external site.  We
                            encourage you to review the privacy policy of any third-party site you
                            visit.</p>
                    </div>
                </div>

                <!-- 11 -->
                <div class="legal-section" id="changes">
                    <span class="legal-section__number">Section 11</span>
                    <h2 class="legal-section__title">Changes to This Policy</h2>
                    <div class="legal-section__body">
                        <p>We may update this Privacy Policy periodically to reflect changes in
                            our practices, technology, legal requirements, or for other operational
                            reasons.  When we make material changes we will:</p>
                        <ul class="legal-list">
                            <li>Update the "Last Updated" date at the top of this page.</li>
                            <li>Send a notification email to all registered account holders.</li>
                            <li>Display a prominent banner on the website for at least 14 days after the change takes effect.</li>
                        </ul>
                        <p>Continued use of the Service after the effective date of a revised
                            policy constitutes your acceptance of the updated terms.  If you do not
                            agree with the changes, you may delete your account before the new
                            policy takes effect.</p>
                    </div>
                </div>

                <!-- 12 -->
                <div class="legal-section" id="contact-dpo">
                    <span class="legal-section__number">Section 12</span>
                    <h2 class="legal-section__title">Contact Us</h2>
                    <div class="legal-section__body">
                        <p>For any questions, requests, or complaints regarding this Privacy
                            Policy or our handling of your personal data, please contact our
                            Data Protection Officer:</p>
                    </div>
                    <div class="legal-contact-card">
                        <div class="legal-contact-card__icon">
                            <svg width="20" height="20" fill="none" stroke="currentColor"
                                 stroke-width="1.8" viewBox="0 0 24 24">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            </svg>
                        </div>
                        <div>
                            <p class="legal-contact-card__title">Data Protection Officer</p>
                            <p class="legal-contact-card__text">
                                Grand Horizon Hotel<br>
                                12, Palace Road, Near Golden Temple<br>
                                Amritsar, Punjab — 143001, India<br><br>
                                Email: <a href="mailto:privacy@grandhorizon.in">privacy@grandhorizon.in</a><br>
                                Phone: <a href="tel:+911234567890">+91 12345 67890</a><br>
                                Response time: within 30 days
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Sibling page link -->
                <a href="terms-of-service.jsp" class="legal-sibling">
                    <div>
                        <p class="legal-sibling__label">Also Read</p>
                        <p class="legal-sibling__title">Terms of Service →</p>
                    </div>
                    <span class="legal-sibling__arrow">›</span>
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
                    <li><a href="privacy-policy.jsp" style="color:var(--gold);">Privacy Policy</a></li>
                    <li><a href="terms-of-service.jsp">Terms of Service</a></li>
                    <li><a href="contact.jsp">Contact Us</a></li>
                </ul>
            </div>
        </div>
        <div class="footer__bottom">
            <span>&copy; 2025 Grand Horizon Hotel. All rights reserved.</span>
            <span>
        <a href="privacy-policy.jsp" style="color:var(--gold);">Privacy Policy</a>
        &nbsp;·&nbsp;
        <a href="terms-of-service.jsp">Terms of Service</a>
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
