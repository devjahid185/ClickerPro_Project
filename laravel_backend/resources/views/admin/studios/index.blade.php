@extends('admin.layouts.app')

@section('title', 'Businesses')

@section('content')
    <div class="page-header">
        <div>
            <span class="eyebrow">Studio Accounts</span>
            <h1>Businesses</h1>
            <p class="page-header__sub">Review owner accounts and business profiles without exposing private studio operations.</p>
        </div>
        <span class="count-pill">{{ number_format($total) }} studios</span>
    </div>

    <form method="GET" action="{{ route('admin.studios') }}" class="toolbar">
        <input class="input toolbar__search" type="search" name="search" value="{{ $search }}" placeholder="Search business or owner">
        <button type="submit" class="btn btn--ghost">
            <span class="material-symbols-rounded" aria-hidden="true">filter_alt</span>
            Filter
        </button>
    </form>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Business / Owner</th>
                        <th>Email</th>
                        <th>Plan</th>
                        <th>Clients</th>
                        <th>Status</th>
                        <th style="text-align:right">Action</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($studios as $s)
                        @php $suspended = !is_null($s['deletedAt']); @endphp
                        <tr>
                            <td class="cell-link" onclick="location.href='{{ route('admin.users.show', $s['id']) }}'">
                                <strong>{{ $s['businessName'] ?: $s['fullName'] }}</strong>
                                <div class="cell-sub">{{ $s['fullName'] ?: 'Owner account' }}</div>
                            </td>
                            <td class="mono" style="font-size:13px">{{ $s['email'] }}</td>
                            <td><span class="badge {{ $s['plan'] === 'PRO' ? 'badge--warning' : 'badge--neutral' }}">{{ $s['plan'] }}</span></td>
                            <td class="mono">{{ number_format($s['totalClients'] ?? 0) }}</td>
                            <td>
                                @if ($suspended)
                                    <span class="badge badge--danger">Suspended</span>
                                @else
                                    <span class="badge badge--success">Active</span>
                                @endif
                            </td>
                            <td style="text-align:right">
                                <a class="btn btn--ghost btn--sm" href="{{ route('admin.users.show', $s['id']) }}">View</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6">
                                <div class="empty-state">
                                    <span class="material-symbols-rounded empty-state__icon" aria-hidden="true">storefront</span>
                                    <p>No businesses found.</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
