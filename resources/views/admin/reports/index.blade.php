@extends('admin.layouts.app')
@section('title', 'Signalements')
@section('content')
<div class="page-heading"><div><h1>Signalements</h1><p>Consulter les signalements enregistrés sur la plateforme.</p></div></div>
<div class="panel table-panel"><table class="admin-table"><thead><tr><th>ID</th><th>Utilisateur</th><th>Mission</th><th>Statut</th><th>Date</th><th></th></tr></thead><tbody>
@forelse($reports as $report)
<tr><td>#{{ $report->id }}</td><td>{{ $report->reporter?->name ?? trim(($report->reporter?->first_name ?? '').' '.($report->reporter?->last_name ?? '')) ?: '—' }}</td><td>{{ $report->mission_id ? '#'.$report->mission_id : '—' }}</td><td><span class="badge">{{ $report->status ?? 'Non défini' }}</span></td><td>{{ $report->created_at?->format('d/m/Y H:i') }}</td><td><a class="btn btn-small btn-outline" href="{{ route('admin.reports.show', $report) }}">Voir</a></td></tr>
@empty<tr><td colspan="6" class="empty">Aucun signalement.</td></tr>@endforelse
</tbody></table></div><div class="pagination-wrap">{{ $reports->links() }}</div>
@endsection
