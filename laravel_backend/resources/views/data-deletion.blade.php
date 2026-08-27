<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Graphy7 Data Deletion Request</title>
    <meta name="description" content="How to request deletion of your Graphy7 account and app data.">
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
            --success: #13795b;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Outfit, Arial, sans-serif;
            color: var(--text);
            background: linear-gradient(180deg, #fff7f2 0, var(--bg) 340px);
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

        .hero { padding: 54px 0 30px; }

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
            font-size: clamp(36px, 7vw, 66px);
            line-height: 1.02;
            letter-spacing: 0;
        }

        .lead {
            max-width: 780px;
            margin: 0;
            color: #445066;
            font-size: 19px;
        }

        .content {
            display: grid;
            grid-template-columns: 1fr;
            gap: 22px;
            padding: 18px 0 80px;
        }

        .panel {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 18px;
            box-shadow: 0 20px 60px rgba(15, 23, 42, .08);
            padding: clamp(22px, 4vw, 44px);
        }

        .steps {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 16px;
            margin: 28px 0;
        }

        .step {
            border: 1px solid var(--line);
            border-radius: 16px;
            padding: 20px;
            background: #fbfdff;
        }

        .step__number {
            width: 34px;
            height: 34px;
            display: grid;
            place-items: center;
            border-radius: 50%;
            background: var(--primary);
            color: white;
            font-weight: 800;
        }

        h2 {
            margin: 34px 0 10px;
            color: var(--dark);
            font-size: 24px;
            letter-spacing: 0;
        }

        h3 {
            margin: 16px 0 8px;
            color: var(--dark);
            font-size: 18px;
            letter-spacing: 0;
        }

        ul { padding-left: 22px; }
        li { margin: 8px 0; }

        .notice {
            margin: 24px 0;
            padding: 18px;
            border: 1px solid #cfeadd;
            background: #f0fbf6;
            border-radius: 14px;
            color: var(--success);
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

        @media (max-width: 820px) {
            .steps { grid-template-columns: 1fr; }
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
            <a href="{{ route('privacy') }}">Privacy Policy</a>
        </div>
    </nav>

    <header class="hero">
        <div class="eyebrow">Account and Data Deletion</div>
        <h1>Graphy7 Data Deletion Request</h1>
        <p class="lead">You can request deletion of your Graphy7 account and eligible app data. This page explains the request process, what is deleted, what may be retained, and how long it normally takes.</p>
        <p class="meta">Effective date: July 20, 2026. Last updated: July 20, 2026.</p>
    </header>

    <main class="content">
        <article class="panel">
            <h2>How to Request Deletion</h2>
            <div class="steps">
                <section class="step">
                    <div class="step__number">1</div>
                    <h3>Send Your Request</h3>
                    <p>Email <a href="mailto:support@graphy7.tech?subject=Graphy7%20Data%20Deletion%20Request">support@graphy7.tech</a> with the subject line <strong>Graphy7 Data Deletion Request</strong>.</p>
                </section>
                <section class="step">
                    <div class="step__number">2</div>
                    <h3>Verify the Account</h3>
                    <p>Include your Graphy7 account email, phone number, and studio or business name if available. Never send your password or OTP code.</p>
                </section>
                <section class="step">
                    <div class="step__number">3</div>
                    <h3>Confirmation</h3>
                    <p>After verification, we will process the deletion and send confirmation to the account email.</p>
                </section>
            </div>

            <div class="notice">We normally acknowledge deletion requests within 7 days and complete eligible deletion within 30 days, unless legal, security, fraud-prevention, or technical backup limits require more time.</div>

            <h2>Data We Delete</h2>
            <p>When a verified deletion request is completed, Graphy7 deletes or anonymizes eligible account data, which may include:</p>
            <ul>
                <li>User account profile, login access, role, business profile, and contact details.</li>
                <li>Studio records such as bookings, clients, notes, team assignments, invoices, reports, and operational records linked only to the deleted account.</li>
                <li>Payment and finance entries where deletion is legally allowed.</li>
                <li>Uploaded files, photos, documents, support messages, device tokens, and app notification records where available.</li>
                <li>Calendar, location, and weather-related app data stored by Graphy7, where available.</li>
            </ul>

            <h2>Data That May Be Retained</h2>
            <p>Some data may be retained when required or allowed by law, security, accounting, dispute resolution, fraud prevention, or backup operations. This can include:</p>
            <ul>
                <li>Financial records, invoices, payment records, tax or accounting records that must be kept for legal reasons.</li>
                <li>Security logs, abuse-prevention logs, and audit records.</li>
                <li>Information needed to protect other users, team members, clients, or active studio records.</li>
                <li>Encrypted backups, which are removed according to normal backup rotation schedules.</li>
                <li>Aggregated or anonymized data that no longer identifies you.</li>
            </ul>

            <h2>Device Permissions</h2>
            <p>You can also remove Graphy7 permissions directly from your device settings, including location, notifications, calendar, photos, and files. Removing device permissions does not automatically delete server-side account data, so please send a deletion request if you want the account removed.</p>

            <h2>Contact</h2>
            <p>For account deletion or privacy questions, contact <a href="mailto:support@graphy7.tech">support@graphy7.tech</a>.</p>
            <p>Privacy Policy: <a href="{{ route('privacy') }}">{{ route('privacy') }}</a></p>
        </article>
    </main>

    <footer class="footer">Copyright {{ date('Y') }} Graphy7. All rights reserved.</footer>
</body>
</html>
