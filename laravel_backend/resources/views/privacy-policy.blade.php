<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Graphy7 Privacy Policy</title>
    <meta name="description" content="Privacy Policy for Graphy7 photography studio management app.">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="apple-touch-icon" href="{{ asset('landing/img/apple-touch-icon.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #f6f8fb;
            --card: #ffffff;
            --text: #162033;
            --muted: #647084;
            --line: #dbe3ef;
            --primary: #ff5a1f;
            --dark: #0e1729;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Outfit, Arial, sans-serif;
            color: var(--text);
            background: linear-gradient(180deg, #fff7f2 0, var(--bg) 330px);
            line-height: 1.65;
        }

        a { color: var(--primary); text-decoration: none; font-weight: 700; }

        .nav, .hero, .content, .footer {
            width: min(1040px, calc(100% - 32px));
            margin: 0 auto;
        }

        .nav {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 22px 0;
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            color: var(--dark);
            font-weight: 800;
            letter-spacing: 0;
        }

        .brand img { width: 34px; height: 34px; object-fit: contain; }

        .nav__links { display: flex; gap: 18px; align-items: center; }
        .nav__links a { color: var(--muted); font-size: 14px; }

        .hero {
            padding: 54px 0 32px;
        }

        .eyebrow {
            color: var(--primary);
            font-size: 13px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .12em;
        }

        h1 {
            margin: 12px 0 16px;
            color: var(--dark);
            font-size: clamp(36px, 7vw, 68px);
            line-height: 1.02;
            letter-spacing: 0;
        }

        .lead {
            max-width: 760px;
            margin: 0;
            color: #445066;
            font-size: 19px;
        }

        .content {
            display: grid;
            grid-template-columns: 240px 1fr;
            gap: 28px;
            align-items: start;
            padding: 18px 0 80px;
        }

        .toc, .policy {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 18px;
            box-shadow: 0 20px 60px rgba(15, 23, 42, .08);
        }

        .toc {
            position: sticky;
            top: 18px;
            padding: 18px;
        }

        .toc a {
            display: block;
            color: #506079;
            font-size: 14px;
            padding: 8px 0;
        }

        .policy { padding: clamp(22px, 4vw, 44px); }

        h2 {
            margin: 34px 0 10px;
            color: var(--dark);
            font-size: 24px;
            letter-spacing: 0;
        }

        h2:first-child { margin-top: 0; }

        ul { padding-left: 22px; }
        li { margin: 8px 0; }

        .notice {
            margin: 24px 0;
            padding: 18px;
            border: 1px solid #ffd2bd;
            background: #fff4ed;
            border-radius: 14px;
            color: #7a3418;
        }

        .meta {
            color: var(--muted);
            font-size: 14px;
        }

        .footer {
            padding: 28px 0 44px;
            color: var(--muted);
            font-size: 14px;
            border-top: 1px solid var(--line);
        }

        @media (max-width: 780px) {
            .content { grid-template-columns: 1fr; }
            .toc { position: static; }
            .nav { align-items: flex-start; gap: 16px; flex-direction: column; }
        }
    </style>
