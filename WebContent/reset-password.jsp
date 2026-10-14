<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#x27;");
    }
%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0L);
    response.setHeader("Referrer-Policy", "no-referrer");
    response.setHeader("X-Content-Type-Options", "nosniff");

    /* ── Token and state attributes set by ResetPasswordServlet ── */
    String token        = (String) request.getAttribute("token");
    String tokenEmail   = (String) request.getAttribute("tokenEmail");
    String errorMsg     = (String) request.getAttribute("error");
    String successMsg   = (String) request.getAttribute("success");
    Boolean tokenValid  = (Boolean) request.getAttribute("tokenValid");

    /* ── If accessed directly without servlet forward (GET with ?token=) ──
       The servlet sets tokenValid=true/false. If attribute is missing
       the page shows the expired/invalid state as a safe default. */
    if (tokenValid == null) tokenValid = false;
    if (token      == null) token      = "";
    if (tokenEmail == null) tokenEmail = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="referrer" content="no-referrer">
    <title>Reset Password — Grand Horizon Hotel</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* ── Step indicator (same as forgot-password.jsp) ──── */
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

        /* ── Password strength bar ───────────────────────── */
        .pwd-strength-wrap { margin-top: 0.6rem; }
        .pwd-strength-bar-bg {
            height: 3px;
            background: var(--border);
            border-radius: 2px;
            overflow: hidden;
        }
        .pwd-strength-bar {
            height: 100%;
            width: 0;
            border-radius: 2px;
            transition: width 0.35s ease, background 0.35s ease;
        }
        .pwd-strength-label {
            font-size: 0.7rem;
            color: var(--text-muted);
            margin-top: 0.3rem;
        }

        /* ── Requirements checklist ──────────────────────── */
        .pwd-reqs {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0.4rem 1rem;
            margin-top: 0.9rem;
            padding: 1rem;
            background: var(--charcoal);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
        }
        .pwd-req {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-size: 0.78rem;
            color: var(--text-muted);
            transition: color 0.25s ease;
        }
        .pwd-req.met { color: var(--success); }
        .pwd-req__dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--border);
            flex-shrink: 0;
            transition: background 0.25s ease;
        }
        .pwd-req.met .pwd-req__dot { background: var(--success); }

        /* ── Expired / invalid token state ──────────────── */
        .token-expired {
            text-align: center;
            padding: 1rem 0;
        }
        .token-expired__icon {
            width: 68px;
            height: 68px;
            border-radius: 50%;
            background: rgba(192,81,58,0.08);
            border: 1px solid rgba(192,81,58,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            color: var(--error);
            animation: popIn 0.5s cubic-bezier(0.34,1.56,0.64,1) both;
        }
        @keyframes popIn {
            from { opacity: 0; transform: scale(0.5); }
            to   { opacity: 1; transform: scale(1); }
        }

        /* ── Success state ───────────────────────────────── */
        .success-state {
            text-align: center;
            padding: 1rem 0;
        }
        .success-state__icon {
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
        .success-state__icon svg {
            width: 34px;
            height: 34px;
            color: #4a8c6a;
            stroke-dasharray: 45;
            stroke-dashoffset: 45;
            animation: drawCheck 0.5s 0.3s ease forwards;
        }
        @keyframes drawCheck {
            to { stroke-dashoffset: 0; }
        }
    </style>
</head>
<body>

<div class="auth-page">

    <!-- ── Visual panel ──────────────────────────────────────── -->
    <div class="auth-panel auth-panel--visual">
        <div class="auth-visual-content">
            <div class="ornament" style="margin-bottom:2.5rem;"><span>✦</span></div>
            <blockquote>
                "Security and serenity — two promises we keep without compromise."
            </blockquote>
            <cite>— Grand Horizon</cite>
            <div class="ornament" style="margin-top:2.5rem;"><span>✦</span></div>
        </div>
    </div>

    <!-- ── Form panel ────────────────────────────────────────── -->
    <div class="auth-panel">
        <div class="auth-form-wrap">

            <a href="index.jsp" class="auth-logo">Grand Horizon</a>
            <p class="auth-tagline">Luxury Hotel &amp; Suites</p>

            <%-- ════════════════════════════════════════════════════
                 STATE 1: PASSWORD SUCCESSFULLY CHANGED
            ════════════════════════════════════════════════════ --%>
            <% if (successMsg != null) { %>

            <div class="reset-steps">
                <div class="reset-step done">
                    <div class="reset-step__num">
                        <svg width="13" height="13" fill="none" stroke="currentColor"
                             stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    </div>
                    <span class="reset-step__label">Email</span>
                </div>
                <div class="reset-step done">
                    <div class="reset-step__num">
                        <svg width="13" height="13" fill="none" stroke="currentColor"
                             stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    </div>
                    <span class="reset-step__label">Check inbox</span>
                </div>
                <div class="reset-step done">
                    <div class="reset-step__num">
                        <svg width="13" height="13" fill="none" stroke="currentColor"
                             stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    </div>
                    <span class="reset-step__label">New password</span>
                </div>
            </div>

            <div class="success-state">
                <div class="success-state__icon">
                    <svg fill="none" stroke="currentColor" stroke-width="2.5"
                         stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
                        <polyline points="20 6 9 17 4 12"/>
                    </svg>
                </div>
                <h1 class="auth-title" style="margin-bottom:0.5rem;">Password Updated!</h1>
                <p class="auth-subtitle" style="margin-bottom:2rem;">
                    Your password has been changed successfully.
                    You can now sign in with your new password.
                </p>
                <a href="login.jsp" class="btn btn--primary btn--full btn--lg">
                    Sign In Now →
                </a>
            </div>

            <%-- ════════════════════════════════════════════════════
                 STATE 2: TOKEN INVALID OR EXPIRED
            ════════════════════════════════════════════════════ --%>
            <% } else if (!tokenValid) { %>

            <div class="token-expired">
                <div class="token-expired__icon">
                    <svg width="30" height="30" fill="none" stroke="currentColor"
                         stroke-width="2" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10"/>
                        <polyline points="12 6 12 12 16 14"/>
                    </svg>
                </div>
                <h1 class="auth-title" style="margin-bottom:0.5rem;">Link Expired</h1>
                <p class="auth-subtitle" style="margin-bottom:0.5rem;">
                    This password reset link is no longer valid.
                </p>
                <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:2rem;line-height:1.8;">
                    Reset links expire after <strong style="color:var(--text-primary);">60 minutes</strong>
                    and can only be used once.
                    Please request a new link below.
                </p>
                <a href="forgot-password.jsp" class="btn btn--primary btn--full">
                    Request a New Link
                </a>
                <p class="auth-footer-text" style="margin-top:1.2rem;">
                    <a href="login.jsp">← Back to Sign In</a>
                </p>
            </div>

            <%-- ════════════════════════════════════════════════════
                 STATE 3: VALID TOKEN — SHOW NEW PASSWORD FORM
            ════════════════════════════════════════════════════ --%>
            <% } else { %>

            <div class="reset-steps">
                <div class="reset-step done">
                    <div class="reset-step__num">
                        <svg width="13" height="13" fill="none" stroke="currentColor"
                             stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    </div>
                    <span class="reset-step__label">Email</span>
                </div>
                <div class="reset-step done">
                    <div class="reset-step__num">
                        <svg width="13" height="13" fill="none" stroke="currentColor"
                             stroke-width="2.5" viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                    </div>
                    <span class="reset-step__label">Check inbox</span>
                </div>
                <div class="reset-step active">
                    <div class="reset-step__num">3</div>
                    <span class="reset-step__label">New password</span>
                </div>
            </div>

            <h1 class="auth-title">Set New Password</h1>
            <p class="auth-subtitle">
                Resetting password for
                <strong style="color:var(--text-primary);">
                    <%= escapeHtml(tokenEmail.replaceAll("(?<=.{2}).(?=.*@)", "*")) %>
                </strong>
            </p>

            <% if (errorMsg != null) { %>
            <div class="alert alert--error" style="margin:0 0 1.5rem;">
                <svg width="15" height="15" fill="none" stroke="currentColor"
                     stroke-width="2" viewBox="0 0 24 24">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= escapeHtml(errorMsg) %>
            </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/reset" method="post"
                  id="resetForm" novalidate>

                <%-- Token passed as hidden field — validated server-side --%>
                <input type="hidden" name="token" value="<%= escapeHtml(token) %>">

                <div class="form-group">
                    <label for="newPassword">New Password</label>
                    <input type="password" id="newPassword" name="newPassword"
                           class="form-control"
                           placeholder="Min. 12 characters" minlength="12" maxlength="128"
                           required
                           autocomplete="new-password"
                           oninput="checkStrength(this.value)">

                    <div class="pwd-strength-wrap">
                        <div class="pwd-strength-bar-bg">
                            <div class="pwd-strength-bar" id="strengthBar"></div>
                        </div>
                        <p class="pwd-strength-label" id="strengthLabel">Choose a strong password</p>
                    </div>
                </div>

                <!-- Requirements checklist -->
                <div class="pwd-reqs">
                    <div class="pwd-req" id="req-len">
                        <div class="pwd-req__dot"></div>At least 12 characters
                    </div>
                    <div class="pwd-req" id="req-upper">
                        <div class="pwd-req__dot"></div>One uppercase letter
                    </div>
                    <div class="pwd-req" id="req-lower">
                        <div class="pwd-req__dot"></div>One lowercase letter
                    </div>
                    <div class="pwd-req" id="req-num">
                        <div class="pwd-req__dot"></div>One number
                    </div>
                    <div class="pwd-req" id="req-special">
                        <div class="pwd-req__dot"></div>One special character
                    </div>
                </div>

                <div class="form-group" style="margin-top:1.2rem;">
                    <label for="confirmPassword">Confirm New Password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword"
                           class="form-control"
                           placeholder="Repeat new password"
                           required
                           autocomplete="new-password">
                    <span class="form-error" id="matchErr">Passwords do not match.</span>
                </div>

                <button type="submit" class="btn btn--primary btn--full btn--lg"
                        id="resetBtn" disabled>
                    Update Password
                </button>

            </form>

            <% } %>

        </div><!-- /auth-form-wrap -->
    </div><!-- /auth-panel -->

</div><!-- /auth-page -->

<script>
    /* ── Password strength checker ── */
    function checkStrength(val) {
        const bar   = document.getElementById('strengthBar');
        const label = document.getElementById('strengthLabel');
        const btn   = document.getElementById('resetBtn');
        if (!bar) return;

        const rules = {
            len:     val.length >= 12,
            upper:   /[A-Z]/.test(val),
            lower:   /[a-z]/.test(val),
            num:     /[0-9]/.test(val),
            special: /[^A-Za-z0-9]/.test(val)
        };

        // Update requirement dots
        Object.keys(rules).forEach(key => {
            document.getElementById('req-' + key)
                .classList.toggle('met', rules[key]);
        });

        const score = Object.values(rules).filter(Boolean).length;

        const cfg = [
            { w:'0%',   bg:'transparent',       lbl:'Choose a strong password' },
            { w:'25%',  bg:'var(--error)',       lbl:'Too weak' },
            { w:'50%',  bg:'var(--warning)',     lbl:'Fair' },
            { w:'75%',  bg:'#8a8820',           lbl:'Good' },
            { w:'90%',  bg:'var(--success)',     lbl:'Strong' },
            { w:'100%', bg:'#2a8c5a',           lbl:'Excellent ✓' },
        ];
        const c = cfg[score];
        bar.style.width      = c.w;
        bar.style.background = c.bg;
        label.textContent    = c.lbl;
        label.style.color    = score > 0 ? c.bg : 'var(--text-muted)';

        // Enable submit only when minimum requirements are met
        btn.disabled = !Object.values(rules).every(Boolean);
        syncMatchState();
    }

    /* ── Password match checker ── */
    function syncMatchState() {
        const p1   = document.getElementById('newPassword');
        const p2   = document.getElementById('confirmPassword');
        const err  = document.getElementById('matchErr');
        const btn  = document.getElementById('resetBtn');
        if (!p1 || !p2) return;

        const match = p1.value === p2.value && p2.value.length > 0;
        if (p2.value.length > 0) {
            err.classList.toggle('visible', !match);
            p2.classList.toggle('form-control--error', !match);
        }
        const strong = p1.value.length >= 12 && p1.value.length <= 128
                && /[A-Z]/.test(p1.value) && /[a-z]/.test(p1.value)
                && /[0-9]/.test(p1.value) && /[^A-Za-z0-9]/.test(p1.value);
        btn.disabled = !(match && strong);
    }

    const confirmEl = document.getElementById('confirmPassword');
    if (confirmEl) {
        confirmEl.addEventListener('input', syncMatchState);
    }

    /* ── Form submit guard ── */
    const form = document.getElementById('resetForm');
    if (form) {
        form.addEventListener('submit', function(e) {
            const p1 = document.getElementById('newPassword').value;
            const p2 = document.getElementById('confirmPassword').value;
            const strong = p1.length >= 12 && p1.length <= 128
                    && /[A-Z]/.test(p1) && /[a-z]/.test(p1)
                    && /[0-9]/.test(p1) && /[^A-Za-z0-9]/.test(p1);
            if (p1 !== p2 || !strong) {
                e.preventDefault();
                document.getElementById('matchErr').classList.add('visible');
            } else {
                document.getElementById('resetBtn').disabled = true;
                document.getElementById('resetBtn').textContent = 'Updating…';
            }
        });
    }
</script>

<div class="footer__bottom" style="text-align:center;padding:1.2rem;border-top:1px solid var(--border);
            background:var(--deep-navy);font-size:0.78rem;color:var(--text-muted);">
    &copy; 2025 Grand Horizon Hotel· All rights reserved.&nbsp;
        <span><a href="privacy-policy.jsp" style="color:var(--text-muted);">Privacy Policy.</a>
        <a href="terms-of-service.jsp" style="color:var(--text-muted);">Terms of Service</a></span>
</div>
</body>
</html>
