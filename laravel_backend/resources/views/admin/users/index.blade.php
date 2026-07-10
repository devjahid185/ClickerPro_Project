@extends('admin.layouts.app')

@section('title', 'Users')

@section('content')
    <div class="page-header">
        <div>
            <span class="eyebrow">Account Control</span>
            <h1>Users</h1>
            <p class="page-header__sub">Search accounts, adjust roles, manage plans, and suspend access when needed.</p>
        </div>
        <div class="page-header__actions">
            <span class="count-pill">{{ number_format($total) }} accounts</span>
            <button type="button" class="btn btn--primary" onclick="document.getElementById('createUserModal').classList.add('is-open')">
                <span class="material-symbols-rounded" aria-hidden="true">person_add</span>
                New User
            </button>
        </div>
    </div>

    <form method="GET" action="{{ route('admin.users') }}" class="toolbar">
        <input class="input toolbar__search" type="search" name="search"
               value="{{ $search }}" placeholder="Search name or email">
        <select class="select" name="role" onchange="this.form.submit()">
            <option value="">All roles</option>
            @foreach ($roles as $r)
                <option value="{{ $r }}" @selected($role === $r)>{{ $r }}</option>
            @endforeach
        </select>
        <select class="select" name="activity" onchange="this.form.submit()">
            <option value="" @selected($activity === '')>All users</option>
            <option value="active" @selected($activity === 'active')>Active (30d)</option>
            <option value="inactive" @selected($activity === 'inactive')>Inactive</option>
        </select>
        <button type="submit" class="btn btn--ghost">
            <span class="material-symbols-rounded" aria-hidden="true">filter_alt</span>
            Filter
        </button>
        <div class="toolbar__spacer"></div>
        <a class="btn btn--ghost" href="{{ route('admin.users.export') }}">
            <span class="material-symbols-rounded" aria-hidden="true">download</span>
            Export CSV
        </a>
    </form>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Contact</th>
                        <th>Role</th>
                        <th>Plan</th>
                        <th>Registered</th>
                        <th>Last active</th>
                        <th>Status</th>
                        <th style="text-align:right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($users as $u)
                        @php
                            $suspended = !is_null($u['deletedAt']);
                            $registered = !empty($u['createdAt']) ? \Illuminate\Support\Carbon::parse($u['createdAt']) : null;
                            $lastActive = !empty($u['lastActiveAt']) ? \Illuminate\Support\Carbon::parse($u['lastActiveAt']) : null;
                            $recentlyActive = $u['recentlyActive'] ?? false;
                        @endphp
                        <tr>
                            <td class="cell-link" onclick="location.href='{{ route('admin.users.show', $u['id']) }}'">
                                <strong>{{ $u['fullName'] ?: 'Unnamed User' }}</strong>
                                @if (!empty($u['businessName']))
                                    <div class="cell-sub">{{ $u['businessName'] }}</div>
                                @endif
                            </td>
                            <td class="mono" style="font-size:13px">
                                {{ $u['email'] }}
                                @if (!empty($u['phone']))
                                    <div class="cell-sub">{{ $u['phone'] }}</div>
                                @endif
                            </td>
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
                            <td style="font-size:13px" title="{{ $registered?->toDayDateTimeString() }}">
                                {{ $registered ? $registered->format('d M Y') : '—' }}
                            </td>
                            <td style="font-size:13px" title="{{ $lastActive?->toDayDateTimeString() ?? 'Never used the app' }}">
                                {{ $lastActive ? $lastActive->diffForHumans() : 'Never' }}
                            </td>
                            <td>
                                @if ($suspended)
                                    <span class="badge badge--danger">Suspended</span>
                                @elseif ($recentlyActive)
                                    <span class="badge badge--success">Active</span>
                                @else
                                    <span class="badge badge--neutral">Inactive</span>
                                @endif
                            </td>
                            <td>
                                <div class="cell-actions">
                                    <a class="btn btn--ghost btn--sm" href="{{ route('admin.users.show', $u['id']) }}">View</a>
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
                            <td colspan="8">
                                <div class="empty-state">
                                    <span class="material-symbols-rounded empty-state__icon" aria-hidden="true">groups</span>
                                    <p>No users found{{ $search || $role || $activity ? ' for this filter' : '' }}.</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

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
    @if ($errors->any())
        document.getElementById('createUserModal').classList.add('is-open');
    @endif
</script>
@endpush
