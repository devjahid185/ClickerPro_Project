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
               value="{{ $search }}" placeholder="Search by client or venue…">
        @if ($status)
            <input type="hidden" name="status" value="{{ $status }}">
        @endif
        <button type="submit" class="btn btn--ghost">
            <span class="material-symbols-rounded" aria-hidden="true">search</span>
            Search
        </button>
    </form>

    {{-- Design's filter chip row — active chip filled, others outlined. --}}
    <div class="chip-row">
        <a class="chip {{ $status === '' ? 'is-active' : '' }}"
           href="{{ route('admin.bookings', array_filter(['search' => $search])) }}">All</a>
        @foreach ($statuses as $s)
            <a class="chip {{ $status === $s ? 'is-active' : '' }}"
               href="{{ route('admin.bookings', array_filter(['search' => $search, 'status' => $s])) }}">
                {{ ucwords(strtolower(str_replace('_', ' ', $s))) }}
            </a>
        @endforeach
    </div>

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
