{{-- Reusable status badge. Usage: @include('admin.partials.status_badge', ['status' => $s]) --}}
@php
    $statusMap = [
        'PENDING' => 'badge--warning', 'CONFIRMED' => 'badge--info',
        'IN_PROGRESS' => 'badge--warning', 'SHOT_COMPLETE' => 'badge--info',
        'DELIVERED' => 'badge--success', 'COMPLETED' => 'badge--success',
        'SUCCESSFUL' => 'badge--success', 'CANCELLED' => 'badge--danger',
        'ACTIVE' => 'badge--success', 'ARCHIVED' => 'badge--neutral',
        'OPEN' => 'badge--warning', 'IN_PROGRESS_TICKET' => 'badge--info',
        'RESOLVED' => 'badge--success', 'CLOSED' => 'badge--neutral',
    ];
    $cls = $statusMap[$status ?? ''] ?? 'badge--neutral';
@endphp
<span class="badge {{ $cls }}">{{ $status ?: '—' }}</span>
