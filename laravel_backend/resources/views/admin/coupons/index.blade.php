@extends('admin.layouts.app')

@section('title', 'Coupons')

@section('content')
    <div class="page-header">
        <div class="flex items-center gap-3"><h1>Coupons</h1><span class="count-pill">{{ $coupons->count() }} codes</span></div>
        <button type="button" class="btn btn--primary" onclick="document.getElementById('createCouponModal').classList.add('is-open')">+ New Coupon</button>
    </div>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Code</th><th>Type</th><th>Value</th><th>Uses</th><th>Expires</th><th>Status</th><th style="text-align:right">Actions</th></tr></thead>
                <tbody>
                    @forelse ($coupons as $c)
                        <tr>
                            <td><strong class="mono">{{ $c->code }}</strong></td>
                            <td>{{ $c->type }}</td>
                            <td class="mono">{{ $c->type === 'PERCENT' ? $c->value . '%' : ($c->type === 'PRO_DAYS' ? $c->value . ' days' : '৳' . number_format($c->value)) }}</td>
                            <td class="mono">{{ $c->uses ?? 0 }}{{ $c->max_uses ? ' / ' . $c->max_uses : '' }}</td>
                            <td class="mono" style="font-size:13px">{{ $c->expires_at ? $c->expires_at->format('d M Y') : '—' }}</td>
                            <td>
                                @if ($c->is_active)<span class="badge badge--success">Active</span>
                                @else<span class="badge badge--neutral">Inactive</span>@endif
                            </td>
                            <td>
                                <div class="cell-actions">
                                    <form method="POST" action="{{ route('admin.coupons.toggle', $c->id) }}">
                                        @csrf @method('PATCH')
                                        <button type="submit" class="btn btn--ghost btn--sm">{{ $c->is_active ? 'Deactivate' : 'Activate' }}</button>
                                    </form>
                                    <form method="POST" action="{{ route('admin.coupons.destroy', $c->id) }}" onsubmit="return confirm('Delete coupon {{ $c->code }}?')">
                                        @csrf @method('DELETE')
                                        <button type="submit" class="btn btn--ghost btn--sm" style="color:var(--danger)">Delete</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7"><div class="empty-state"><div class="empty-state__icon">⊕</div><p>No coupons yet.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div class="modal-backdrop" id="createCouponModal" onclick="if(event.target===this)this.classList.remove('is-open')">
        <div class="modal">
            <h2>New Coupon</h2>
            <form method="POST" action="{{ route('admin.coupons.store') }}">
                @csrf
                <div class="field">
                    <label class="field__label">Code</label>
                    <input class="input mono" type="text" name="code" value="{{ old('code') }}" style="text-transform:uppercase" required>
                </div>
                <div class="field">
                    <label class="field__label">Type</label>
                    <select class="select" name="type">
                        @foreach ($types as $t)<option value="{{ $t }}" @selected(old('type')===$t)>{{ $t }}</option>@endforeach
                    </select>
                </div>
                <div class="field">
                    <label class="field__label">Value <span class="text-muted">(% / ৳ / days)</span></label>
                    <input class="input" type="number" name="value" step="0.01" min="0" value="{{ old('value') }}" required>
                </div>
                <div class="field">
                    <label class="field__label">Max uses <span class="text-muted">(optional)</span></label>
                    <input class="input" type="number" name="max_uses" min="1" value="{{ old('max_uses') }}">
                </div>
                <div class="field">
                    <label class="field__label">Expires at <span class="text-muted">(optional)</span></label>
                    <input class="input" type="date" name="expires_at" value="{{ old('expires_at') }}">
                </div>
                <label class="flex items-center gap-2" style="font-size:13px;color:var(--text-dim)">
                    <input type="checkbox" name="is_active" value="1" checked> Active
                </label>
                <div class="modal__actions">
                    <button type="button" class="btn btn--ghost" onclick="document.getElementById('createCouponModal').classList.remove('is-open')">Cancel</button>
                    <button type="submit" class="btn btn--primary">Create</button>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
<script>
    @if ($errors->any())
        document.getElementById('createCouponModal').classList.add('is-open');
    @endif
</script>
@endpush
