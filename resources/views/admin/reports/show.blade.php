@extends('admin.layouts.app')
@section('title', 'Signalement')
@section('content')
<div class="page-heading"><div><h1>Signalement #{{ $report->id }}</h1><p>Consultation du signalement.</p></div><a class="btn btn-outline" href="{{ route('admin.reports.index') }}">Retour</a></div>
<div class="detail-grid"><section class="panel"><h2>Informations</h2><dl class="detail-list"><div><dt>Utilisateur</dt><dd>{{ $report->reporter?->name ?? trim(($report->reporter?->first_name ?? '').' '.($report->reporter?->last_name ?? '')) ?: '—' }}</dd></div><div><dt>Mission</dt><dd>{{ $report->mission_id ? '#'.$report->mission_id : '—' }}</dd></div><div><dt>Statut</dt><dd>{{ $report->status ?? 'Non défini' }}</dd></div><div><dt>Date</dt><dd>{{ $report->created_at?->format('d/m/Y H:i') }}</dd></div></dl></section></div>
<p class="note">Le guide du groupe ne fixe pas les valeurs du cycle de statut des signalements. Cette version les affiche sans inventer de workflow supplémentaire.</p>
@endsection
