@extends('admin.layouts.app')

@section('title', $user['fullName'] ?? 'User')

@section('content')
    @php
        $statusMap = [
            'PENDING' => 'badge--warning', 'CONFIRMED' => 'badge--info',
            'IN_PROGRESS' => 'badge--warning', 'SHOT_COMPLETE' => 'badge--info',
            'DELIVERED' => 'badge--success', 'COMPLETED' => 'badge--success',
            'SUCCESSFUL' => 'badge--success', 'CANCELLED' => 'badge--danger',
        ];
        $paymentsTotal = ($stats['paymentsTotal'] ?? 0);
    @endphp

    <div class="page-header">
        <div>
            <a class="btn btn--ghost btn--sm mb-4" href="{{ route('admin.users') }}">← Back to users</a>
            <h1>{{ $user['fullName'] ?: '—' }}</h1>
            <p class="page-header__sub">
                {{ $user['email'] ?? '' }}
                @if (!empty($user['businessName'])) · {{ $user['businessName'] }} @endif
            </p>
        </div>
        <div class="flex items-center gap-2">
            <span class="badge {{ ($user['plan'] ?? 'FREE') === 'PRO' ? 'badge--warning' : 'badge--neutral' }}">{{ $user['plan'] ?? 'FREE' }}</span>
            <span class="badge badge--info">{{ $user['role'] ?? 'OWNER' }}</span>
        </div>
    </div>

    {{-- Stat cards --}}
    <div class="stat-grid mb-6">
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--info-soft);color:var(--info)">▦</div>
            <div class="stat-card__value">{{ number_format($stats['bookings'] ?? 0) }}</div>
            <div class="stat-card__label">Bookings</div>
        </div>
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--primary-soft);color:var(--primary)">◌</div>
            <div class="stat-card__value">{{ number_format($stats['clients'] ?? 0) }}</div>
            <div class="stat-card__label">Clients</div>
        </div>
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--success-soft);color:var(--success)">◇</div>
            <div class="stat-card__value">{{ number_format($stats['paymentsCount'] ?? 0) }}</div>
            <div class="stat-card__label">Payments</div>
        </div>
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--success-soft);color:var(--success)">◎</div>
            <div class="stat-card__value">৳{{ number_format($paymentsTotal) }}</div>
            <div class="stat-card__label">Total Collected</div>
        </div>
    </div>

    <div class="grid" style="grid-template-columns: 320px 1fr; gap: var(--sp-5); align-items: start;">
        {{-- Profile + admin actions --}}
        <div class="card">
            <div class="card__header"><span class="card__title">Account</span></div>
            <div class="card__body">
                @php
                    $fields = [
                        'Email' => $user['email'] ?? '—',
                        'Phone' => $user['phone'] ?? '—',
                        'WhatsApp' => $user['whatsapp'] ?? '—',
                        'Business' => $user['businessName'] ?? '—',
                        'Address' => $user['businessAddress'] ?? '—',
                        'Joined' => !empty($user['createdAt']) ? \Illuminate\Support\Carbon::parse($user['createdAt'])->format('d M Y') : '—',
                    ];
                @endphp
                @foreach ($fields as $label => $value)
                    <div class="flex justify-between" style="padding:var(--sp-2) 0;border-bottom:1px solid var(--hairline)">
                        <span class="text-muted" style="font-size:13px">{{ $label }}</span>
                        <span style="font-size:13px;text-align:right;max-width:60%">{{ $value }}</span>
                    </div>
                @endforeach

                <form method="POST" action="{{ route('admin.users.role', $user['id']) }}" class="mt-4">
                    @csrf @method('PATCH')
                    <label class="field__label">Change role</label>
                    <div class="flex gap-2">
                        <select class="select" name="role">
                            @foreach ($roles as $r)
                                <option value="{{ $r }}" @selected(strtoupper($user['role'] ?? '') === $r)>{{ $r }}</option>
                            @endforeach
                        </select>
                        <button type="submit" class="btn btn--primary">Save</button>
                    </div>
                </form>
            </div>
        </div>

        {{-- Recent bookings --}}
        <div class="card">
            <div class="card__header"><span class="card__title">Recent Bookings</span></div>
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr><th>Title</th><th>Client</th><th>Date</th><th>Venue</th><th>Status</th></tr>
                    </thead>
                    <tbody>
                        @forelse ($bookings as $b)
                            <tr>
                                <td><strong>{{ $b['title'] ?: '—' }}</strong><div class="cell-sub">{{ $b['type'] ?? '' }}</div></td>
                                <td>{{ $b['client']['name'] ?? '—' }}</td>
                                <td class="mono" style="font-size:13px">{{ $b['date'] ?? '—' }}</td>
                                <td>{{ $b['venue'] ?: '—' }}</td>
                                <td><span class="badge {{ $statusMap[$b['status']] ?? 'badge--neutral' }}">{{ $b['status'] }}</span></td>
                            </tr>
                        @empty
                            <tr><td colspan="5"><div class="empty-state"><div class="empty-state__icon">▦</div><p>No bookings yet.</p></div></td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
@endsection
