@extends('admin.layouts.app')

@section('title', 'Subscriptions')

@section('content')
    <div class="page-header">
        <div>
            <h1>Subscriptions &amp; Features</h1>
            <p class="page-header__sub">Toggle which features require a PRO plan. {{ $paidCount }} feature(s) are PRO-only.</p>
        </div>
    </div>

    <div class="card mb-4">
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Feature</th><th>Access</th><th style="text-align:right">Action</th></tr></thead>
                <tbody>
                    @forelse ($features as $f)
                        <tr>
                            <td><strong>{{ $f->label ?: $f->key }}</strong><div class="cell-sub mono">{{ $f->key }}</div></td>
                            <td>
                                @if ($f->requires_pro)<span class="badge badge--warning">PRO</span>
                                @else<span class="badge badge--success">Free</span>@endif
                            </td>
                            <td style="text-align:right">
                                <form method="POST" action="{{ route('admin.subscriptions.toggle', $f->key) }}">
                                    @csrf @method('PATCH')
                                    <button type="submit" class="btn btn--ghost btn--sm">{{ $f->requires_pro ? 'Make Free' : 'Make PRO' }}</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="3"><div class="empty-state"><div class="empty-state__icon">◈</div><p>No feature flags configured.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div class="flash" style="background:var(--info-soft);color:var(--info)">
        💡 Grant individual users a PRO plan from the <strong>Users</strong> page.
    </div>
@endsection
