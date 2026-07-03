@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('content')
    @php
        // NOTE: Revenue and Total Bookings cards were intentionally removed —
        // the admin console must not surface any user's finance or booking data,
        // not even aggregated. Only non-financial platform counts remain.
        $cards = [
            ['label' => 'Total Users',    'value' => number_format($stats['totalUsers'] ?? 0),     'icon' => '⊙', 'tint' => 'var(--primary-soft)', 'color' => 'var(--primary)'],
            ['label' => 'Owners',         'value' => number_format($stats['owners'] ?? 0),         'icon' => '⬡', 'tint' => 'var(--info-soft)',    'color' => 'var(--info)'],
            ['label' => 'Freelancers',    'value' => number_format($stats['freelancers'] ?? 0),    'icon' => '◇', 'tint' => 'var(--success-soft)', 'color' => 'var(--success)'],
            ['label' => 'Total Clients',  'value' => number_format($stats['totalClients'] ?? 0),   'icon' => '◌', 'tint' => 'var(--primary-soft)', 'color' => 'var(--primary)'],
            ['label' => 'Active Broadcasts', 'value' => number_format($stats['activeBroadcasts'] ?? 0), 'icon' => '◉', 'tint' => 'var(--info-soft)',   'color' => 'var(--info)'],
            ['label' => 'Open Tickets',   'value' => number_format($stats['openTickets'] ?? 0),    'icon' => '⊛', 'tint' => 'var(--danger-soft)',  'color' => 'var(--danger)'],
        ];
    @endphp

    <div class="page-header">
        <div>
            <h1>Overview</h1>
            <p class="page-header__sub">Live platform metrics across all studios.</p>
        </div>
    </div>

    <div class="stat-grid">
        @foreach ($cards as $c)
            <div class="stat-card">
                <div class="stat-card__icon" style="background:{{ $c['tint'] }};color:{{ $c['color'] }}">{{ $c['icon'] }}</div>
                <div class="stat-card__value">{{ $c['value'] }}</div>
                <div class="stat-card__label">{{ $c['label'] }}</div>
            </div>
        @endforeach
    </div>

    <div class="card mt-4">
        <div class="card__header">
            <div>
                <span class="card__title">Quick Actions</span>
                <p class="card__meta text-dim" style="margin-top:8px;font-size:13px;">Jump to the landing editor, live site, or settings panel.</p>
            </div>
        </div>
        <div class="card__body">
            <div class="toolbar">
                <a href="{{ route('landing') }}" class="btn btn--ghost">View Landing Page</a>
                <a href="{{ route('admin.settings') }}" class="btn btn--primary">Edit Landing Settings</a>
            </div>
        </div>
    </div>

    <div class="card mt-4">
        <div class="card__header">
            <span class="card__title">Foundation Ready</span>
            <span class="badge badge--success">Phase 0</span>
        </div>
        <div class="card__body text-dim">
            Design system, dark/light theming, base layout, and session auth are wired against the
            existing Laravel API. Operations &amp; system modules (Users, Bookings, Finance, Broadcasts…)
            will be ported from the Next.js panel onto this foundation — one module at a time.
        </div>
    </div>
@endsection
