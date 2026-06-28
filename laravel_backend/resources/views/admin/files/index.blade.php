@extends('admin.layouts.app')

@section('title', 'Files')

@section('content')
    @php
        $fmt = function ($bytes) {
            if ($bytes < 1024) return $bytes . ' B';
            if ($bytes < 1048576) return round($bytes / 1024, 1) . ' KB';
            return round($bytes / 1048576, 2) . ' MB';
        };
    @endphp

    <div class="page-header">
        <div class="flex items-center gap-3"><h1>Files</h1><span class="count-pill">{{ count($files) }} files · {{ $fmt($totalBytes) }}</span></div>
    </div>

    <div class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Name</th><th>Size</th><th>Modified</th><th style="text-align:right">Actions</th></tr></thead>
                <tbody>
                    @forelse ($files as $f)
                        <tr>
                            <td><a href="{{ $f['url'] }}" target="_blank" rel="noopener"><strong style="color:var(--primary)">{{ $f['name'] }}</strong></a></td>
                            <td class="mono" style="font-size:13px">{{ $fmt($f['size'] ?? 0) }}</td>
                            <td class="mono" style="font-size:13px">{{ !empty($f['modified']) ? \Illuminate\Support\Carbon::parse($f['modified'])->format('d M Y, H:i') : '—' }}</td>
                            <td style="text-align:right">
                                <form method="POST" action="{{ route('admin.files.destroy', $f['name']) }}" onsubmit="return confirm('Delete {{ $f['name'] }}?')">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn btn--ghost btn--sm" style="color:var(--danger)">Delete</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="4"><div class="empty-state"><div class="empty-state__icon">▣</div><p>No uploaded files.</p></div></td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
@endsection
