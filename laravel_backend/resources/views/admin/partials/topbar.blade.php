{{-- Admin topbar — page title, theme toggle, admin identity --}}
@php $admin = auth()->user(); @endphp
<header class="topbar">
    <div class="flex items-center gap-3">
        <button class="theme-toggle menu-toggle" aria-label="Menu">☰</button>
        <span class="topbar__title">@yield('title', 'Dashboard')</span>
    </div>

    <div class="topbar__actions">
        <button class="theme-toggle" data-theme-toggle aria-label="Toggle theme">☾</button>
        @if ($admin)
            <div class="flex items-center gap-2">
                <div class="avatar">{{ strtoupper(substr($admin->name ?? $admin->email, 0, 1)) }}</div>
                <div style="line-height:1.2">
                    <div style="font-weight:600;font-size:13px">{{ $admin->full_name ?? 'Admin' }}</div>
                    <div class="text-muted mono" style="font-size:11px">{{ $admin->email }}</div>
                </div>
            </div>
        @endif
    </div>
</header>
