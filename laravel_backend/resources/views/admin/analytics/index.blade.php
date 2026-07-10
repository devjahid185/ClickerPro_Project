@extends('admin.layouts.app')

@section('title', 'Analytics')

@section('content')
    @php
        $signupSeries = collect($signups)->map(fn ($r) => [
            'label' => isset($r['month']) ? \Illuminate\Support\Str::of($r['month'])->afterLast('-') : '',
            'value' => (int) ($r['count'] ?? 0),
        ])->take(-12)->values();
        $maxSignup = max(1, $signupSeries->max('value') ?? 1);
        $totalSignups = $signupSeries->sum('value');
        $latest = $signupSeries->last()['value'] ?? 0;
    @endphp

    <div class="page-header">
        <div>
            <span class="eyebrow">Privacy-Safe Analytics</span>
            <h1>Growth Overview</h1>
            <p class="page-header__sub">Track platform account growth without exposing any studio booking, payment, income, or expense records.</p>
        </div>
    </div>

    <div class="stat-grid mb-6">
        <section class="stat-card stat-card--orange">
            <div class="stat-card__top">
                <span class="material-symbols-rounded stat-card__icon" aria-hidden="true">person_add</span>
                <span class="stat-card__label">Signups</span>
            </div>
            <div class="stat-card__value">{{ number_format($totalSignups) }}</div>
            <div class="stat-card__meta">Shown for the current trend window</div>
        </section>
        <section class="stat-card stat-card--teal">
            <div class="stat-card__top">
                <span class="material-symbols-rounded stat-card__icon" aria-hidden="true">calendar_month</span>
                <span class="stat-card__label">Latest Month</span>
            </div>
            <div class="stat-card__value">{{ number_format($latest) }}</div>
            <div class="stat-card__meta">New accounts in the latest bucket</div>
        </section>
        <section class="stat-card stat-card--green">
            <div class="stat-card__top">
                <span class="material-symbols-rounded stat-card__icon" aria-hidden="true">lock</span>
                <span class="stat-card__label">Privacy</span>
            </div>
            <div class="stat-card__value">On</div>
            <div class="stat-card__meta">No bookings or finance analytics displayed</div>
        </section>
    </div>

    <div class="dashboard-grid">
        <section class="card dashboard-panel--wide">
            <div class="card__header">
                <div>
                    <span class="card__title">New Signups</span>
                    <p class="card__meta">Monthly account creation trend.</p>
                </div>
                <span class="count-pill">{{ $signupSeries->count() }} months</span>
            </div>
            <div class="card__body">
                @if ($signupSeries->isEmpty())
                    <div class="empty-state">
                        <span class="material-symbols-rounded empty-state__icon" aria-hidden="true">monitoring</span>
                        <p>No signup data yet.</p>
                    </div>
                @else
                    <div class="bar-chart">
                        @foreach ($signupSeries as $pt)
                            <div class="bar-chart__col">
                                <span class="bar-chart__val">{{ $pt['value'] }}</span>
                                <div class="bar-chart__bar" style="height: {{ max(6, round($pt['value'] / $maxSignup * 132)) }}px"></div>
                                <span class="bar-chart__label">{{ $pt['label'] }}</span>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>
        </section>

        <section class="card">
            <div class="card__header">
                <div>
                    <span class="card__title">Data Boundary</span>
                    <p class="card__meta">What this page intentionally excludes.</p>
                </div>
                <span class="badge badge--success">Protected</span>
            </div>
            <div class="card__body">
                <div class="system-list">
                    <div class="system-row">
                        <span class="material-symbols-rounded" aria-hidden="true">event_busy</span>
                        <div>
                            <strong>No booking analytics</strong>
                            <p>Studio schedules remain owner-private.</p>
                        </div>
                    </div>
                    <div class="system-row">
                        <span class="material-symbols-rounded" aria-hidden="true">payments</span>
                        <div>
                            <strong>No finance analytics</strong>
                            <p>Payments, income, and expenses are not surfaced.</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>
@endsection
