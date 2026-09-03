@extends('admin.layouts.app')
@section('title', 'Monitoring')
@section('content')
<div class="page-heading"><div><h1>Monitoring technique</h1><p>État technique de l’application, distinct des statistiques métier.</p></div><a class="btn btn-outline" href="{{ route('admin.monitoring.index') }}">Actualiser</a></div>
<div class="health-grid">
<div class="health-card"><span>Application</span><strong class="{{ $health['application']['ok'] ? 'status-ok' : 'status-bad' }}">{{ $health['application']['label'] }}</strong></div>
<div class="health-card"><span>Base de données</span><strong class="{{ $health['database']['ok'] ? 'status-ok' : 'status-bad' }}">{{ $health['database']['label'] }}</strong></div>
<div class="health-card"><span>Temps de contrôle</span><strong>{{ $health['response_ms'] }} ms</strong></div>
<div class="health-card"><span>Mémoire PHP</span><strong>{{ $health['memory_mb'] }} MB</strong></div>
<div class="health-card"><span>Charge CPU</span><strong>{{ $health['cpu_load'] ?? 'N/D' }}</strong></div>
<div class="health-card"><span>Stockage utilisé</span><strong>{{ $health['disk']['percent'] !== null ? $health['disk']['percent'].'%' : 'N/D' }}</strong></div>
<div class="health-card"><span>Docker</span><strong>{{ $health['docker']['detected'] ? 'Détecté' : 'Non détecté' }}</strong><small>{{ $health['docker']['label'] }}</small></div>
<div class="health-card orange"><span>Erreurs récentes</span><strong>{{ $health['log']['errors'] }}</strong><small>Dans les dernières lignes du log Laravel</small></div>
</div>
<section class="panel mt-24"><div class="panel-head"><div><h2>Derniers événements Laravel</h2><p>Extrait du fichier storage/logs/laravel.log.</p></div></div><div class="log-console">@forelse($health['log']['lines'] as $line)<div>{{ $line }}</div>@empty<div>Aucun log disponible.</div>@endforelse</div></section>
@endsection
