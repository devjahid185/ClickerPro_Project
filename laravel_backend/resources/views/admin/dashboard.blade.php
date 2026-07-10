@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('content')
    @php
        // The admin dashboard intentionally avoids studio bookings, revenue,
        // payments, income, and expense data. Keep these metrics platform-safe.
        $totalUsers = (int) ($stats['totalUsers'] ?? 0);
        $owners = (int) ($stats['owners'] ?? 0);
        $freelancers = (int) ($stats['freelancers'] ?? 0);
        $admins = (int) ($stats['admins'] ?? 0);
        $clients = (int) ($stats['totalClients'] ?? 0);
        $broadcasts = (int) ($stats['activeBroadcasts'] ?? 0);
        $tickets = (int) ($stats['openTickets'] ?? 0);
        $accountBase = max(1, $owners + $freelancers + $admins);

        $cards = [
            ['label' => 'Total Users', 'value' => number_format($totalUsers), 'icon' => 'groups', 'tone' => 'orange', 'meta' => 'All registered accounts'],
            ['label' => 'Studio Owners', 'value' => number_format($owners), 'icon' => 'storefront', 'tone' => 'teal', 'meta' => 'Owner or both roles'],
            ['label' => 'Freelancers', 'value' => number_format($freelancers), 'icon' => 'badge', 'tone' => 'green', 'meta' => 'Freelancer or both roles'],
            ['label' => 'Open Tickets', 'value' => number_format($tickets), 'icon' => 'support_agent', 'tone' => $tickets > 0 ? 'red' : 'green', 'meta' => 'Needs admin attention'],
        ];

        $roleRows = [
            ['label' => 'Owners', 'value' => $owners, 'pct' => round($owners / $accountBase * 100), 'tone' => 'teal'],
            ['label' => 'Freelancers', 'value' => $freelancers, 'pct' => round($freelancers / $accountBase * 100), 'tone' => 'green'],
            ['label' => 'Admins', 'value' => $admins, 'pct' => round($admins / $accountBase * 100), 'tone' => 'orange'],
        ];

        $operations = [
            ['label' => 'Active Broadcasts', 'value' => $broadcasts, 'icon' => 'campaign', 'href' => route('admin.broadcasts')],
            ['label' => 'Client Records', 'value' => $clients, 'icon' => 'contacts', 'href' => route('admin.analytics')],
            ['label' => 'Feature Flags', 'value' => 'Manage', 'icon' => 'workspace_premium', 'href' => route('admin.subscriptions')],
            ['label' => 'Security Center', 'value' => 'Review', 'icon' => 'shield_lock', 'href' => route('admin.security')],
        ];
    @endphp

    <div class="page-header">
        <div>
            <span class="eyebrow">Clicker Pro Admin</span>
            <h1>Platform Overview</h1>
            <p class="page-header__sub">Monitor accounts, support load, broadcasts, and system controls without exposing studio-private work.</p>
        </div>
        <div class="page-header__actions">
            <a href="{{ route('landing') }}" class="btn btn--ghost">
                <span class="material-symbols-rounded" aria-hidden="true">open_in_new</span>
                Landing
            </a>
            <a href="{{ route('admin.settings') }}" class="btn btn--primary">
                <span class="material-symbols-rounded" aria-hidden="true">tune</span>
                Settings
            </a>
        </div>
    </div>

    <div class="stat-grid">
        @foreach ($cards as $c)
            <section class="stat-card stat-card--{{ $c['tone'] }}">
                <div class="stat-card__top">
                    <span class="material-symbols-rounded stat-card__icon" aria-hidden="true">{{ $c['icon'] }}</span>
                    <span class="stat-card__label">{{ $c['label'] }}</span>
                </div>
                <div class="stat-card__value">{{ $c['value'] }}</div>
                <div class="stat-card__meta">{{ $c['meta'] }}</div>
            </section>
        @endforeach
    </div>

    <div class="dashboard-grid mt-4">
        <section class="card dashboard-panel dashboard-panel--wide">
            <div class="card__header">
                <div>
                    <span class="card__title">Account Mix</span>
                    <p class="card__meta">Role distribution across the platform.</p>
                </div>
                <span class="count-pill">{{ number_format($accountBase) }} role records</span>
            </div>
            <div class="card__body">
                <div class="progress-stack">
                    @foreach ($roleRows as $row)
                        <div class="progress-row">
                            <div class="progress-row__head">
                                <span>{{ $row['label'] }}</span>
                                <span class="mono">{{ number_format($row['value']) }} / {{ $row['pct'] }}%</span>
                            </div>
                            <div class="progress-row__track">
                                <div class="progress-row__bar progress-row__bar--{{ $row['tone'] }}" style="width: {{ $row['pct'] }}%"></div>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        </section>

        <section class="card dashboard-panel">
            <div class="card__header">
                <div>
                    <span class="card__title">Operations</span>
                    <p class="card__meta">High-frequency admin areas.</p>
                </div>
            </div>
            <div class="quick-list">
                @foreach ($operations as $op)
                    <a class="quick-link" href="{{ $op['href'] }}">
                        <span class="material-symbols-rounded quick-link__icon" aria-hidden="true">{{ $op['icon'] }}</span>
                        <span>{{ $op['label'] }}</span>
                        <strong>{{ is_numeric($op['value']) ? number_format($op['value']) : $op['value'] }}</strong>
                    </a>
                @endforeach
            </div>
        </section>
    </div>

    <div class="dashboard-grid mt-4">
        <section class="card">
            <div class="card__header">
                <div>
                    <span class="card__title">Admin Queue</span>
                    <p class="card__meta">Things worth checking first.</p>
                </div>
            </div>
            <div class="card__body">
                <div class="system-list">
                    <a class="system-row" href="{{ route('admin.support') }}">
                        <span class="material-symbols-rounded" aria-hidden="true">support_agent</span>
                        <div>
                            <strong>{{ number_format($tickets) }} open support tickets</strong>
                            <p>Review user issues and FAQ updates.</p>
                        </div>
                        <span class="badge {{ $tickets > 0 ? 'badge--warning' : 'badge--success' }}">{{ $tickets > 0 ? 'Open' : 'Clear' }}</span>
                    </a>
                    <a class="system-row" href="{{ route('admin.broadcasts') }}">
                        <span class="material-symbols-rounded" aria-hidden="true">campaign</span>
                        <div>
                            <strong>{{ number_format($broadcasts) }} active broadcasts</strong>
                            <p>Manage app-wide announcements.</p>
                        </div>
                        <span class="badge badge--info">Live</span>
                    </a>
                    <a class="system-row" href="{{ route('admin.audit') }}">
                        <span class="material-symbols-rounded" aria-hidden="true">receipt_long</span>
                        <div>
                            <strong>Audit log</strong>
                            <p>Trace recent admin activity.</p>
                        </div>
                        <span class="badge badge--neutral">System</span>
                    </a>
                </div>
            </div>
        </section>

        <section class="card">
            <div class="card__header">
                <div>
                    <span class="card__title">Privacy Boundary</span>
                    <p class="card__meta">Current console policy.</p>
                </div>
                <span class="badge badge--success">Protected</span>
            </div>
            <div class="card__body">
                <div class="privacy-box">
                    <span class="material-symbols-rounded" aria-hidden="true">lock</span>
                    <div>
                        <strong>Studio operations stay owner-controlled.</strong>
                        <p>Admin screens are scoped to accounts, platform settings, support, security, and broadcasts. Booking and finance dashboards are intentionally absent.</p>
                    </div>
                </div>
            </div>
        </section>
    </div>
@endsection
