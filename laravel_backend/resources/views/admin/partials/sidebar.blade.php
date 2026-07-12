{{-- Admin sidebar — Graphy7 Admin design --}}
@php
    $navGroups = [
        ['label' => 'Overview', 'items' => [
            ['route' => 'admin.dashboard', 'label' => 'Dashboard', 'icon' => 'grid_view'],
            ['route' => 'admin.analytics', 'label' => 'Analytics', 'icon' => 'monitoring'],
        ]],
        ['label' => 'Users', 'items' => [
            ['route' => 'admin.users',   'label' => 'All Users',  'icon' => 'groups'],
            ['route' => 'admin.studios', 'label' => 'Businesses', 'icon' => 'storefront'],
        ]],
        // Bookings / Payments / Finance: read-only platform-wide lists.
        // Owner-side actions (approve/decline, payouts) stay in the owner app.
        ['label' => 'Operations', 'items' => [
            ['route' => 'admin.bookings',      'label' => 'Bookings',      'icon' => 'event_note'],
            ['route' => 'admin.payments',      'label' => 'Payments',      'icon' => 'payments'],
            ['route' => 'admin.finance',       'label' => 'Finance',       'icon' => 'account_balance_wallet'],
            ['route' => 'admin.subscriptions', 'label' => 'Subscriptions', 'icon' => 'workspace_premium'],
            ['route' => 'admin.coupons',       'label' => 'Coupons',       'icon' => 'sell'],
        ]],
        ['label' => 'Engagement', 'items' => [
            ['route' => 'admin.broadcasts', 'label' => 'Notifications', 'icon' => 'campaign'],
            ['route' => 'admin.files',      'label' => 'Files',         'icon' => 'folder'],
            ['route' => 'admin.support',    'label' => 'Support & FAQ', 'icon' => 'support_agent'],
        ]],
        ['label' => 'System', 'items' => [
            ['route' => 'admin.security', 'label' => 'Security',  'icon' => 'shield_lock'],
            ['route' => 'admin.audit',    'label' => 'Audit Log', 'icon' => 'receipt_long'],
            ['route' => 'admin.settings', 'label' => 'Settings',  'icon' => 'tune'],
        ]],
    ];
@endphp

<aside class="sidebar">
    <div class="sidebar__brand">
        <div class="sidebar__brand-mark">G7</div>
        <div>
            <div class="sidebar__brand-name">Graphy<span>7</span></div>
            <div class="sidebar__brand-sub">Admin Control</div>
        </div>
    </div>

    <nav class="sidebar__nav">
        @foreach ($navGroups as $group)
            <div class="nav-group">
                <div class="nav-group__label section-label">{{ $group['label'] }}</div>
                @foreach ($group['items'] as $item)
                    @php $exists = \Illuminate\Support\Facades\Route::has($item['route']); @endphp
                    <a class="nav-item {{ $exists && request()->routeIs($item['route']) ? 'is-active' : '' }}"
                       href="{{ $exists ? route($item['route']) : '#' }}">
                        <span class="material-symbols-rounded nav-item__icon" aria-hidden="true">{{ $item['icon'] }}</span>
                        <span>{{ $item['label'] }}</span>
                    </a>
                @endforeach
            </div>
        @endforeach
    </nav>

    <div class="sidebar__footer">
        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit" class="btn btn--ghost w-full">
                <span class="material-symbols-rounded" aria-hidden="true">logout</span>
                Sign Out
            </button>
        </form>
    </div>
</aside>
