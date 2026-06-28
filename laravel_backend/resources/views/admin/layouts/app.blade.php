{{-- Clicker Pro Admin — base layout (Phase 0 foundation) --}}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Dashboard') · Clicker Pro Admin</title>

    {{-- Prevent theme flash: set data-theme before paint --}}
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
    @stack('styles')
</head>
<body>
    <div class="admin-shell">
        @include('admin.partials.sidebar')

        <div class="admin-main">
            @include('admin.partials.topbar')

            <main class="admin-content">
                @if (session('status'))
                    <div class="flash flash--success">{{ session('status') }}</div>
                @endif
                @if (session('error'))
                    <div class="flash flash--danger">{{ session('error') }}</div>
                @endif
                @if ($errors->any())
                    <div class="flash flash--danger">
                        {{ $errors->first() }}
                    </div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>

    <div class="scrim"></div>
    <script src="{{ asset('admin-assets/js/admin.js') }}"></script>
    @stack('scripts')
</body>
</html>
