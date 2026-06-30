{{-- Admin sidebar — nav mirrors the Next.js Shell groups --}}
@php
    $navGroups = [
        ['label' => 'Overview', 'items' => [
            ['route' => 'admin.dashboard', 'label' => 'Dashboard', 'icon' => '◈'],
            ['route' => 'admin.analytics', 'label' => 'Analytics', 'icon' => '↗'],
        ]],
        ['label' => 'Users', 'items' => [
            ['route' => 'admin.users',   'label' => 'All Users',  'icon' => '⊙'],
            ['route' => 'admin.studios', 'label' => 'Businesses', 'icon' => '⬡'],
        ]],
        // NOTE: Bookings / Finance / Payments were intentionally removed —
        // the admin console must not expose any user's booking or finance data.
        ['label' => 'Operations', 'items' => [
            ['route' => 'admin.subscriptions', 'label' => 'Subscriptions', 'icon' => '◈'],
            ['route' => 'admin.coupons',       'label' => 'Coupons',       'icon' => '⊕'],
        ]],
        ['label' => 'Engagement', 'items' => [
            ['route' => 'admin.broadcasts', 'label' => 'Notifications', 'icon' => '◉'],
            ['route' => 'admin.files',      'label' => 'Files',         'icon' => '▣'],
            ['route' => 'admin.support',    'label' => 'Support & FAQ', 'icon' => '◌'],
        ]],
        ['label' => 'System', 'items' => [
            ['route' => 'admin.security', 'label' => 'Security',  'icon' => '⊛'],
            ['route' => 'admin.audit',    'label' => 'Audit Log', 'icon' => '≡'],
            ['route' => 'admin.settings', 'label' => 'Settings',  'icon' => '⊞'],
        ]],
    ];
@endphp

<aside class="sidebar">
    <div class="sidebar__brand">
        <div class="sidebar__brand-mark">C</div>
        <div>
            <div class="sidebar__brand-name">Clicker Pro</div>
            <div class="sidebar__brand-sub">Admin Console</div>
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
                        <span class="nav-item__icon">{{ $item['icon'] }}</span>
                        <span>{{ $item['label'] }}</span>
                    </a>
                @endforeach
            </div>
        @endforeach
    </nav>

    <div class="sidebar__footer">
        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit" class="btn btn--ghost w-full">Sign Out</button>
        </form>
    </div>
</aside>
