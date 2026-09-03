@extends('admin.layouts.app')
@section('title', 'Utilisateur')
@section('content')
<div class="page-heading"><div><h1>{{ $user->name ?? trim(($user->first_name ?? '').' '.($user->last_name ?? '')) ?: $user->email }}</h1><p>Fiche de supervision utilisateur.</p></div><a class="btn btn-outline" href="{{ route('admin.users.index') }}">Retour</a></div>
<div class="detail-grid">
<section class="panel"><h2>Compte</h2><dl class="detail-list"><div><dt>E-mail</dt><dd>{{ $user->email }}</dd></div><div><dt>Rôles</dt><dd>@forelse($user->roles as $role)<span class="badge">{{ $role->name }}</span>@empty — @endforelse</dd></div></dl></section>
<section class="panel"><h2>Profil prestataire</h2>@if($user->providerProfile)<p class="status-ok">Profil prestataire actif.</p>@else<p class="empty">Aucun ProviderProfile.</p>@endif</section>
</div>
@endsection
