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
               value="{{ $search }}" placeholder="Search by name, phone, or email">
        <select class="select" name="role" onchange="this.form.submit()">
            <option value="">All roles</option>
            @foreach ($roles as $r)
                <option value="{{ $r }}" @selected($role === $r)>{{ $r }}</option>
            @endforeach
        </select>
        <select class="select" name="activity" onchange="this.form.submit()">
            <option value="" @selected($activity === '')>All users</option>
            <option value="active" @selected($activity === 'active')>Active (30d)</option>
            <option value="inactive" @selected($activity === 'inactive')>Inactive / no recent activity</option>
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
                            $isAdminUser = strtoupper((string) ($u['role'] ?? '')) === 'ADMIN';
                            $isCurrentUser = (string) auth()->id() === (string) $u['id'];
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
                                {{ $registered ? $registered->format('d M Y') : '-' }}
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
                                    <span class="badge badge--neutral">No recent activity</span>
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
                                    <button type="button" class="btn btn--ghost btn--sm"
                                            onclick="openPasswordModal(@js([
                                                'id' => $u['id'],
                                                'name' => $u['fullName'] ?: 'Unnamed User',
                                                'email' => $u['email'],
                                            ]))">
                                        Password
                                    </button>
                                    <form method="POST" action="{{ route('admin.users.suspend', $u['id']) }}"
                                          onsubmit="return confirm(@js(($suspended ? 'Reactivate ' : 'Suspend ') . $u['email'] . '?'))">
                                        @csrf @method('PATCH')
                                        <input type="hidden" name="suspended" value="{{ $suspended ? 0 : 1 }}">
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ $suspended ? 'Reactivate' : 'Suspend' }}</button>
                                    </form>
                                    @if (! $isAdminUser && ! $isCurrentUser)
                                        <button type="button" class="btn btn--danger btn--sm"
                                                onclick="openDeleteUserModal(@js([
                                                    'id' => $u['id'],
                                                    'name' => $u['fullName'] ?: 'Unnamed User',
                                                    'email' => $u['email'],
                                                ]))">
                                            Soft delete
                                        </button>
                                    @endif
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
                <input type="hidden" name="form_context" value="create_user">
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

    <div class="modal-backdrop" id="passwordUserModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>Change Password</h2>
            <form method="POST" id="passwordUserForm">
                @csrf @method('PATCH')
                <input type="hidden" name="form_context" value="password_user">
                <input type="hidden" name="password_user_id" id="passwordUserId">
                <input type="hidden" name="password_user_name" id="passwordUserName">
                <input type="hidden" name="password_user_email" id="passwordUserEmail">
                <p class="field__help" id="passwordUserSummary" style="margin-bottom:var(--sp-4)"></p>
                <div class="field">
                    <label class="field__label">New password</label>
                    <input class="input" type="password" name="password" minlength="8" autocomplete="new-password" required>
                </div>
                <div class="field">
                    <label class="field__label">Confirm password</label>
                    <input class="input" type="password" name="password_confirmation" minlength="8" autocomplete="new-password" required>
                </div>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('passwordUserModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Update password</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-backdrop" id="deleteUserModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>Soft Delete User</h2>
            <form method="POST" id="deleteUserForm">
                @csrf @method('DELETE')
                <p class="field__help" id="deleteUserSummary" style="margin-bottom:var(--sp-4)"></p>
                <div class="flash flash--danger" style="margin-bottom:var(--sp-4)">
                    This will revoke active sessions and hide the account from user management. Existing records stay in the database.
                </div>
                <div class="field">
                    <label class="field__label">Type DELETE to confirm</label>
                    <input class="input mono" type="text" id="deleteUserConfirmInput" autocomplete="off" required>
                </div>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('deleteUserModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--danger" id="deleteUserSubmit" disabled>Soft delete</button>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
<script>
    function openPasswordModal(user) {
        const form = document.getElementById('passwordUserForm');
        form.action = `{{ url('/admin/users') }}/${user.id}/password`;
        form.reset();
        document.getElementById('passwordUserId').value = user.id || '';
        document.getElementById('passwordUserName').value = user.name || 'User';
        document.getElementById('passwordUserEmail').value = user.email || '';
        document.getElementById('passwordUserSummary').textContent =
            `Set a new password for ${user.name} (${user.email}). Existing app sessions will be signed out.`;
        document.getElementById('passwordUserModal').classList.add('is-open');
    }

    function openDeleteUserModal(user) {
        const form = document.getElementById('deleteUserForm');
        const input = document.getElementById('deleteUserConfirmInput');
        const submit = document.getElementById('deleteUserSubmit');
        form.action = `{{ url('/admin/users') }}/${user.id}`;
        document.getElementById('deleteUserSummary').textContent =
            `Soft delete ${user.name} (${user.email})?`;
        input.value = '';
        submit.disabled = true;
        document.getElementById('deleteUserModal').classList.add('is-open');
        setTimeout(() => input.focus(), 80);
    }

    document.getElementById('deleteUserConfirmInput')?.addEventListener('input', function () {
        document.getElementById('deleteUserSubmit').disabled = this.value !== 'DELETE';
    });

    @if ($errors->any())
        @if (old('form_context') === 'password_user')
            openPasswordModal(@js([
                'id' => old('password_user_id'),
                'name' => old('password_user_name', 'User'),
                'email' => old('password_user_email', ''),
            ]));
        @else
            document.getElementById('createUserModal').classList.add('is-open');
        @endif
    @endif
</script>
@endpush
