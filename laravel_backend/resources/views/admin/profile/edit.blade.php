@extends('admin.layouts.app')

@section('title', 'My Profile')

@section('content')
    <div class="page-header">
        <div>
            <span class="eyebrow">Admin Account</span>
            <h1>My Profile</h1>
            <p class="page-header__sub">Update your admin information, email, and password without leaving the console.</p>
        </div>
        <div class="page-header__actions">
            <span class="count-pill">{{ strtoupper($admin->role ?? 'ADMIN') }}</span>
        </div>
    </div>

    <div class="settings-grid">
        <section class="settings-card">
            <div class="settings-card__header">
                <div>
                    <h2 class="settings-card__title">Profile Information</h2>
                    <p class="settings-card__meta">These details are shown in the admin panel and account records.</p>
                </div>
            </div>
            <form method="POST" action="{{ route('admin.profile.update') }}" class="settings-card__body">
                @csrf
                @method('PUT')

                <div class="field">
                    <label class="field__label">Full name</label>
                    <input class="input" type="text" name="name" value="{{ old('name', $admin->name) }}" required>
                </div>

                <div class="field">
                    <label class="field__label">Phone</label>
                    <input class="input" type="text" name="phone" value="{{ old('phone', $admin->phone) }}">
                </div>

                <div class="field">
                    <label class="field__label">WhatsApp</label>
                    <input class="input" type="text" name="whatsapp" value="{{ old('whatsapp', $admin->whatsapp) }}">
                </div>

                <div class="field">
                    <label class="field__label">Business name</label>
                    <input class="input" type="text" name="business_name" value="{{ old('business_name', $admin->business_name) }}">
                </div>

                <div class="field">
                    <label class="field__label">Studio address</label>
                    <textarea class="textarea" name="studio_address" rows="3">{{ old('studio_address', $admin->studio_address) }}</textarea>
                </div>

                <div class="field">
                    <label class="field__label">Specialization</label>
                    <input class="input" type="text" name="specialization" value="{{ old('specialization', $admin->specialization) }}">
                </div>

                <div class="field">
                    <label class="field__label">Bio</label>
                    <textarea class="textarea" name="bio" rows="4">{{ old('bio', $admin->bio) }}</textarea>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn--primary">
                        <span class="material-symbols-rounded" aria-hidden="true">save</span>
                        Save Profile
                    </button>
                </div>
            </form>
        </section>

        <section class="settings-card">
            <div class="settings-card__header">
                <div>
                    <h2 class="settings-card__title">Login and Password</h2>
                    <p class="settings-card__meta">Changing email or password requires your current password.</p>
                </div>
            </div>
            <form method="POST" action="{{ route('admin.profile.security') }}" class="settings-card__body">
                @csrf
                @method('PUT')

                <div class="field">
                    <label class="field__label">Email</label>
                    <input class="input" type="email" name="email" value="{{ old('email', $admin->email) }}" required>
                    <p class="field__help">This email is used for admin login.</p>
                </div>

                <div class="field">
                    <label class="field__label">Current password</label>
                    <input class="input" type="password" name="current_password" autocomplete="current-password" required>
                </div>

                <div class="field">
                    <label class="field__label">New password</label>
                    <input class="input" type="password" name="password" autocomplete="new-password" minlength="8">
                    <p class="field__help">Leave blank if you only want to update the email.</p>
                </div>

                <div class="field">
                    <label class="field__label">Confirm new password</label>
                    <input class="input" type="password" name="password_confirmation" autocomplete="new-password" minlength="8">
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn--primary">
                        <span class="material-symbols-rounded" aria-hidden="true">lock_reset</span>
                        Save Login Details
                    </button>
                </div>
            </form>
        </section>
    </div>
@endsection
