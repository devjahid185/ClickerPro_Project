@extends('admin.layouts.app')

@section('title', 'Payments')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3">
            <h1>Payments</h1>
            <span class="count-pill">{{ number_format($total) }} payments</span>
        </div>
    </div>

    <div class="stat-grid mb-6">
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--success-soft);color:var(--success)">◎</div>
            <div class="stat-card__value">৳{{ number_format($totalAmount) }}</div>
            <div class="stat-card__label">Total Collected (all studios)</div>
        </div>
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--info-soft);color:var(--info)">◇</div>
            <div class="stat-card__value">{{ number_format($total) }}</div>
            <div class="stat-card__label">Payment Records</div>
        </div>
    </div>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Amount</th>
                        <th>Kind</th>
                        <th>Method</th>
                        <th>Studio / Owner</th>
                        <th>Booking</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($payments as $p)
                        <tr>
                            <td><strong style="color:var(--success)">৳{{ number_format($p['amount'] ?? 0) }}</strong></td>
                            <td>@include('admin.partials.status_badge', ['status' => $p['status'] ?? $p['kind']])</td>
                            <td class="mono" style="font-size:13px">{{ $p['method'] ?: '—' }}</td>
                            <td>
                                @if (!empty($p['event']['owner']))
                                    {{ $p['event']['owner']['businessName'] ?: $p['event']['owner']['fullName'] }}
                                @else — @endif
                            </td>
                            <td>{{ $p['event']['title'] ?? '—' }}</td>
                            <td class="mono" style="font-size:13px">{{ !empty($p['date']) ? \Illuminate\Support\Carbon::parse($p['date'])->format('d M Y') : '—' }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="6"><div class="empty-state"><div class="empty-state__icon">◇</div><p>No payments found.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
