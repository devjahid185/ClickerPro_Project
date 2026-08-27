<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Graphy7 - Run Your Photography Business</title>
    <meta name="description" content="Graphy7 replaces a photography studio notebook, WhatsApp groups, and Excel sheets with one app. Bookings, team, and money in one place.">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('landing/img/apple-touch-icon.png') }}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Outfit:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('landing/css/landing.css') }}?v=20260719-screens4">
</head>
<body>
    <nav class="nav">
        <a href="#top" class="nav__brand" aria-label="Graphy7 home">
            <img class="brand-logo" src="{{ asset('landing/img/logo.png') }}" alt="Graphy7">
            <span>Graphy<span style="color:var(--primary)">7</span></span>
        </a>
        <div class="nav__links">
            <a href="#features" class="nav__link">Features</a>
            <a href="#screens" class="nav__link">Screens</a>
            <a href="#pricing" class="nav__link">Pricing</a>
            <a href="{{ $appWebUrl }}" class="nav__link" target="_blank" rel="noopener">Web App</a>
            <a href="{{ $appDownloadUrl }}" class="nav__cta">Download APK</a>
        </div>
        <button class="nav__menu" type="button" aria-label="Menu">Menu</button>
    </nav>

    <header id="top" class="hero">
        <div class="hero__fallback"></div>
        <div id="mountain-scene" class="hero__scene"></div>
        <div class="hero__overlay"></div>

        <div class="hero__content">
            <div class="hero__eyebrow">Professional Photography Management</div>
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

    <section id="features" class="section">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Everything You Need</div>
                <h2 class="section__title">Built For Creative Pros</h2>
                <p class="section__desc">Every tool your photography business needs, designed around the way studios actually work.</p>
            </div>

            @php
                $features = [
                    ['icon' => '01', 'name' => 'Smart Bookings', 'desc' => 'Book events with client, date, shift, package and team, with instant conflict warnings.'],
                    ['icon' => '02', 'name' => 'Team Roles', 'desc' => 'Invite managers and freelancers with clean roles, passcodes, permissions and accountability.'],
                    ['icon' => '03', 'name' => 'Money Tracking', 'desc' => 'Track advance, due, payouts, studio income and payment methods from one dashboard.'],
                    ['icon' => '04', 'name' => 'Offline First', 'desc' => 'Keep working in low-network situations and sync important studio data when online.'],
                    ['icon' => '05', 'name' => 'Event Alerts', 'desc' => 'Get strong pre-event reminders so teams never miss a shoot date or key task.'],
                    ['icon' => '06', 'name' => 'Reports', 'desc' => 'See monthly and yearly income, expenses, dues and performance in a clean overview.'],
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
                        <a href="{{ $detail['link'] }}" class="btn btn--ghost btn--small" @if(Str::startsWith($detail['link'], 'http')) target="_blank" rel="noopener" @endif>{{ $detail['button'] }}</a>
                    </article>
                @endforeach
            </div>
        </div>
    </section>

    <section id="screens" class="section section--light">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Screenshots</div>
                <h2 class="section__title">A complete studio workspace in your pocket.</h2>
                <p class="section__desc">Real Graphy7 app screens for bookings, finance, teams and daily studio control.</p>
            </div>

            @php
                $screenshots = [
                    ['file' => 'graphy7-screen-01.png', 'title' => 'Studio dashboard', 'caption' => 'Daily status, events and money at a glance.'],
                    ['file' => 'graphy7-screen-02.png', 'title' => 'Booking flow', 'caption' => 'Create and manage client events with clean details.'],
                    ['file' => 'graphy7-screen-03.png', 'title' => 'Calendar planning', 'caption' => 'Track shoots, shifts and upcoming studio work.'],
                    ['file' => 'graphy7-screen-04.png', 'title' => 'Finance overview', 'caption' => 'Advance, due, expense and income tracking.'],
                    ['file' => 'graphy7-screen-05.png', 'title' => 'Team workspace', 'caption' => 'Owners, managers and freelancers stay aligned.'],
                    ['file' => 'graphy7-screen-06.png', 'title' => 'Reports', 'caption' => 'Professional summaries for stronger decisions.'],
                    ['file' => 'graphy7-screen-07.png', 'title' => 'Settings', 'caption' => 'Studio controls designed for real operations.'],
                    ['file' => 'graphy7-screen-08.png', 'title' => 'Mobile ready', 'caption' => 'Everything tuned for fast phone-based work.'],
                ];
            @endphp

            <div class="screenshot-showcase">
                @foreach ($screenshots as $screen)
                    <article class="screenshot-card reveal">
                        <div class="screenshot-card__media">
                            <img
                                src="{{ asset('landing/img/' . $screen['file']) }}?v=20260719"
                                alt="Graphy7 {{ $screen['title'] }} screen"
                                loading="lazy"
                                width="1242"
                                height="2208"
                            >
                        </div>
                        <div class="screenshot-card__copy">
                            <h3>{{ $screen['title'] }}</h3>
                            <p>{{ $screen['caption'] }}</p>
                        </div>
                    </article>
                @endforeach
            </div>
        </div>
    </section>

    <section id="pricing" class="section section--dark">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Pricing</div>
                <h2 class="section__title">Simple pricing for growing studios.</h2>
                <p class="section__desc">Start free. Upgrade only when your studio is ready to scale the full team.</p>
            </div>

            <div class="details-grid">
                <article class="detail-card reveal">
                    <div class="detail-card__icon">Free</div>
                    <h3 class="detail-card__title">Free</h3>
                    <p class="detail-card__text">Unlimited bookings, one studio owner account, offline-first sync and the core finance dashboard.</p>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost btn--small">Start Free</a>
                </article>
                <article class="detail-card reveal">
                    <div class="detail-card__icon">Pro</div>
                    <h3 class="detail-card__title">Pro</h3>
                    <p class="detail-card__text">Everything in Free, plus unlimited team members, invoices, delivery tracking and stronger reminders.</p>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost btn--small">Download APK</a>
                </article>
                <article class="detail-card reveal">
                    <div class="detail-card__icon">Web</div>
                    <h3 class="detail-card__title">Web Dashboard</h3>
                    <p class="detail-card__text">Open the browser version for larger screens, planning sessions, reports and studio overview work.</p>
                    <a href="{{ $appWebUrl }}" class="btn btn--ghost btn--small" target="_blank" rel="noopener">Open Web App</a>
                </article>
            </div>
        </div>
    </section>

    <section class="section">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Studio Feedback</div>
                <h2 class="section__title">Loved by photographers and managers.</h2>
                <p class="section__desc">Local studios use Graphy7 to move from paper and chat chaos to a clean professional workflow.</p>
            </div>

            <div class="reviews-grid">
                @foreach ($reviews as $review)
                    <article class="review-card reveal">
                        <div class="review-card__avatar">{{ strtoupper(substr($review['name'], 0, 1)) }}</div>
                        <div>
                            <div class="review-card__name">{{ $review['name'] }}</div>
                            <div class="review-card__role">{{ $review['role'] }}</div>
                        </div>
                        <p class="review-card__text">"{{ $review['text'] }}"</p>
                    </article>
                @endforeach
            </div>
        </div>
    </section>

    <section id="download" class="section">
        <div class="container">
            <div class="cta-band reveal">
                <div class="cta-band__content">
                    <h2 class="cta-band__title">Ready to run your studio better?</h2>
                    <p class="cta-band__desc">Use Graphy7 on the web or install the Android app. Keep bookings, team and finance in one place.</p>
                </div>
                <div class="cta-band__actions">
                    <a href="{{ $appWebUrl }}" class="btn btn--light" target="_blank" rel="noopener">Open Web App</a>
                    <a href="{{ $appDownloadUrl }}" class="btn btn--ghost">Download APK</a>
                </div>
            </div>
        </div>
    </section>

    <footer class="footer">
        <div class="container">
            <div class="footer__grid">
                <div class="footer__brand">
                    <img class="brand-logo" src="{{ asset('landing/img/logo.png') }}" alt="Graphy7">
                    <span>Graphy<span style="color:var(--primary)">7</span></span>
                </div>
                <div class="footer__links">
                    <a href="#features" class="footer__link">Features</a>
                    <a href="#download" class="footer__link">Download</a>
                    <a href="{{ $appWebUrl }}" class="footer__link" target="_blank" rel="noopener">Web App</a>
                    <a href="{{ route('privacy') }}" class="footer__link">Privacy Policy</a>
                    <a href="{{ route('data-deletion') }}" class="footer__link">Data Deletion</a>
                </div>
            </div>
            <div class="footer__copy">Copyright {{ date('Y') }} Graphy7. Photography and event management for studios.</div>
        </div>
    </footer>

    <script type="module" src="{{ asset('landing/js/mountain-scene.js') }}"></script>
    <script src="{{ asset('landing/js/landing.js') }}?v=20260718-clean"></script>

    <script>
    (function () {
      var sent = 0;
      function report(message, stack) {
        if (sent >= 5) return;
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
        } catch (e) {}
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
