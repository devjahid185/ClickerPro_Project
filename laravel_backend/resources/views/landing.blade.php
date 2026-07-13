<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Graphy7 — Run Your Photography Business</title>
    <meta name="description" content="Graphy7 replaces a photography studio's notebook, WhatsApp groups, and Excel sheet with one app. Bookings, team, and money — in one place.">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Outfit:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('landing/css/landing.css') }}">
</head>
<body>
    {{-- NAV --}}
    <nav class="nav">
        <a href="#top" class="nav__brand">
            <span class="nav__mark">G</span> Graphy<span style="color:var(--primary)">7</span>
        </a>
        <div class="nav__links">
            <a href="#features" class="nav__link">Features</a>
            <a href="#screens" class="nav__link">Screens</a>
            <a href="#pricing" class="nav__link">Pricing</a>
            <a href="{{ $appWebUrl }}" class="nav__link" target="_blank" rel="noopener">Web App</a>
            <a href="{{ $appDownloadUrl }}" class="nav__cta">Download APK</a>
        </div>
        <button class="nav__menu" aria-label="Menu">☰</button>
    </nav>

    {{-- HERO --}}
    <header id="top" class="hero">
        <div class="hero__fallback"></div>
        <div id="mountain-scene" class="hero__scene"></div>
        <div class="hero__overlay"></div>

        <div class="hero__content">
            <div class="hero__eyebrow">— Professional Photography Management</div>
            <h1 class="hero__title">{{ $heroTitle }}</h1>
            <p class="hero__desc">{{ $heroSubtitle }}</p>
            <p class="hero__support">{{ $heroDescription }}</p>
            <div class="hero__actions">
                <a href="{{ $appDownloadUrl }}" class="btn btn--primary">Download APK</a>
                <a href="{{ $appWebUrl }}" class="btn btn--ghost" target="_blank" rel="noopener">Open Web App</a>
            </div>
        </div>

        <div class="hero__scroll">
            <div class="hero__scroll-bar"></div>
            <span>Scroll</span>
        </div>
    </header>

    {{-- FEATURES --}}
    <section id="features" class="section">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Everything You Need</div>
                <h2 class="section__title">Built For Creative Pros</h2>
                <p class="section__desc">Every tool your photography business needs, carefully designed for the way you actually work.</p>
            </div>

            @php
                $features = [
                    ['icon' => '📅', 'name' => 'Smart Bookings', 'desc' => 'Book events with client, date, shift, package and team — with instant conflict warnings.'],
                    ['icon' => '👥', 'name' => 'Team Roles', 'desc' => 'Passcode-only joining and proper job roles with fine-grained permissions per studio.'],
                    ['icon' => '৳',  'name' => 'Money Tracking', 'desc' => 'Separate studio and freelancer income, one-tap invoicing, and clear due tracking.'],
                    ['icon' => '📴', 'name' => 'Offline First', 'desc' => 'Every screen works offline and backs up everywhere — built for patchy networks.'],
                    ['icon' => '🔔', 'name' => 'Pre-Event Alerts', 'desc' => 'Full-screen takeover reminders before each shoot, like an incoming call.'],
                    ['icon' => '📊', 'name' => 'Finance Dashboard', 'desc' => 'Monthly and yearly income, expense and net at a glance, with WhatsApp reminders.'],
                ];
            @endphp
            <div class="features-grid">
                @foreach ($features as $i => $f)
                    <div class="feature-card reveal">
                        <div class="feature-card__num">0{{ $i + 1 }}</div>
                        <div class="feature-card__icon">{{ $f['icon'] }}</div>
                        <div class="feature-card__name">{{ $f['name'] }}</div>
                        <p class="feature-card__desc">{{ $f['desc'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    {{-- DETAILS --}}
    <section class="section section--dark">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">What You Get</div>
                <h2 class="section__title">{{ $featureHeadline }}</h2>
                <p class="section__desc">{{ $featureSubheadline }}</p>
            </div>

            <div class="details-grid">
                @foreach ($details as $detail)
                    <article class="detail-card reveal">
                        <div class="detail-card__icon">{{ $detail['icon'] }}</div>
                        <h3 class="detail-card__title">{{ $detail['title'] }}</h3>
                        <p class="detail-card__text">{{ $detail['text'] }}</p>
                        <a href="{{ $detail['link'] }}" class="btn btn--ghost btn--small">{{ $detail['button'] }}</a>
                    </article>
                @endforeach
            </div>
        </div>
    </section>

    {{-- SCREEN PREVIEW --}}
    <section id="screens" class="section section--light">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Screenshots</div>
                <h2 class="section__title">Mobile and web built for real studio workflows.</h2>
                <p class="section__desc">Tap into a modern interface that keeps bookings, team notes and finances visible from every device.</p>
            </div>

            <div class="visual-grid">
                <article class="visual-card reveal">
                    <div class="visual-card__label">Mobile app preview</div>
                    <img src="{{ asset('landing/img/mobile-app.jpg') }}" alt="Graphy7 mobile app screenshot" loading="lazy" width="720" height="1069">
                </article>
                <article class="visual-card reveal">
                    <div class="visual-card__label">Web dashboard preview</div>
                    <img src="{{ asset('landing/img/web-app.jpg') }}" alt="Graphy7 web dashboard screenshot" loading="lazy" width="1280" height="800">
                </article>
            </div>

            <div class="screens-grid">
                <article class="phone-card reveal">
                    <div class="phone-card__header">
                        <span>Dashboard</span>
                        <span class="phone-card__badge">Live</span>
                    </div>
                    <div class="phone-card__body">
                        <div class="phone-card__figure">Good morning, Rahim 👋</div>
                        <div class="phone-card__text">Today: 6 shoots, 2 invoices due, 11 payments pending.</div>
                    </div>
                    <div class="phone-card__footer">Central shoot status and finance at a glance.</div>
                </article>

                <article class="phone-card reveal">
                    <div class="phone-card__header">
                        <span>Calendar</span>
                        <span class="phone-card__badge phone-card__badge--soft">Upcoming</span>
                    </div>
                    <div class="phone-card__body">
                        <div class="phone-card__figure">July 2026</div>
                        <div class="phone-card__text">Bookings, holidays, and reminders in one smart schedule.</div>
                    </div>
                    <div class="phone-card__footer">Avoid double bookings and see every shoot at once.</div>
                </article>

                <article class="phone-card reveal">
                    <div class="phone-card__header">
                        <span>Team Chat</span>
                        <span class="phone-card__badge phone-card__badge--muted">3 online</span>
                    </div>
                    <div class="phone-card__body">
                        <div class="phone-card__figure"># Wedding Team</div>
                        <div class="phone-card__text">Send shoot notes, updates, and file links in one channel.</div>
                    </div>
                    <div class="phone-card__footer">Keep conversations tied to each event, not scattered across apps.</div>
                </article>
            </div>
        </div>
    </section>

    {{-- PRICING --}}
    <section id="pricing" class="section section--dark">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Pricing</div>
                <h2 class="section__title">Simple pricing, built for growing studios.</h2>
                <p class="section__desc">Start free. Upgrade only when your studio is ready to scale the whole team.</p>
            </div>

            <div class="details-grid">
                <article class="detail-card reveal">
                    <div class="detail-card__icon">🆓</div>
                    <h3 class="detail-card__title">Free</h3>
                    <p class="detail-card__text">Unlimited bookings, one studio owner account, offline-first sync, and the core finance dashboard — ৳0, no card required.</p>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost btn--small">Start Free</a>
                </article>
                <article class="detail-card reveal">
                    <div class="detail-card__icon">⭐</div>
                    <h3 class="detail-card__title">Pro</h3>
                    <p class="detail-card__text">Everything in Free, plus unlimited team members, invoices, delivery tracking, and pre-event reminders for the whole crew.</p>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost btn--small">Download APK</a>
                </article>
                <article class="detail-card reveal">
                    <div class="detail-card__icon">🏢</div>
                    <h3 class="detail-card__title">Studio</h3>
                    <p class="detail-card__text">For larger teams — multiple managers, freelancer payouts, audit history and priority support. Contact us for a custom quote.</p>
                    <a href="#download" class="btn btn--ghost btn--small">Get In Touch</a>
                </article>
            </div>
        </div>
    </section>

    {{-- REVIEWS --}}
    <section class="section">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Studio Feedback</div>
                <h2 class="section__title">Loved by photographers and managers.</h2>
                <p class="section__desc">Reviews from local studios who now run their business with modern workflows instead of paper and chat apps.</p>
            </div>

            <div class="reviews-grid">
                @foreach ($reviews as $review)
                    <article class="review-card reveal">
                        <div class="review-card__avatar">{{ strtoupper(substr($review['name'], 0, 1)) }}</div>
                        <div>
                            <div class="review-card__name">{{ $review['name'] }}</div>
                            <div class="review-card__role">{{ $review['role'] }}</div>
                        </div>
                        <p class="review-card__text">“{{ $review['text'] }}”</p>
                    </article>
                @endforeach
            </div>
        </div>
    </section>

    {{-- CTA --}}
    <section id="download" class="section">
        <div class="container">
            <div class="cta-band reveal">
                <div class="cta-band__content">
                    <h2 class="cta-band__title">Ready to run your studio better?</h2>
                    <p class="cta-band__desc">Use Graphy7 on the web or install the app — bring bookings, team, and money into one place.</p>
                </div>
                <div class="cta-band__actions">
                    <a href="{{ $appWebUrl }}" class="btn btn--light" target="_blank" rel="noopener">🌐 Open Web App</a>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost">⬇ Download APK</a>
                </div>
            </div>
        </div>
    </section>

    {{-- FOOTER --}}
    <footer class="footer">
        <div class="container">
            <div class="footer__grid">
                <div class="footer__brand"><span class="nav__mark">G</span> Graphy<span style="color:var(--primary)">7</span></div>
                <div class="footer__links">
                    <a href="#features" class="footer__link">Features</a>
                    <a href="#download" class="footer__link">Download</a>
                </div>
            </div>
            <div class="footer__copy">© {{ date('Y') }} Graphy7 · Photography &amp; event management for studios.</div>
        </div>
    </footer>

    <script type="module" src="{{ asset('landing/js/mountain-scene.js') }}"></script>
    <script src="{{ asset('landing/js/landing.js') }}"></script>

    {{-- Landing crash/bug reporter: forwards uncaught JS errors + promise
         rejections to the same /api/crash-reports pipeline the apps use, so the
         admin console sees landing-page failures too. Best-effort and silent —
         it must never interfere with the page. --}}
    <script>
    (function () {
      var sent = 0;
      function report(message, stack) {
        if (sent >= 5) return; // cap per page load so a loop can't spam
        sent++;
        try {
          fetch('/api/crash-reports', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
              error: String(message || 'Unknown landing error').slice(0, 1000),
              stackTrace: stack ? String(stack).slice(0, 4000) : null,
              platform: 'landing',
              breadcrumbs: [{ message: 'url: ' + location.pathname, timestamp: new Date().toISOString() }]
            }),
            keepalive: true
          }).catch(function () {});
        } catch (e) { /* swallow */ }
      }
      window.addEventListener('error', function (e) {
        report(e.message, e.error && e.error.stack);
      });
      window.addEventListener('unhandledrejection', function (e) {
        var r = e.reason;
        report(r && r.message ? r.message : r, r && r.stack);
      });
    })();
    </script>
</body>
</html>
