@extends('admin.layouts.app')

@section('title', 'Users')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3">
            <h1>Users</h1>
            <span class="count-pill">{{ number_format($total) }} accounts</span>
        </div>
    </div>

    {{-- Search + role filter + actions. GET form keeps state shareable/bookmarkable. --}}
    <form method="GET" action="{{ route('admin.users') }}" class="toolbar">
        <input class="input toolbar__search" type="search" name="search"
               value="{{ $search }}" placeholder="Search name or email…">
        <select class="select" name="role" onchange="this.form.submit()">
            <option value="">All roles</option>
            @foreach ($roles as $r)
                <option value="{{ $r }}" @selected($role === $r)>{{ $r }}</option>
            @endforeach
        </select>
        <button type="submit" class="btn btn--ghost">Filter</button>
        <div class="toolbar__spacer"></div>
        <a class="btn btn--ghost" href="{{ route('admin.users.export') }}">⬇ Export CSV</a>
        <button type="button" class="btn btn--primary" onclick="document.getElementById('createUserModal').classList.add('is-open')">+ New User</button>
    </form>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Plan</th>
                        <th>Status</th>
                        <th style="text-align:right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($users as $u)
                        @php $suspended = !is_null($u['deletedAt']); @endphp
                        <tr>
                            <td class="cell-link" onclick="location.href='{{ route('admin.users.show', $u['id']) }}'">
                                <strong>{{ $u['fullName'] ?: '—' }}</strong>
                                @if (!empty($u['businessName']))
                                    <div class="cell-sub">{{ $u['businessName'] }}</div>
                                @endif
                            </td>
                            <td class="mono" style="font-size:13px">{{ $u['email'] }}</td>
                            <td>
                                <form method="POST" action="{{ route('admin.users.role', $u['id']) }}">
                                    @csrf @method('PATCH')
                                    <select class="select select--inline" name="role" onchange="this.form.submit()">
                                        @foreach ($roles as $r)
                                            <option value="{{ $r }}" @selected(strtoupper($u['role']) === $r)>{{ $r }}</option>
                                        @endforeach
                                    </select>
                                </form>
                            </td>
                            <td>
                                <span class="badge {{ $u['plan'] === 'PRO' ? 'badge--warning' : 'badge--neutral' }}">{{ $u['plan'] }}</span>
                            </td>
                            <td>
                                @if ($suspended)
                                    <span class="badge badge--danger">Suspended</span>
                                @else
                                    <span class="badge badge--success">Active</span>
                                @endif
                            </td>
                            <td>
                                <div class="cell-actions">
                                    <form method="POST" action="{{ route('admin.users.plan', $u['id']) }}">
                                        @csrf @method('PATCH')
                                        <input type="hidden" name="plan" value="{{ $u['plan'] === 'PRO' ? 'FREE' : 'PRO' }}">
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ $u['plan'] === 'PRO' ? 'Downgrade' : 'Make PRO' }}</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.users.suspend', $u['id']) }}"
                                          onsubmit="return confirm('{{ $suspended ? 'Reactivate' : 'Suspend' }} {{ $u['email'] }}?')">
                                        @csrf @method('PATCH')
                                        <input type="hidden" name="suspended" value="{{ $suspended ? 0 : 1 }}">
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ $suspended ? 'Reactivate' : 'Suspend' }}</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6">
                                <div class="empty-state">
                                    <div class="empty-state__icon">⊙</div>
                                    <p>No users found{{ $search || $role ? ' for this filter' : '' }}.</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Create user modal --}}
    <div class="modal-backdrop" id="createUserModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>New User</h2>
            <form method="POST" action="{{ route('admin.users.store') }}">
                @csrf
                <div class="field">
                    <label class="field__label">Full name</label>
                    <input class="input" type="text" name="name" value="{{ old('name') }}" required>
                </div>
                <div class="field">
                    <label class="field__label">Email</label>
                    <input class="input" type="email" name="email" value="{{ old('email') }}" required>
                </div>
                <div class="field">
                    <label class="field__label">Password</label>
                    <input class="input" type="text" name="password" minlength="8" required>
                </div>
                <div class="field">
                    <label class="field__label">Role</label>
                    <select class="select" name="role">
                        @foreach ($roles as $r)
                            <option value="{{ $r }}" @selected(old('role', 'OWNER') === $r)>{{ $r }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('createUserModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Create</button>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
<script>
    // Re-open the create modal if validation bounced back with errors.
    @if ($errors->any())
        document.getElementById('createUserModal').classList.add('is-open');
    @endif
</script>
@endpush
