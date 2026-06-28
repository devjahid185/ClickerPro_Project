@extends('admin.layouts.app')

@section('title', 'Analytics')

@section('content')
    @php
        $mk = fn ($rows, $key) => collect($rows)->map(fn ($r) => [
            'label' => isset($r['month']) ? \Illuminate\Support\Str::of($r['month'])->afterLast('-') : '',
            'value' => (int) ($r[$key] ?? $r['count'] ?? 0),
        ])->take(-6)->values();
        $signupSeries  = $mk($signups, 'count');
        $bookingSeries = $mk($bookings, 'count');
        $maxSignup  = max(1, $signupSeries->max('value') ?? 1);
        $maxBooking = max(1, $bookingSeries->max('value') ?? 1);
        $statusTotal = max(1, collect($statusBreakdown)->sum(fn ($s) => (int) ($s['count'] ?? 0)));
    @endphp

    <div class="page-header"><div><h1>Analytics</h1><p class="page-header__sub">Growth trends and platform breakdown.</p></div></div>

    <div class="grid mb-6" style="grid-template-columns: 1fr 1fr; gap: var(--sp-5);">
        <div class="card">
            <div class="card__header"><span class="card__title">New Signups (6 mo)</span></div>
            <div class="card__body">
                @if ($signupSeries->isEmpty())<div class="empty-state"><p>No data.</p></div>@else
                <div class="bar-chart">
                    @foreach ($signupSeries as $pt)
                        <div class="bar-chart__col">
                            <span class="bar-chart__val">{{ $pt['value'] }}</span>
                            <div class="bar-chart__bar" style="height: {{ max(4, round($pt['value'] / $maxSignup * 130)) }}px"></div>
                            <span class="bar-chart__label">{{ $pt['label'] }}</span>
                        </div>
                    @endforeach
                </div>@endif
            </div>
        </div>
        <div class="card">
            <div class="card__header"><span class="card__title">Bookings (6 mo)</span></div>
            <div class="card__body">
                @if ($bookingSeries->isEmpty())<div class="empty-state"><p>No data.</p></div>@else
                <div class="bar-chart">
                    @foreach ($bookingSeries as $pt)
                        <div class="bar-chart__col">
                            <span class="bar-chart__val">{{ $pt['value'] }}</span>
                            <div class="bar-chart__bar" style="height: {{ max(4, round($pt['value'] / $maxBooking * 130)) }}px"></div>
                            <span class="bar-chart__label">{{ $pt['label'] }}</span>
                        </div>
                    @endforeach
                </div>@endif
            </div>
        </div>
    </div>

    <div class="grid" style="grid-template-columns: 1fr 1fr; gap: var(--sp-5); align-items: start;">
        <div class="card">
            <div class="card__header"><span class="card__title">Status Breakdown</span></div>
            <div class="card__body">
                @forelse ($statusBreakdown as $s)
                    @php $count = (int) ($s['count'] ?? 0); $pct = round($count / $statusTotal * 100); @endphp
                    <div style="margin-bottom: var(--sp-3)">
                        <div class="flex justify-between" style="margin-bottom:4px">
                            @include('admin.partials.status_badge', ['status' => $s['status'] ?? '—'])
                            <span class="mono" style="font-size:13px">{{ $count }} ({{ $pct }}%)</span>
                        </div>
                        <div style="height:6px;background:var(--surface-alt);border-radius:var(--r-pill);overflow:hidden">
                            <div style="height:100%;width:{{ $pct }}%;background:var(--primary)"></div>
                        </div>
                    </div>
                @empty
                    <div class="empty-state"><p>No bookings yet.</p></div>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card__header"><span class="card__title">Top Studios</span></div>
            <div class="table-wrap">
                <table class="data-table">
                    <thead><tr><th>Studio</th><th style="text-align:right">Bookings</th></tr></thead>
                    <tbody>
                        @forelse ($topStudios as $t)
                            <tr>
                                <td><strong>{{ $t['name'] ?? '—' }}</strong></td>
                                <td style="text-align:right" class="mono">{{ number_format($t['bookings'] ?? 0) }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="2"><div class="empty-state"><p>No data.</p></div></td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
@endsection
