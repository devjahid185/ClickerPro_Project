@extends('admin.layouts.app')

@section('title', 'Support & FAQ')

@section('content')
    <div class="page-header"><div><h1>Support &amp; FAQ</h1><p class="page-header__sub">Respond to tickets and manage help content.</p></div></div>

    {{-- Support tickets --}}
    <div class="card mb-6">
        <div class="card__header"><span class="card__title">Tickets</span><span class="count-pill">{{ $tickets->count() }}</span></div>
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Subject</th><th>User</th><th>Status</th><th>Submitted</th><th style="text-align:right">Action</th></tr></thead>
                <tbody>
                    @forelse ($tickets as $t)
                        <tr>
                            <td><strong>{{ $t->subject ?: '—' }}</strong><div class="cell-sub">{{ \Illuminate\Support\Str::limit($t->body, 70) }}</div></td>
                            <td>{{ $t->user->name ?? $t->user->email ?? '—' }}</td>
                            <td>@include('admin.partials.status_badge', ['status' => $t->status ?: 'OPEN'])</td>
                            <td class="mono" style="font-size:13px">{{ $t->created_at?->format('d M Y') }}</td>
                            <td style="text-align:right">
                                <button type="button" class="btn btn--ghost btn--sm"
                                    onclick="document.getElementById('reply-{{ $t->id }}').classList.add('is-open')">
                                    {{ $t->admin_reply ? 'View' : 'Reply' }}
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="5"><div class="empty-state"><div class="empty-state__icon">◌</div><p>No tickets.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Reply modals (one per ticket) --}}
    @foreach ($tickets as $t)
        <div class="modal-backdrop" id="reply-{{ $t->id }}" onclick="if(event.target===this)this.classList.remove('is-open')">
            <div class="modal">
                <h2>{{ $t->subject ?: 'Ticket' }}</h2>
                <p class="text-dim mb-4" style="font-size:13px">{{ $t->body }}</p>
                <form method="POST" action="{{ route('admin.support.reply', $t->id) }}">
                    @csrf @method('PATCH')
                    <div class="field">
                        <label class="field__label">Reply</label>
                        <textarea class="textarea" name="admin_reply" rows="4" required>{{ $t->admin_reply }}</textarea>
                    </div>
                    <div class="field">
                        <label class="field__label">Status</label>
                        <select class="select" name="status">
                            <option value="CLOSED" @selected($t->status === 'CLOSED')>CLOSED</option>
                            <option value="PENDING" @selected($t->status === 'PENDING')>PENDING</option>
                            <option value="OPEN" @selected($t->status === 'OPEN')>OPEN</option>
                        </select>
                    </div>
                    <div class="modal__actions">
                        <button type="button" class="btn btn--ghost" onclick="document.getElementById('reply-{{ $t->id }}').classList.remove('is-open')">Cancel</button>
                        <button type="submit" class="btn btn--primary">Send Reply</button>
                    </div>
                </form>
            </div>
        </div>
    @endforeach

    {{-- FAQ management --}}
    <div class="card">
        <div class="card__header">
            <span class="card__title">FAQ</span>
            <button type="button" class="btn btn--primary btn--sm" onclick="document.getElementById('createFaqModal').classList.add('is-open')">+ Add FAQ</button>
        </div>
        <div class="card__body">
            @forelse ($faqs as $f)
                <div style="padding:var(--sp-3) 0;border-bottom:1px solid var(--hairline)">
                    <div class="flex justify-between items-center">
                        <strong>{{ $f->question }}</strong>
                        <form method="POST" action="{{ route('admin.support.faq.destroy', $f->id) }}" onsubmit="return confirm('Delete this FAQ?')">
                            @csrf @method('DELETE')
                            <button type="submit" class="btn btn--ghost btn--sm" style="color:var(--danger)">Delete</button>
                        </form>
                    </div>
                    <p class="text-dim" style="font-size:13px;margin-top:4px">{{ $f->answer }}</p>
                </div>
            @empty
                <div class="empty-state"><p>No FAQ entries.</p></div>
            @endforelse
        </div>
    </div>

    <div class="modal-backdrop" id="createFaqModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>Add FAQ</h2>
            <form method="POST" action="{{ route('admin.support.faq.store') }}">
                @csrf
                <div class="field"><label class="field__label">Question</label><input class="input" type="text" name="question" required></div>
                <div class="field"><label class="field__label">Answer</label><textarea class="textarea" name="answer" rows="3" required></textarea></div>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('createFaqModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Add</button>
                </div>
            </form>
        </div>
    </div>
@endsection
