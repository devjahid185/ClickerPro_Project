{{-- Admin login — standalone (no shell) --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign In · Clicker Pro Admin</title>
    <script>
        (function () {
            var t = localStorage.getItem('cp_admin_theme')
                || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
            document.documentElement.setAttribute('data-theme', t);
        })();
    </script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Outfit:wght@400;500;600;700;800&family=IBM+Plex+Mono:wght@500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('admin-assets/css/design-system.css') }}">
    <style>
        .auth-wrap { min-height: 100vh; display: grid; place-items: center; padding: var(--sp-6); }
        .auth-card { width: 100%; max-width: 400px; }
        .auth-brand { text-align: center; margin-bottom: var(--sp-6); }
        .auth-brand__mark {
            width: 56px; height: 56px; border-radius: var(--r-lg); margin: 0 auto var(--sp-3);
            background: linear-gradient(135deg, var(--primary-light), var(--primary));
            display: grid; place-items: center; color: #fff;
            font-family: var(--font-display); font-weight: 700; font-size: 26px;
        }
    </style>
</head>
<body>
    <div class="auth-wrap">
        <div class="auth-card">
            <div class="auth-brand">
                <div class="auth-brand__mark">C</div>
                <h1>Clicker Pro</h1>
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
                        <button type="submit" class="btn btn--primary w-full">Sign In</button>
                    </form>
                </div>
            </div>

            <p class="text-muted" style="text-align:center;margin-top:var(--sp-4);font-size:12px">
                Admin access only · Clicker Pro © {{ date('Y') }}
            </p>
        </div>
    </div>
    <script src="{{ asset('admin-assets/js/admin.js') }}"></script>
</body>
</html>
