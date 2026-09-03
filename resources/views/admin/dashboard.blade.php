@extends('admin.layouts.app')
@section('title', 'Tableau de bord')

@section('content')
<div class="page-heading">
    <div>
        <h1>Tableau de bord administrateur</h1>
        <p>Vue d’ensemble de l’activité de Service229.</p>
    </div>
    <a class="btn btn-outline" href="{{ route('admin.monitoring.index') }}">Voir le monitoring</a>
</div>

<div class="kpi-grid">
    <div class="kpi-card"><span>Utilisateurs</span><strong>{{ $metrics['users'] }}</strong><small>Comptes inscrits</small></div>
    <div class="kpi-card"><span>Prestataires</span><strong>{{ $metrics['providers'] }}</strong><small>Profils prestataires</small></div>
    <div class="kpi-card accent"><span>Demandes actives</span><strong>{{ $metrics['active_requests'] }}</strong><small>Publiées, matchées ou attribuées</small></div>
    <div class="kpi-card"><span>Missions en cours</span><strong>{{ $metrics['missions_in_progress'] }}</strong><small>Statut in_progress</small></div>
    <div class="kpi-card"><span>Missions terminées</span><strong>{{ $metrics['missions_completed'] }}</strong><small>Statut completed</small></div>
    <div class="kpi-card orange"><span>Signalements</span><strong>{{ $metrics['reports'] }}</strong><small>Total enregistré</small></div>
</div>

<div class="dashboard-grid">
    <section class="panel">
        <div class="panel-head"><div><h2>Services les plus recherchés</h2><p>Selon les demandes enregistrées.</p></div></div>
        @forelse($metrics['top_services'] as $service)
            @php($max = max(array_column($metrics['top_services'], 'total') ?: [1]))
            <div class="bar-row">
                <div class="bar-label"><span>{{ $service['name'] }}</span><strong>{{ $service['total'] }}</strong></div>
                <div class="bar-track"><span style="width: {{ $max ? ($service['total'] / $max) * 100 : 0 }}%"></span></div>
            </div>
        @empty
            <p class="empty">Aucune donnée disponible.</p>
        @endforelse
    </section>

    <section class="panel">
        <div class="panel-head"><div><h2>Zones les plus actives</h2><p>Demandes par zone.</p></div></div>
        @forelse($metrics['top_zones'] as $zone)
            <div class="rank-item"><span>{{ $loop->iteration }}. {{ $zone['name'] }}</span><strong>{{ $zone['total'] }}</strong></div>
        @empty
            <p class="empty">Aucune donnée disponible.</p>
        @endforelse
    </section>
</div>

<section class="panel mt-24">
    <div class="panel-head">
        <div><h2>Activités récentes</h2><p>Événements enregistrés dans activity_logs.</p></div>
        <a href="{{ route('admin.logs.index') }}" class="text-link">Voir tout</a>
    </div>
    <div class="activity-list">
        @forelse($metrics['recent_activity'] as $item)
            <div class="activity-item">
                <span class="activity-dot"></span>
                <div><strong>{{ $item['action'] }}</strong><small>{{ !empty($item['user_id']) ? 'Utilisateur #'.$item['user_id'] : 'Système' }} · {{ $item['created_at'] ?? '' }}</small></div>
            </div>
        @empty
            <p class="empty">Aucune activité enregistrée.</p>
        @endforelse
    </div>
</section>
@endsection
