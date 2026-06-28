@extends('admin.layouts.app')

@section('title', 'Audit Log')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3"><h1>Audit Log</h1><span class="count-pill">{{ number_format($total) }} entries</span></div>
    </div>

    <form method="GET" action="{{ route('admin.audit') }}" class="toolbar">
        <input class="input" type="text" name="entity" value="{{ $entity }}" placeholder="Entity (e.g. Event)">
        <input class="input" type="text" name="action" value="{{ $action }}" placeholder="Action (e.g. created)">
        <button type="submit" class="btn btn--ghost">Filter</button>
    </form>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Actor</th><th>Action</th><th>Entity</th><th>Entity ID</th><th>When</th></tr></thead>
                <tbody>
                    @forelse ($logs as $l)
                        <tr>
                            <td><strong>{{ $l['actorName'] ?? 'System' }}</strong></td>
                            <td><span class="badge badge--info">{{ $l['action'] ?? '—' }}</span></td>
                            <td>{{ $l['entityType'] ?? '—' }}</td>
                            <td class="mono" style="font-size:12px">{{ $l['entityId'] ?? '—' }}</td>
                            <td class="mono" style="font-size:12px">{{ !empty($l['createdAt']) ? \Illuminate\Support\Carbon::parse($l['createdAt'])->format('d M Y, H:i') : '—' }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="5"><div class="empty-state"><div class="empty-state__icon">≡</div><p>No audit entries.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
