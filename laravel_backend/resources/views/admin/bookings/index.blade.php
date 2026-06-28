@extends('admin.layouts.app')

@section('title', 'Bookings')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3">
            <h1>Bookings</h1>
            <span class="count-pill">{{ number_format($total) }} total</span>
        </div>
    </div>

    <form method="GET" action="{{ route('admin.bookings') }}" class="toolbar">
        <input class="input toolbar__search" type="search" name="search"
               value="{{ $search }}" placeholder="Search title or venue…">
        <select class="select" name="status" onchange="this.form.submit()">
            <option value="">All statuses</option>
            @foreach ($statuses as $s)
                <option value="{{ $s }}" @selected($status === $s)>{{ $s }}</option>
            @endforeach
        </select>
        <button type="submit" class="btn btn--ghost">Filter</button>
    </form>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Studio / Owner</th>
                        <th>Client</th>
                        <th>Date</th>
                        <th>Venue</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($bookings as $b)
                        <tr>
                            <td><strong>{{ $b['title'] ?: '—' }}</strong><div class="cell-sub">{{ $b['type'] ?? '' }}</div></td>
                            <td>
                                @if (!empty($b['owner']))
                                    {{ $b['owner']['businessName'] ?: $b['owner']['fullName'] }}
                                    <div class="cell-sub">{{ $b['owner']['fullName'] }}</div>
                                @else — @endif
                            </td>
                            <td>{{ $b['client']['name'] ?? '—' }}</td>
                            <td class="mono" style="font-size:13px">{{ $b['date'] ?? '—' }}</td>
                            <td>{{ $b['venue'] ?: '—' }}</td>
                            <td>@include('admin.partials.status_badge', ['status' => $b['status']])</td>
                        </tr>
                    @empty
                        <tr><td colspan="6"><div class="empty-state"><div class="empty-state__icon">▦</div><p>No bookings found.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
