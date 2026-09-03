@extends('admin.layouts.app')
@section('title', 'Statistiques')
@section('content')
<div class="page-heading"><div><h1>Statistiques</h1><p>Indicateurs métier séparés du monitoring technique.</p></div></div>
<div class="kpi-grid"><div class="kpi-card"><span>Utilisateurs</span><strong>{{ $metrics['users'] }}</strong></div><div class="kpi-card"><span>Prestataires</span><strong>{{ $metrics['providers'] }}</strong></div><div class="kpi-card"><span>Demandes actives</span><strong>{{ $metrics['active_requests'] }}</strong></div><div class="kpi-card"><span>Missions en cours</span><strong>{{ $metrics['missions_in_progress'] }}</strong></div><div class="kpi-card accent"><span>Taux demande → mission</span><strong>{{ $transformationRate }}%</strong></div></div>
<div class="dashboard-grid">
<section class="panel"><h2>Services les plus recherchés</h2>@forelse($metrics['top_services'] as $service)<div class="rank-item"><span>{{ $service['name'] }}</span><strong>{{ $service['total'] }}</strong></div>@empty<p class="empty">Aucune donnée.</p>@endforelse</section>
<section class="panel"><h2>Zones les plus actives</h2>@forelse($metrics['top_zones'] as $zone)<div class="rank-item"><span>{{ $zone['name'] }}</span><strong>{{ $zone['total'] }}</strong></div>@empty<p class="empty">Aucune donnée.</p>@endforelse</section>
</div>
@endsection
