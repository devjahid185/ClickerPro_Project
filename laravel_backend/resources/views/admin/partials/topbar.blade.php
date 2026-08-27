{{-- Admin topbar — Graphy7 Admin design (dark-only, lime accent) --}}
@php $admin = auth()->user(); @endphp
<header class="topbar">
    <div class="topbar__brand">
        <button class="icon-button menu-toggle" aria-label="Menu">
            <span class="material-symbols-rounded" aria-hidden="true">menu</span>
        </button>
        <div>
            <span class="topbar__title">@yield('title', 'Dashboard')</span>
            <div class="topbar__subtitle">Graphy7 · Platform Control</div>
        </div>
    </div>

    <div class="topbar__actions">
        <form class="topbar__search" method="GET" action="{{ route('admin.users') }}">
            <span class="material-symbols-rounded" aria-hidden="true">search</span>
            <input type="search" name="search" placeholder="Search users — name, phone, email">
        </form>
        @if ($admin)
            <a class="topbar__profile" href="{{ route('admin.profile') }}" style="text-decoration:none;color:inherit">
                <div class="avatar">{{ strtoupper(substr($admin->name ?? $admin->email, 0, 1)) }}</div>
                <div>
                    <div class="topbar__profile-name">{{ $admin->name ?? $admin->full_name ?? 'Admin' }}</div>
                    <div class="text-muted mono" style="font-size:11px">{{ $admin->email }}</div>
                </div>
            </a>
        @endif
    </div>
</header>
