{{-- Admin login - standalone --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign In | Graphy7 Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('admin-assets/css/design-system.css') }}">
</head>
<body>
    <div class="auth-wrap">
        <section class="auth-hero">
            <div class="auth-brand auth-brand--hero">
                <div class="auth-brand__mark">G7</div>
                <div>
                    <h1>Graphy<span style="color:var(--primary)">7</span></h1>
                    <div class="section-label auth-brand__subtitle">Admin Control</div>
                </div>
            </div>

            <div class="auth-hero__copy">
                <span class="eyebrow">Platform Control Room</span>
                <h2>Run the whole platform — users, bookings, finance, support — from one calm console.</h2>
                <p>Search any account by name, phone, or email. Review bookings and payments across every studio, manage broadcasts, and keep the system secure.</p>
            </div>

            <div class="auth-preview">
                <div class="auth-preview__top">
                    <span>System Pulse</span>
                    <span class="badge badge--success">Protected</span>
                </div>
                <div class="auth-preview__grid">
                    <div>
                        <span class="material-symbols-rounded" aria-hidden="true">groups</span>
                        <strong>Users</strong>
                        <small>Account controls</small>
                    </div>
                    <div>
                        <span class="material-symbols-rounded" aria-hidden="true">support_agent</span>
                        <strong>Support</strong>
                        <small>Ticket queue</small>
                    </div>
                    <div>
                        <span class="material-symbols-rounded" aria-hidden="true">campaign</span>
                        <strong>Broadcasts</strong>
                        <small>Announcements</small>
                    </div>
                    <div>
                        <span class="material-symbols-rounded" aria-hidden="true">shield_lock</span>
                        <strong>Security</strong>
                        <small>Access review</small>
                    </div>
                </div>
            </div>
        </section>

        <div class="auth-card">
            <div class="auth-brand auth-brand--compact">
                <div class="auth-brand__mark">G7</div>
                <h1>Graphy<span style="color:var(--primary)">7</span></h1>
                <div class="section-label auth-brand__subtitle">Admin Console</div>
            </div>

            <div class="card">
                <div class="card__body">
                    @if (session('error'))
                        <div class="flash flash--danger">{{ session('error') }}</div>
                    @endif

                    <form method="POST" action="{{ route('admin.login.submit') }}">
                        @csrf
                        <div class="field">
                            <label class="field__label" for="email">Email</label>
                            <input class="input" type="email" id="email" name="email"
                                   value="{{ old('email') }}" required autofocus autocomplete="username">
                        </div>
                        <div class="field">
                            <label class="field__label" for="password">Password</label>
                            <input class="input" type="password" id="password" name="password"
                                   required autocomplete="current-password">
                        </div>
                        <label class="flex items-center gap-2 mb-4" style="font-size:13px;color:var(--text-dim)">
                            <input type="checkbox" name="remember" value="1"> Keep me signed in
                        </label>
                        <button type="submit" class="btn btn--primary w-full">
                            <span class="material-symbols-rounded" aria-hidden="true">login</span>
                            Sign In
                        </button>
                        @env('local')
                            <div class="auth-hint">
                                <span class="material-symbols-rounded" aria-hidden="true">key</span>
                                <span>Local seed: <strong>admin@clickerpro.app</strong> / <strong>Admin@1234</strong></span>
                            </div>
                        @endenv
                    </form>
                </div>
            </div>

            <p class="text-muted" style="text-align:center;margin-top:var(--sp-4);font-size:12px">
                Admin access only | Graphy7 {{ date('Y') }}
            </p>
        </div>
    </div>
    <script src="{{ asset('admin-assets/js/admin.js') }}"></script>
</body>
</html>
