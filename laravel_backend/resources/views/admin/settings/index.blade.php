@extends('admin.layouts.app')

@section('title', 'Settings')

@section('content')
    <div class="page-header"><div><h1>Settings</h1><p class="page-header__sub">Platform configuration. Secret values stay masked until replaced.</p></div></div>

    <form method="POST" action="{{ route('admin.settings.update') }}">
        @csrf @method('PUT')
        @forelse ($groups as $group => $rows)
            <div class="card mb-4">
                <div class="card__header"><span class="card__title">{{ ucfirst($group) }}</span></div>
                <div class="card__body">
                    @foreach ($rows as $row)
                        <div class="field">
                            <label class="field__label">
                                {{ $row['key'] }}
                                @if ($row['isSecret'] ?? false)<span class="badge badge--warning" style="margin-left:6px">secret</span>@endif
                            </label>
                            <input class="input{{ ($row['isSecret'] ?? false) ? ' mono' : '' }}"
                                   type="{{ ($row['isSecret'] ?? false) ? 'password' : 'text' }}"
                                   name="settings[{{ $row['key'] }}]"
                                   value="{{ ($row['isSecret'] ?? false) ? '' : ($row['value'] ?? '') }}"
                                   placeholder="{{ ($row['isSecret'] ?? false) && ($row['hasValue'] ?? false) ? '•••••••• (set — leave blank to keep)' : '' }}">
                        </div>
                    @endforeach
                </div>
            </div>
        @empty
            <div class="card"><div class="empty-state"><div class="empty-state__icon">⊞</div><p>No settings configured.</p></div></div>
        @endforelse

        @if (!empty($groups))
            <button type="submit" class="btn btn--primary">Save Settings</button>
        @endif
    </form>
@endsection
