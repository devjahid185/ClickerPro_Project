@extends('admin.layouts.app')

@section('title', $user['fullName'] ?? 'User')

@section('content')
    @php
        $name = $user['fullName'] ?: 'Unnamed User';
        $plan = $user['plan'] ?? 'FREE';
        $role = $user['role'] ?? 'OWNER';
        $isAdminUser = strtoupper((string) $role) === 'ADMIN';
        $isCurrentUser = (string) auth()->id() === (string) ($user['id'] ?? '');
        $fields = [
            'Email' => $user['email'] ?? '-',
            'Phone' => $user['phone'] ?? '-',
            'WhatsApp' => $user['whatsapp'] ?? '-',
            'Business' => $user['businessName'] ?? '-',
            'Address' => $user['businessAddress'] ?? '-',
            'Joined' => !empty($user['createdAt']) ? \Illuminate\Support\Carbon::parse($user['createdAt'])->format('d M Y') : '-',
        ];
    @endphp

    <div class="page-header">
        <div>
            <a class="btn btn--ghost btn--sm mb-4" href="{{ route('admin.users') }}">
                <span class="material-symbols-rounded" aria-hidden="true">arrow_back</span>
                Back to users
            </a>
            <span class="eyebrow">Account Detail</span>
            <h1>{{ $name }}</h1>
            <p class="page-header__sub">
                {{ $user['email'] ?? '' }}
                @if (!empty($user['businessName'])) | {{ $user['businessName'] }} @endif
            </p>
        </div>
        <div class="page-header__actions">
            <span class="badge {{ $plan === 'PRO' ? 'badge--warning' : 'badge--neutral' }}">{{ $plan }}</span>
            <span class="badge badge--info">{{ $role }}</span>
        </div>
    </div>

    <div class="dashboard-grid">
        <section class="card">
            <div class="card__header">
                <div>
                    <span class="card__title">Profile</span>
                    <p class="card__meta">Non-financial account information.</p>
                </div>
            </div>
            <div class="card__body">
                @foreach ($fields as $label => $value)
                    <div class="kv-row">
                        <span class="kv-row__key">{{ $label }}</span>
                        <span style="text-align:right;max-width:60%">{{ $value }}</span>
                    </div>
                @endforeach
            </div>
        </section>

        <section class="card">
            <div class="card__header">
                <div>
                    <span class="card__title">Admin Actions</span>
                    <p class="card__meta">Role changes and privacy-safe stats.</p>
                </div>
            </div>
            <div class="card__body">
                <div class="stat-card stat-card--teal mb-4">
                    <div class="stat-card__top">
                        <span class="material-symbols-rounded stat-card__icon" aria-hidden="true">contacts</span>
                        <span class="stat-card__label">Clients</span>
                    </div>
                    <div class="stat-card__value">{{ number_format($stats['clients'] ?? 0) }}</div>
                    <div class="stat-card__meta">Client count only; no bookings or finances.</div>
                </div>

                <form method="POST" action="{{ route('admin.users.role', $user['id']) }}">
                    @csrf @method('PATCH')
                    <div class="field">
                        <label class="field__label">Change role</label>
                        <div class="flex gap-2">
                            <select class="select" name="role">
                                @foreach ($roles as $r)
                                    <option value="{{ $r }}" @selected(strtoupper($role) === $r)>{{ $r }}</option>
                                @endforeach
                            </select>
                            <button type="submit" class="btn btn--primary">Save</button>
                        </div>
                    </div>
                </form>

                <form method="POST" action="{{ route('admin.users.password', $user['id']) }}" class="mt-4">
                    @csrf @method('PATCH')
                    <input type="hidden" name="form_context" value="detail_password">
                    <div class="field">
                        <label class="field__label">Change password</label>
                        <input class="input" type="password" name="password" minlength="8" autocomplete="new-password" placeholder="New password" required>
                    </div>
                    <div class="field">
                        <input class="input" type="password" name="password_confirmation" minlength="8" autocomplete="new-password" placeholder="Confirm password" required>
                    </div>
                    <button type="submit" class="btn btn--primary">Update password</button>
                </form>

                @if (! $isAdminUser && ! $isCurrentUser)
                    <button type="button" class="btn btn--danger mt-4"
                            onclick="openDetailDeleteModal(@js([
                                'name' => $name,
                                'email' => $user['email'] ?? '',
                            ]))">
                        Soft delete user
                    </button>
                @endif
            </div>
        </section>
    </div>

    @if (! $isAdminUser && ! $isCurrentUser)
        <div class="modal-backdrop" id="detailDeleteUserModal" onclick="if(event.target===this)this.classList.remove('is-open')">
            <div class="modal">
                <h2>Soft Delete User</h2>
                <form method="POST" action="{{ route('admin.users.destroy', $user['id']) }}" id="detailDeleteUserForm">
                    @csrf @method('DELETE')
                    <p class="field__help" id="detailDeleteUserSummary" style="margin-bottom:var(--sp-4)"></p>
                    <div class="flash flash--danger" style="margin-bottom:var(--sp-4)">
                        This will revoke active sessions and hide the account from user management. Existing records stay in the database.
                    </div>
                    <div class="field">
                        <label class="field__label">Type DELETE to confirm</label>
                        <input class="input mono" type="text" id="detailDeleteUserConfirmInput" autocomplete="off" required>
                    </div>
                    <div class="modal__actions">
                        <button type="button" class="btn btn--ghost" onclick="document.getElementById('detailDeleteUserModal').classList.remove('is-open')">Cancel</button>
                        <button type="submit" class="btn btn--danger" id="detailDeleteUserSubmit" disabled>Soft delete</button>
                    </div>
                </form>
            </div>
        </div>
    @endif
@endsection

@push('scripts')
<script>
    function openDetailDeleteModal(user) {
        const input = document.getElementById('detailDeleteUserConfirmInput');
        const submit = document.getElementById('detailDeleteUserSubmit');
        document.getElementById('detailDeleteUserSummary').textContent =
            `Soft delete ${user.name} (${user.email})?`;
        input.value = '';
        submit.disabled = true;
        document.getElementById('detailDeleteUserModal').classList.add('is-open');
        setTimeout(() => input.focus(), 80);
    }

    document.getElementById('detailDeleteUserConfirmInput')?.addEventListener('input', function () {
        document.getElementById('detailDeleteUserSubmit').disabled = this.value !== 'DELETE';
    });
</script>
@endpush
