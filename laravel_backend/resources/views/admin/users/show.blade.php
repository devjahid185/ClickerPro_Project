@extends('admin.layouts.app')

@section('title', $user['fullName'] ?? 'User')

@section('content')
    {{--
        PRIVACY: this page must NOT show the user's bookings, payments, income,
        or expenses. The booking/payment stat cards and the "Recent Bookings"
        table were intentionally removed — only the profile, a non-financial
        client count, and admin actions remain.
    --}}

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

    {{-- Stat cards — non-financial only --}}
    <div class="stat-grid mb-6">
        <div class="stat-card">
            <div class="stat-card__icon" style="background:var(--primary-soft);color:var(--primary)">◌</div>
            <div class="stat-card__value">{{ number_format($stats['clients'] ?? 0) }}</div>
            <div class="stat-card__label">Clients</div>
        </div>
    </div>

    {{-- Profile + admin actions --}}
    <div class="card" style="max-width: 480px;">
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
@endsection
