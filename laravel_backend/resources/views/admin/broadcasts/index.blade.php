@extends('admin.layouts.app')

@section('title', 'Notifications')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3"><h1>Notifications</h1><span class="count-pill">{{ count($broadcasts) }} broadcasts</span></div>
        <button type="button" class="btn btn--primary" onclick="document.getElementById('createBroadcastModal').classList.add('is-open')">+ New Broadcast</button>
    </div>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Title</th><th>Audience</th><th>Type</th><th>Status</th><th style="text-align:right">Actions</th></tr></thead>
                <tbody>
                    @forelse ($broadcasts as $b)
                        <tr>
                            <td><strong>{{ $b['title'] ?? '—' }}</strong><div class="cell-sub">{{ \Illuminate\Support\Str::limit($b['body'] ?? $b['content'] ?? '', 60) }}</div></td>
                            <td><span class="badge badge--neutral">{{ $b['targetRole'] ?? $b['target_role'] ?? 'ALL' }}</span></td>
                            <td>{{ $b['type'] ?? 'Announcement' }}</td>
                            <td>@include('admin.partials.status_badge', ['status' => $b['status'] ?? 'ACTIVE'])</td>
                            <td>
                                <div class="cell-actions">
                                    <form method="POST" action="{{ route('admin.broadcasts.toggle', $b['id']) }}">
                                        @csrf @method('PATCH')
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ ($b['status'] ?? 'ACTIVE') === 'ACTIVE' ? 'Archive' : 'Activate' }}</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.broadcasts.destroy', $b['id']) }}" onsubmit="return confirm('Delete this broadcast?')">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="btn btn--ghost btn--sm" style="color:var(--danger)">Delete</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="5"><div class="empty-state"><div class="empty-state__icon">◉</div><p>No broadcasts yet.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div class="modal-backdrop" id="createBroadcastModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>New Broadcast</h2>
            <form method="POST" action="{{ route('admin.broadcasts.store') }}">
                @csrf
                <div class="field">
                    <label class="field__label">Title</label>
                    <input class="input" type="text" name="title" value="{{ old('title') }}" required>
                </div>
                <div class="field">
                    <label class="field__label">Message</label>
                    <textarea class="textarea" name="body" rows="4" required>{{ old('body') }}</textarea>
                </div>
                <div class="field">
                    <label class="field__label">Audience</label>
                    <select class="select" name="target_role">
                        @foreach ($roles as $r)<option value="{{ $r }}" @selected(old('target_role')===$r)>{{ $r }}</option>@endforeach
                    </select>
                </div>
                <label class="flex items-center gap-2" style="font-size:13px;color:var(--text-dim)">
                    <input type="checkbox" name="is_active" value="1" checked> Send immediately (push to all devices)
                </label>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('createBroadcastModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Send</button>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
<script>
    @if ($errors->any() || session('error'))
        document.getElementById('createBroadcastModal').classList.add('is-open');
    @endif
</script>
@endpush
