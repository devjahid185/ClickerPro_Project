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
                        @php
                            $audience = $b['targetRole'] ?? $b['target_role'] ?? 'ALL';
                            $audience = $audience ?: 'ALL';
                            $status = $b['status'] ?? 'ACTIVE';
                        @endphp
                        <tr>
                            <td><strong>{{ $b['title'] ?? '-' }}</strong><div class="cell-sub">{{ \Illuminate\Support\Str::limit($b['body'] ?? $b['content'] ?? '', 60) }}</div></td>
                            <td><span class="badge badge--neutral">{{ $audience }}</span></td>
                            <td>{{ $b['type'] ?? 'Announcement' }}</td>
                            <td>@include('admin.partials.status_badge', ['status' => $status])</td>
                            <td>
                                <div class="cell-actions">
                                    <button type="button" class="btn btn--ghost btn--sm" onclick="openEditBroadcast(@js([
                                        "id" => $b["id"],
                                        "title" => $b["title"] ?? "",
                                        "body" => $b["body"] ?? $b["content"] ?? "",
                                        "target_role" => $audience,
                                        "type" => $b["type"] ?? "Announcement",
                                        "priority" => $b["priority"] ?? "Normal",
                                        "image_url" => $b["image_url"] ?? $b["imageUrl"] ?? "",
                                        "link" => $b["link"] ?? "",
                                        "button_label" => $b["buttonLabel"] ?? "",
                                        "times_per_day" => $b["times_per_day"] ?? $b["timesPerDay"] ?? 1,
                                        "scheduled_at" => $b["scheduled_at"] ?? "",
                                        "is_active" => ($status === "ACTIVE"),
                                    ]))">Edit</button>
                                    <form method="POST" action="{{ route('admin.broadcasts.toggle', $b['id']) }}">
                                        @csrf @method('PATCH')
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ $status === 'ACTIVE' ? 'Archive' : 'Activate' }}</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.broadcasts.destroy', $b['id']) }}" onsubmit="return confirm('Delete this broadcast?')">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="btn btn--ghost btn--sm" style="color:var(--danger)">Delete</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="5"><div class="empty-state"><div class="empty-state__icon">*</div><p>No broadcasts yet.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div class="modal-backdrop" id="createBroadcastModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal modal--wide">
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
                        @foreach ($roles as $r)<option value="{{ $r }}" @selected(old('target_role', 'ALL')===$r)>{{ $r }}</option>@endforeach
                    </select>
                </div>
                <div class="field">
                    <label class="field__label">Type</label>
                    <input class="input" type="text" name="type" value="{{ old('type', 'Announcement') }}">
                </div>
                <div class="field">
                    <label class="field__label">Priority</label>
                    <select class="select" name="priority">
                        @foreach (['Normal', 'Important', 'Emergency'] as $priority)
                            <option value="{{ $priority }}" @selected(old('priority', 'Normal')===$priority)>{{ $priority }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="field">
                    <label class="field__label">Image URL</label>
                    <input class="input" type="text" name="image_url" value="{{ old('image_url') }}" placeholder="https://...">
                </div>
                <div class="field">
                    <label class="field__label">Link</label>
                    <input class="input" type="text" name="link" value="{{ old('link') }}" placeholder="https://...">
                </div>
                <div class="field">
                    <label class="field__label">Button label</label>
                    <input class="input" type="text" name="button_label" value="{{ old('button_label') }}" placeholder="Learn more">
                </div>
                <div class="field">
                    <label class="field__label">Times per day</label>
                    <input class="input" type="number" name="times_per_day" min="1" max="20" value="{{ old('times_per_day', 1) }}">
                </div>
                <div class="field">
                    <label class="field__label">Scheduled at</label>
                    <input class="input" type="datetime-local" name="scheduled_at" value="{{ old('scheduled_at') }}">
                </div>
                <label class="flex items-center gap-2" style="font-size:13px;color:var(--text-dim)">
                    <input type="hidden" name="is_active" value="0">
                    <input type="checkbox" name="is_active" value="1" @checked(old('is_active', '1'))> Active / send push now
                </label>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('createBroadcastModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Create broadcast</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-backdrop" id="editBroadcastModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal modal--wide">
            <h2>Edit Broadcast</h2>
            <form method="POST" id="editBroadcastForm">
                @csrf @method('PATCH')
                <div class="field">
                    <label class="field__label">Title</label>
                    <input class="input" type="text" name="title" id="editBroadcastTitle" required>
                </div>
                <div class="field">
                    <label class="field__label">Message</label>
                    <textarea class="textarea" name="body" id="editBroadcastBody" rows="4" required></textarea>
                </div>
                <div class="field">
                    <label class="field__label">Audience</label>
                    <select class="select" name="target_role" id="editBroadcastAudience">
                        @foreach ($roles as $r)<option value="{{ $r }}">{{ $r }}</option>@endforeach
                    </select>
                </div>
                <div class="field">
                    <label class="field__label">Type</label>
                    <input class="input" type="text" name="type" id="editBroadcastType">
                </div>
                <div class="field">
                    <label class="field__label">Priority</label>
                    <select class="select" name="priority" id="editBroadcastPriority">
                        <option value="Normal">Normal</option>
                        <option value="Important">Important</option>
                        <option value="Emergency">Emergency</option>
                    </select>
                </div>
                <div class="field">
                    <label class="field__label">Image URL</label>
                    <input class="input" type="text" name="image_url" id="editBroadcastImageUrl">
                </div>
                <div class="field">
                    <label class="field__label">Link</label>
                    <input class="input" type="text" name="link" id="editBroadcastLink">
                </div>
                <div class="field">
                    <label class="field__label">Button label</label>
                    <input class="input" type="text" name="button_label" id="editBroadcastButtonLabel">
                </div>
                <div class="field">
                    <label class="field__label">Times per day</label>
                    <input class="input" type="number" name="times_per_day" id="editBroadcastTimesPerDay" min="1" max="20">
                </div>
                <div class="field">
                    <label class="field__label">Scheduled at</label>
                    <input class="input" type="datetime-local" name="scheduled_at" id="editBroadcastScheduledAt">
                </div>
                <label class="flex items-center gap-2" style="font-size:13px;color:var(--text-dim)">
                    <input type="hidden" name="is_active" value="0">
                    <input type="checkbox" name="is_active" id="editBroadcastActive" value="1"> Active
                </label>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('editBroadcastModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Save changes</button>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
<script>
    function openEditBroadcast(broadcast) {
        const form = document.getElementById('editBroadcastForm');
        form.action = `{{ url('/admin/broadcasts') }}/${broadcast.id}`;
        document.getElementById('editBroadcastTitle').value = broadcast.title || '';
        document.getElementById('editBroadcastBody').value = broadcast.body || '';
        document.getElementById('editBroadcastAudience').value = broadcast.target_role || 'ALL';
        document.getElementById('editBroadcastType').value = broadcast.type || 'Announcement';
        document.getElementById('editBroadcastPriority').value = broadcast.priority || 'Normal';
        document.getElementById('editBroadcastImageUrl').value = broadcast.image_url || '';
        document.getElementById('editBroadcastLink').value = broadcast.link || '';
        document.getElementById('editBroadcastButtonLabel').value = broadcast.button_label || '';
        document.getElementById('editBroadcastTimesPerDay').value = broadcast.times_per_day || 1;
        document.getElementById('editBroadcastScheduledAt').value = toDateTimeLocalValue(broadcast.scheduled_at);
        document.getElementById('editBroadcastActive').checked = !!broadcast.is_active;
        document.getElementById('editBroadcastModal').classList.add('is-open');
    }

    function toDateTimeLocalValue(value) {
        if (!value) return '';
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return String(value).slice(0, 16);
        const pad = (n) => String(n).padStart(2, '0');
        return [
            date.getFullYear(),
            pad(date.getMonth() + 1),
            pad(date.getDate()),
        ].join('-') + 'T' + [pad(date.getHours()), pad(date.getMinutes())].join(':');
    }

    @if ($errors->any() || session('error'))
        document.getElementById('createBroadcastModal').classList.add('is-open');
    @endif
</script>
@endpush
