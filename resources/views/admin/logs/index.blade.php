@extends('admin.layouts.app')
@section('title', 'Logs')
@section('content')
<div class="page-heading"><div><h1>Activity logs</h1><p>Traçage des actions importantes pour l’administration.</p></div></div>
<div class="panel table-panel"><table class="admin-table"><thead><tr><th>Date</th><th>Utilisateur</th><th>Action</th></tr></thead><tbody>
@forelse($logs as $log)<tr><td>{{ $log->created_at?->format('d/m/Y H:i:s') }}</td><td>{{ $log->user?->name ?? trim(($log->user?->first_name ?? '').' '.($log->user?->last_name ?? '')) ?: 'Système' }}</td><td>{{ $log->action }}</td></tr>@empty<tr><td colspan="3" class="empty">Aucun log métier.</td></tr>@endforelse
</tbody></table></div><div class="pagination-wrap">{{ $logs->links() }}</div>
@endsection
