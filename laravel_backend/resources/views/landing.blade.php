<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Clicker Pro — Run Your Photography Business</title>
    <meta name="description" content="Clicker Pro replaces a photography studio's notebook, WhatsApp groups, and Excel sheet with one app. Bookings, team, and money — in one place.">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Outfit:wght@400;500;600;700;800&family=IBM+Plex+Mono:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('landing/css/landing.css') }}">
</head>
<body>
    {{-- NAV --}}
    <nav class="nav">
        <a href="#top" class="nav__brand">
            <span class="nav__mark">C</span> Clicker Pro
        </a>
        <div class="nav__links">
            <a href="#features" class="nav__link">Features</a>
            <a href="#why" class="nav__link">Why Us</a>
            <a href="#download" class="nav__link">Download</a>
            <a href="{{ route('admin.login') }}" class="nav__cta">Admin Console</a>
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
            <h1 class="hero__title">Run Your<br><span class="accent">Photography</span><br>Business.</h1>
            <p class="hero__desc">
                One app for bookings, your team, and your money. Built for Bangladesh's
                photography studios — works offline, syncs everywhere.
            </p>
            <div class="hero__actions">
                <a href="#download" class="btn btn--primary">Get Started →</a>
                <a href="#features" class="btn btn--ghost">Explore Features</a>
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

    {{-- WHY / STATS --}}
    <section id="why" class="section" style="background:var(--bg-alt)">
        <div class="container">
            <div class="section--center">
                <div class="section__eyebrow">Why Clicker Pro</div>
                <h2 class="section__title">One App, Everything Sorted</h2>
                <p class="section__desc">Replace the notebook, the WhatsApp groups, and the Excel sheet with a single tool your whole team trusts.</p>
            </div>
            <div class="stats">
                <div class="reveal"><div class="stat__value">78+</div><div class="stat__label">Modules</div></div>
                <div class="reveal"><div class="stat__value">4</div><div class="stat__label">Roles</div></div>
                <div class="reveal"><div class="stat__value">100%</div><div class="stat__label">Offline Ready</div></div>
                <div class="reveal"><div class="stat__value">৳0</div><div class="stat__label">To Start</div></div>
            </div>
        </div>
    </section>

    {{-- CTA --}}
    <section id="download" class="section">
        <div class="container">
            <div class="cta-band reveal">
                <h2 class="cta-band__title">Ready to run your studio better?</h2>
                <p class="cta-band__desc">Download Clicker Pro and bring your bookings, team, and money into one place.</p>
                <a href="{{ asset('ClickerPro.apk') }}" class="btn btn--light">⬇ Download for Android</a>
            </div>
        </div>
    </section>

    {{-- FOOTER --}}
    <footer class="footer">
        <div class="container">
            <div class="footer__grid">
                <div class="footer__brand"><span class="nav__mark">C</span> Clicker Pro</div>
                <div class="footer__links">
                    <a href="#features" class="footer__link">Features</a>
                    <a href="#download" class="footer__link">Download</a>
                    <a href="{{ route('admin.login') }}" class="footer__link">Admin</a>
                </div>
            </div>
            <div class="footer__copy">© {{ date('Y') }} Clicker Pro · Photography &amp; event management for Bangladesh.</div>
        </div>
    </footer>

    <script type="module" src="{{ asset('landing/js/mountain-scene.js') }}"></script>
    <script src="{{ asset('landing/js/landing.js') }}"></script>
</body>
</html>