</head>
<body>
    <nav class="nav" aria-label="Legal navigation">
        <a class="brand" href="{{ route('landing') }}">
            <img src="{{ asset('landing/img/logo.png') }}" alt="Graphy7">
            <span>Graphy7</span>
        </a>
        <div class="nav__links">
            <a href="{{ route('landing') }}">Home</a>
            <a href="{{ route('data-deletion') }}">Data Deletion</a>
        </div>
    </nav>

    <header class="hero">
        <div class="eyebrow">Privacy Policy</div>
        <h1>Graphy7 Privacy Policy</h1>
        <p class="lead">This policy explains how Graphy7 collects, uses, stores, and protects information when you use the Graphy7 mobile app, web app, admin tools, and related services.</p>
        <p class="meta">Effective date: July 20, 2026. Last updated: July 20, 2026.</p>
    </header>

    <main class="content">
        <aside class="toc">
            <a href="#who">Who We Are</a>
            <a href="#data">Data We Collect</a>
            <a href="#use">How We Use Data</a>
            <a href="#sharing">Sharing</a>
            <a href="#security">Security</a>
            <a href="#choices">Your Choices</a>
            <a href="#retention">Retention</a>
            <a href="#deletion">Deletion</a>
            <a href="#contact">Contact</a>
        </aside>

        <article class="policy">
            <section id="who">
                <h2>Who We Are</h2>
                <p>Graphy7 is a photography and event studio management platform. The app helps studios manage bookings, clients, team members, payments, invoices, schedules, notifications, files, and reports.</p>
            </section>

            <section id="data">
                <h2>Data We Collect</h2>
                <p>Depending on the features you use, Graphy7 may collect or process the following information:</p>
                <ul>
                    <li>Account and profile data, such as name, email address, phone number, role, business name, password, and account status.</li>
                    <li>Studio and booking data, such as client names, contact details, event date, event address, booking package, assigned team members, notes, delivery status, and calendar details.</li>
                    <li>Payment and finance data, such as package amount, advance, due amount, payment method, transaction notes, invoices, expenses, and payout records.</li>
                    <li>Messages and support data, such as team announcements, broadcast notifications, support requests, and replies.</li>
                    <li>Photos, files, and documents uploaded by you for studio, booking, delivery, or support workflows.</li>
                    <li>Location data if you allow location permission, mainly to show live weather and location-based app features.</li>
                    <li>Calendar event data when you choose to save confirmed bookings to the device calendar.</li>
                    <li>Device and app data, such as push notification tokens, app version, device identifiers used for notifications, crash logs, diagnostics, login activity, IP address, and security logs.</li>
                </ul>
                <div class="notice">Graphy7 does not sell your personal data and does not use your data for third-party advertising.</div>
            </section>

            <section id="use">
                <h2>How We Use Data</h2>
                <p>We use information to provide and improve the Graphy7 service, including to:</p>
                <ul>
                    <li>Create and secure user accounts, including OTP verification and login protection.</li>
                    <li>Manage bookings, clients, teams, invoices, payments, reports, and studio operations.</li>
                    <li>Send booking reminders, assignment notifications, announcements, support replies, and account emails.</li>
                    <li>Sync data between the mobile app, web app, and backend server.</li>
                    <li>Show live weather and calendar-based features when permissions are granted.</li>
                    <li>Detect abuse, troubleshoot errors, improve performance, and maintain platform security.</li>
                </ul>
            </section>

            <section id="sharing">
                <h2>How Data Is Shared</h2>
                <p>We share data only as needed to operate the service, comply with law, or complete actions requested by you. This can include hosting providers, database and storage providers, email delivery providers, push notification services, analytics or crash diagnostic tools, Google services used for sign-in, calendar, or sheets workflows, and payment or communication services you choose to use.</p>
                <p>Your studio data can also be visible to authorized team members based on their role and permissions inside Graphy7.</p>
            </section>

            <section id="security">
                <h2>Security</h2>
                <p>We use reasonable technical and organizational safeguards to protect your data. Data is transmitted using secure HTTPS connections. Passwords and sensitive authentication tokens are protected using industry-standard practices. No system is perfectly secure, so you should keep your password and OTP codes private.</p>
            </section>

            <section id="choices">
                <h2>Your Choices and Permissions</h2>
                <p>You can update account information in the app where available. You can control device permissions such as location, notifications, calendar, photos, and files from your device settings. Some features may not work if required permissions are disabled.</p>
            </section>

            <section id="retention">
                <h2>Data Retention</h2>
                <p>We keep personal data for as long as needed to provide Graphy7, maintain business records, meet legal obligations, resolve disputes, prevent fraud, and enforce our agreements. Some data may remain in backups or logs for a limited period after deletion.</p>
            </section>

            <section id="deletion">
                <h2>Data Deletion</h2>
                <p>You may request account and data deletion at any time. Please visit <a href="{{ route('data-deletion') }}">Graphy7 Data Deletion</a> for the full process. After verification, we will delete or anonymize eligible data unless we must retain limited records for legal, security, accounting, or fraud-prevention reasons.</p>
            </section>

            <section id="children">
                <h2>Children</h2>
                <p>Graphy7 is intended for studio owners, managers, freelancers, and professional users. It is not directed to children under 13 years old.</p>
            </section>

            <section id="changes">
                <h2>Changes to This Policy</h2>
                <p>We may update this policy when Graphy7 features, laws, or operational practices change. The latest version will always be available on this page.</p>
            </section>

            <section id="contact">
                <h2>Contact</h2>
                <p>For privacy questions or requests, contact Graphy7 support at <a href="mailto:support@graphy7.tech">support@graphy7.tech</a>.</p>
            </section>
        </article>
    </main>

    <footer class="footer">Copyright {{ date('Y') }} Graphy7. All rights reserved.</footer>
</body>
</html>
