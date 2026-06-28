@extends('admin.layouts.app')

@section('title', 'Finance')

@section('content')
    @php
        // Normalise the bookings series to {label, value} with a max for scaling.
        $series = collect($bookingsSeries)->map(fn ($b) => [
            'label' => isset($b['month']) ? \Illuminate\Support\Str::of($b['month'])->afterLast('-') : '',
            'value' => (int) ($b['count'] ?? 0),
        ])->take(-6)->values();
        $maxVal = max(1, $series->max('value') ?? 1);
    @endphp

    <div class="page-header">
        <div><h1>Finance</h1><p class="page-header__sub">Revenue and collection across all studios.</p></div>
        <a class="btn btn--ghost" href="{{ route('admin.finance.export') }}">⬇ Export Payments CSV</a>
    </div>

    <div class="stat-grid mb-6">
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--success-soft);color:var(--success)">◎</div>
            <div class="stat-card__value">৳{{ number_format($totalAmount) }}</div>
            <div class="stat-card__label">Total Revenue</div>
        </div>
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--info-soft);color:var(--info)">◇</div>
            <div class="stat-card__value">{{ number_format($total) }}</div>
            <div class="stat-card__label">Payment Records</div>
        </div>
    </div>

    <div class="grid mb-6" style="grid-template-columns: 1.4fr 1fr; gap: var(--sp-5); align-items: start;">
        <div class="card">
            <div class="card__header"><span class="card__title">Bookings created (6 mo)</span></div>
            <div class="card__body">
                @if ($series->isEmpty())
                    <div class="empty-state"><p>No data yet.</p></div>
                @else
                    <div class="bar-chart">
                        @foreach ($series as $pt)
                            <div class="bar-chart__col">
                                <span class="bar-chart__val">{{ $pt['value'] }}</span>
                                <div class="bar-chart__bar" style="height: {{ max(4, round($pt['value'] / $maxVal * 130)) }}px"></div>
                                <span class="bar-chart__label">{{ $pt['label'] }}</span>
                            </div>
                        @endforeach
                    </div>
                @endif
            </div>
        </div>

        <div class="card">
            <div class="card__header"><span class="card__title">By Method</span></div>
            <div class="card__body">
                @foreach ($byMethod as $name => $amount)
                    <div class="method-row">
                        <span class="method-row__name">{{ $name }}</span>
                        <span class="method-row__amount">৳{{ number_format($amount) }}</span>
                    </div>
                @endforeach
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card__header"><span class="card__title">Recent Payments</span></div>
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Amount</th><th>Method</th><th>Studio</th><th>Booking</th><th>Status</th></tr></thead>
                <tbody>
                    @forelse ($payments as $p)
                        <tr>
                            <td><strong style="color:var(--success)">৳{{ number_format($p['amount'] ?? 0) }}</strong></td>
                            <td class="mono" style="font-size:13px">{{ $p['method'] ?: '—' }}</td>
                            <td>{{ $p['event']['owner']['businessName'] ?? $p['event']['owner']['fullName'] ?? '—' }}</td>
                            <td>{{ $p['event']['title'] ?? '—' }}</td>
                            <td>@include('admin.partials.status_badge', ['status' => $p['status'] ?? $p['kind']])</td>
                        </tr>
                    @empty
                        <tr><td colspan="5"><div class="empty-state"><p>No payments yet.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
