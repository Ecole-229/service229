@extends('admin.layouts.app')
@section('title', 'Demandes')
@section('content')
<div class="page-heading"><div><h1>Demandes</h1><p>Supervision des demandes de services.</p></div></div>
<form class="filter-bar" method="GET"><select name="status" onchange="this.form.submit()"><option value="">Tous les statuts</option>@foreach($statuses as $status)<option value="{{ $status }}" @selected(request('status') === $status)>{{ $status }}</option>@endforeach</select></form>
<div class="panel table-panel"><table class="admin-table"><thead><tr><th>Demande</th><th>Client</th><th>Service</th><th>Zone</th><th>Statut</th><th></th></tr></thead><tbody>
@forelse($requests as $item)
<tr><td><strong>{{ $item->title ?? 'Demande #'.$item->id }}</strong></td><td>{{ $item->client_name ?? '—' }}</td><td>{{ $item->service_name ?? '—' }}</td><td>{{ $item->zone_name ?? '—' }}</td><td><span class="badge status-{{ $item->status }}">{{ $item->status }}</span></td><td><a class="btn btn-small btn-outline" href="{{ route('admin.requests.show', $item->id) }}">Voir</a></td></tr>
@empty<tr><td colspan="6" class="empty">Aucune demande.</td></tr>@endforelse
</tbody></table></div><div class="pagination-wrap">{{ $requests->links() }}</div>
@endsection
