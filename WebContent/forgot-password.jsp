<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
    private String html(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;")
                .replace("'", "&#x27;");
    }
%>
<%
    /* ── Read flash attributes set by ForgotPasswordServlet ── */
    String successMsg = (String) request.getAttribute("success");
    String errorMsg   = (String) request.getAttribute("error");
    /* Pre-fill email if bounced back from servlet */
    String prefillEmail = (String) request.getAttribute("prefillEmail");
    if (prefillEmail == null) prefillEmail = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Forgot Password — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Step indicator ──────────────────────────────── */
        .reset-steps {
            display: flex;
            align-items: center;
            gap: 0;
            margin-bottom: 2.5rem;
        }
        .reset-step {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 0.4rem;
            flex: 1;
            position: relative;
        }
        .reset-step:not(:last-child)::after {
            content: '';
            position: absolute;
            top: 16px;
            left: calc(50% + 16px);
            right: calc(-50% + 16px);
            height: 1px;
            background: var(--border);
        }
        .reset-step.active:not(:last-child)::after,
        .reset-step.done:not(:last-child)::after {
            background: var(--gold-muted);
        }
        .reset-step__num {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            border: 1px solid var(--border);
            background: var(--surface);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.75rem;
            color: var(--text-muted);
            z-index: 1;
            transition: all 0.3s ease;
        }
        .reset-step.active .reset-step__num {
            border-color: var(--gold);
            background: var(--gold-glow);
            color: var(--gold);
            font-weight: 600;
        }
        .reset-step.done .reset-step__num {
            border-color: var(--success);
            background: rgba(74,140,106,0.1);
            color: var(--success);
        }
        .reset-step__label {
            font-size: 0.6rem;
            letter-spacing: 0.15em;
            text-transform: uppercase;
            color: var(--text-muted);
        }
        .reset-step.active .reset-step__label { color: var(--gold); }
        .reset-step.done  .reset-step__label  { color: var(--success); }

        /* ── Email sent state ────────────────────────────── */
        .sent-state {
            text-align: center;
            padding: 1rem 0;
        }
        .sent-icon {
            width: 72px;
            height: 72px;
            border-radius: 50%;
            background: rgba(74,140,106,0.08);
            border: 1px solid rgba(74,140,106,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            animation: popIn 0.5s cubic-bezier(0.34,1.56,0.64,1) both;
        }
        @keyframes popIn {
            from { opacity: 0; transform: scale(0.5); }
            to   { opacity: 1; transform: scale(1); }
        }
        .sent-icon svg {
            width: 32px;
            height: 32px;
            color: #4a8c6a;
            stroke-dasharray: 45;
            stroke-dashoffset: 45;
            animation: drawCheck 0.5s 0.3s ease forwards;
        }
        @keyframes drawCheck {
            to { stroke-dashoffset: 0; }
        }
        .sent-title {
            font-family: var(--font-display);
            font-size: 1.9rem;
            font-weight: 300;
            margin-bottom: 0.6rem;
        }
        .sent-email-badge {
            display: inline-block;
            background: var(--gold-glow);
            border: 1px solid var(--border-light);
            border-radius: var(--radius-sm);
            padding: 0.4rem 1.2rem;
            font-size: 0.9rem;
            color: var(--gold-light);
            margin: 0.5rem 0 1.2rem;
            word-break: break-all;
        }
        .sent-note {
            font-size: 0.85rem;
            color: var(--text-secondary);
            line-height: 1.8;
            max-width: 340px;
            margin: 0 auto 1.5rem;
        }
        .resend-row {
            font-size: 0.82rem;
            color: var(--text-muted);
            margin-top: 1rem;
        }
        .resend-row a { color: var(--gold); }
    </style>
</head>
<body>

<div class="auth-page">

    <!-- ── Visual panel ──────────────────────────────────────── -->
    <div class="auth-panel auth-panel--visual">
        <div class="auth-visual-content">
            <div class="ornament" style="margin-bottom:2.5rem;"><span>✦</span></div>
            <blockquote>
                "Every great comeback begins with a single step forward."
            </blockquote>
            <cite>— Grand Horizon Concierge</cite>
            <div style="margin-top:3rem;">
                <p style="font-size:0.7rem;letter-spacing:0.2em;text-transform:uppercase;
                  color:var(--text-muted);margin-bottom:1.2rem;">Need help?</p>
                <p style="font-size:0.88rem;color:var(--text-secondary);line-height:1.8;">
                    Call our front desk anytime:<br>
                    <a href="tel:+919321132636" style="color:var(--gold);">+91 93211 32636</a>
                </p>
            </div>
        </div>
    </div>

    <!-- ── Form panel ────────────────────────────────────────── -->
    <div class="auth-panel">
        <div class="auth-form-wrap">

            <a href="index.jsp" class="auth-logo">Grand Horizon</a>
            <p class="auth-tagline">Luxury Hotel &amp; Suites</p>

            <% if (successMsg != null) { %>
            <!-- ══ EMAIL SENT STATE ══════════════════════════════ -->
            <div class="sent-state">

                <!-- Step indicator -->
                <div class="reset-steps">
                    <div class="reset-step done">
                        <div class="reset-step__num">
                            <svg width="13" height="13" fill="none" stroke="currentColor"
                                 stroke-width="2.5" viewBox="0 0 24 24">
                                <polyline points="20 6 9 17 4 12"/>
                            </svg>
                        </div>
                        <span class="reset-step__label">Email</span>
                    </div>
                    <div class="reset-step active">
                        <div class="reset-step__num">2</div>
                        <span class="reset-step__label">Check inbox</span>
                    </div>
                    <div class="reset-step">
                        <div class="reset-step__num">3</div>
                        <span class="reset-step__label">New password</span>
                    </div>
                </div>

                <div class="sent-icon">
                    <svg fill="none" stroke="currentColor" stroke-width="2.5"
                         stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                        <polyline points="20 6 9 17 4 12"/>
                    </svg>
                </div>

                <h1 class="sent-title">Check Your Inbox</h1>
                <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:0.6rem;">
                    If an account exists for this address, a reset link is on its way to
                </p>
                <span class="sent-email-badge"><%= html(successMsg) %></span>
                <p class="sent-note">
                    The link expires in <strong style="color:var(--text-primary);">60 minutes</strong>.
                    If you don't see the email, check your spam or junk folder.
                </p>

                <a href="login.jsp" class="btn btn--outline btn--full">← Back to Sign In</a>

                <p class="resend-row">
                    Didn't receive it?
                    <a href="forgot-password.jsp">Try a different email</a>
                    or <a href="contact.jsp">contact support</a>.
                </p>
            </div>

            <% } else { %>
            <!-- ══ REQUEST FORM ══════════════════════════════════ -->

            <!-- Step indicator -->
            <div class="reset-steps" style="margin-top:0.5rem;">
                <div class="reset-step active">
                    <div class="reset-step__num">1</div>
                    <span class="reset-step__label">Email</span>
                </div>
                <div class="reset-step">
                    <div class="reset-step__num">2</div>
                    <span class="reset-step__label">Check inbox</span>
                </div>
                <div class="reset-step">
                    <div class="reset-step__num">3</div>
                    <span class="reset-step__label">New password</span>
                </div>
            </div>

            <h1 class="auth-title">Forgot Password?</h1>
            <p class="auth-subtitle">
                Enter the email address on your account and we'll send
                you a secure link to reset your password.
            </p>

            <% if (errorMsg != null) { %>
            <div class="alert alert--error" style="margin-bottom:1.5rem;">
                <svg width="15" height="15" fill="none" stroke="currentColor"
                     stroke-width="2" viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= html(errorMsg) %>
            </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/forgot" method="post"
                  id="fpForm" novalidate>

                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email"
                           class="form-control"
                           placeholder="you@example.com"
                           value="<%= html(prefillEmail) %>"
                           required autocomplete="email">
                    <span class="form-error" id="emailErr">
            Please enter a valid email address.
          </span>
                </div>

                <button type="submit" class="btn btn--primary btn--full"
                        id="submitBtn">
                    Send Reset Link
                </button>

            </form>

            <div class="auth-divider">or</div>

            <p class="auth-footer-text">
                Remember your password?
                <a href="login.jsp">Sign in →</a>
            </p>
            <p class="auth-footer-text" style="margin-top:0.5rem;">
                Don't have an account?
                <a href="register.jsp">Register →</a>
            </p>

            <% } %>

        </div><!-- /auth-form-wrap -->
    </div><!-- /auth-panel -->

</div><!-- /auth-page -->

<script>
    const form = document.getElementById('fpForm');
    if (form) {
        form.addEventListener('submit', function(e) {
            const email  = document.getElementById('email');
            const errEl  = document.getElementById('emailErr');
            const btn    = document.getElementById('submitBtn');
            const valid  = email.value && /\S+@\S+\.\S+/.test(email.value);

            if (!valid) {
                errEl.classList.add('visible');
                email.classList.add('form-control--error');
                e.preventDefault();
            } else {
                errEl.classList.remove('visible');
                email.classList.remove('form-control--error');
                // Disable button to prevent double-submit
                btn.disabled = true;
                btn.textContent = 'Sending…';
            }
        });
    }
</script>
<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
    &copy; 2026 Grand Horizon Hotel· All rights reserved.&nbsp;
    <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
