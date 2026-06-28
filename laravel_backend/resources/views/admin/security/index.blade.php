@extends('admin.layouts.app')

@section('title', 'Security')

@section('content')
    <div class="page-header"><div><h1>Security</h1><p class="page-header__sub">Login activity and IP access control.</p></div></div>

    <div class="grid mb-6" style="grid-template-columns: 1fr 1fr; gap: var(--sp-5); align-items: start;">
        {{-- Blocked IPs --}}
        <div class="card">
            <div class="card__header"><span class="card__title">Blocked IPs</span><span class="count-pill">{{ count($blocked) }}</span></div>
            <div class="card__body">
                <form method="POST" action="{{ route('admin.security.block') }}" class="flex gap-2 mb-4">
                    @csrf
                    <input class="input mono" type="text" name="ip" placeholder="e.g. 203.0.113.5" required>
                    <button type="submit" class="btn btn--primary">Block</button>
                </form>
                @forelse ($blocked as $b)
                    <div class="flex justify-between items-center" style="padding:var(--sp-2) 0;border-bottom:1px solid var(--hairline)">
                        <div>
                            <strong class="mono" style="font-size:13px">{{ $b['ip'] }}</strong>
                            @if (!empty($b['reason']))<div class="cell-sub">{{ $b['reason'] }}</div>@endif
                        </div>
                        <form method="POST" action="{{ route('admin.security.unblock', $b['ip']) }}">
                            @csrf @method('DELETE')
                            <button type="submit" class="btn btn--ghost btn--sm">Unblock</button>
                        </form>
                    </div>
                @empty
                    <div class="empty-state"><p>No blocked IPs.</p></div>
                @endforelse
            </div>
        </div>

        {{-- Login activity --}}
        <div class="card">
            <div class="card__header"><span class="card__title">Login Activity</span></div>
            <div class="table-wrap">
                <table class="data-table">
                    <thead><tr><th>Email</th><th>IP</th><th>Result</th><th>When</th></tr></thead>
                    <tbody>
                        @forelse ($activity as $a)
                            <tr>
                                <td style="font-size:13px">{{ $a['email'] ?: '—' }}</td>
                                <td class="mono" style="font-size:12px">{{ $a['ip'] ?: '—' }}</td>
                                <td>
                                    @if ($a['success'] ?? false)<span class="badge badge--success">OK</span>
                                    @else<span class="badge badge--danger">Failed</span>@endif
                                </td>
                                <td class="mono" style="font-size:12px">{{ !empty($a['createdAt']) ? \Illuminate\Support\Carbon::parse($a['createdAt'])->format('d M H:i') : '—' }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="4"><div class="empty-state"><p>No login activity.</p></div></td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
@endsection
