@extends('admin.layouts.app')
@section('title', 'Demande')
@section('content')
<div class="page-heading"><div><h1>{{ $serviceRequest->title ?? 'Demande #'.$serviceRequest->id }}</h1><p>Supervision du cycle demande → proposition → mission.</p></div><a class="btn btn-outline" href="{{ route('admin.requests.index') }}">Retour</a></div>
<div class="detail-grid">
<section class="panel"><h2>Demande</h2><dl class="detail-list"><div><dt>Client</dt><dd>{{ $serviceRequest->client_name ?? '—' }}</dd></div><div><dt>Service</dt><dd>{{ $serviceRequest->service_name ?? '—' }}</dd></div><div><dt>Zone</dt><dd>{{ $serviceRequest->zone_name ?? '—' }}</dd></div><div><dt>Statut</dt><dd><span class="badge">{{ $serviceRequest->status }}</span></dd></div></dl></section>
<section class="panel"><h2>Mission</h2>@if($mission)<p><span class="badge">{{ $mission->status }}</span></p>@else<p class="empty">Aucune mission liée.</p>@endif</section>
</div>
<section class="panel mt-24"><h2>Propositions</h2><div class="stack-list">@forelse($proposals as $proposal)<div class="stack-item"><span>Proposal #{{ $proposal->id }}</span><span class="badge">{{ $proposal->status }}</span></div>@empty<p class="empty">Aucune proposition.</p>@endforelse</div></section>
@endsection
