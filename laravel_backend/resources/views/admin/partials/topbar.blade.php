{{-- Admin topbar --}}
@php $admin = auth()->user(); @endphp
<header class="topbar">
    <div class="topbar__brand">
        <button class="icon-button menu-toggle" aria-label="Menu">
            <span class="material-symbols-rounded" aria-hidden="true">menu</span>
        </button>
        <div>
            <span class="topbar__title">@yield('title', 'Dashboard')</span>
            <div class="topbar__subtitle">Platform Control Room</div>
        </div>
    </div>

    <div class="topbar__actions">
        <form class="topbar__search" method="GET" action="{{ route('admin.users') }}">
            <span class="material-symbols-rounded" aria-hidden="true">search</span>
            <input type="search" name="search" placeholder="Search users or studios">
        </form>
        <a class="icon-button" href="{{ route('admin.support') }}" aria-label="Support">
            <span class="material-symbols-rounded" aria-hidden="true">inbox</span>
        </a>
        <button class="icon-button" data-theme-toggle aria-label="Toggle theme">
            <span class="material-symbols-rounded" aria-hidden="true">dark_mode</span>
        </button>
        @if ($admin)
            <div class="topbar__profile">
                <div class="avatar">{{ strtoupper(substr($admin->name ?? $admin->email, 0, 1)) }}</div>
                <div>
                    <div class="topbar__profile-name">{{ $admin->name ?? $admin->full_name ?? 'Admin' }}</div>
                    <div class="text-muted mono" style="font-size:11px">{{ $admin->email }}</div>
                </div>
            </div>
        @endif
    </div>
</header>
