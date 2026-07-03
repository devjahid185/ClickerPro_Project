@extends('admin.layouts.app')

@section('title', 'Settings')

@section('content')
    <div class="page-header">
        <div>
            <h1>Settings</h1>
            <p class="page-header__sub">Manage public landing content, app links, and platform configuration from one place.</p>
        </div>
    </div>

    <form method="POST" action="{{ route('admin.settings.update') }}">
        @csrf @method('PUT')

        @php
            $groupLabels = [
                'landing' => 'Landing Page',
                'app' => 'App & Links',
                'general' => 'General Settings',
            ];
            $groupDescriptions = [
                'landing' => 'Edit the hero, details, and review text shown on the public landing page.',
                'app' => 'Configure download, web app and admin console links used across the landing experience.',
                'general' => 'Core platform values and shared configuration.',
            ];
            $preferredOrder = ['landing', 'app', 'general'];
        @endphp

        <div class="settings-grid">
            @foreach ($preferredOrder as $group)
                @if (isset($groups[$group]))
                    @php $rows = $groups[$group]; unset($groups[$group]); @endphp
                    <section class="settings-card">
                        <div class="settings-card__header">
                            <div>
                                <h2 class="settings-card__title">{{ $groupLabels[$group] ?? ucfirst($group) }}</h2>
                                <p class="settings-card__meta">{{ $groupDescriptions[$group] ?? 'Manage the settings in this group.' }}</p>
                            </div>
                        </div>
                        <div class="settings-card__body">
                            @foreach ($rows as $row)
                                <div class="field">
                                    <label class="field__label">
                                        {{ $row['key'] }}
                                        @if ($row['isSecret'] ?? false)
                                            <span class="badge badge--warning">secret</span>
                                        @endif
                                    </label>
                                    <input class="input{{ ($row['isSecret'] ?? false) ? ' mono' : '' }}"
                                           type="{{ ($row['isSecret'] ?? false) ? 'password' : 'text' }}"
                                           name="settings[{{ $row['key'] }}]"
                                           value="{{ ($row['isSecret'] ?? false) ? '' : ($row['value'] ?? '') }}"
                                           placeholder="{{ ($row['isSecret'] ?? false) && ($row['hasValue'] ?? false) ? '•••••••• (set — leave blank to keep)' : ($row['defaultValue'] ?? '') }}">
                                    @if (!($row['isSecret'] ?? false) && !empty($row['defaultValue']))
                                        <p class="field__help">Default: {{ $row['defaultValue'] }}</p>
                                    @endif
                                </div>
                            @endforeach
                        </div>
                    </section>
                @endif
            @endforeach

            @foreach ($groups as $group => $rows)
                <section class="settings-card">
                    <div class="settings-card__header">
                        <div>
                            <h2 class="settings-card__title">{{ $groupLabels[$group] ?? ucfirst($group) }}</h2>
                            <p class="settings-card__meta">{{ $groupDescriptions[$group] ?? 'Manage the settings in this group.' }}</p>
                        </div>
                    </div>
                    <div class="settings-card__body">
                        @foreach ($rows as $row)
                            <div class="field">
                                <label class="field__label">
                                    {{ $row['key'] }}
                                    @if ($row['isSecret'] ?? false)
                                        <span class="badge badge--warning">secret</span>
                                    @endif
                                </label>
                                <input class="input{{ ($row['isSecret'] ?? false) ? ' mono' : '' }}"
                                       type="{{ ($row['isSecret'] ?? false) ? 'password' : 'text' }}"
                                       name="settings[{{ $row['key'] }}]"
                                       value="{{ ($row['isSecret'] ?? false) ? '' : ($row['value'] ?? '') }}"
                                       placeholder="{{ ($row['isSecret'] ?? false) && ($row['hasValue'] ?? false) ? '•••••••• (set — leave blank to keep)' : ($row['defaultValue'] ?? '') }}">
                                @if (!($row['isSecret'] ?? false) && !empty($row['defaultValue']))
                                    <p class="field__help">Default: {{ $row['defaultValue'] }}</p>
                                @endif
                            </div>
                        @endforeach
                    </div>
                </section>
            @endforeach
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary">Save Settings</button>
        </div>
    </form>
@endsection
