@extends('admin.layouts.app')
@section('title', 'Utilisateurs')
@section('content')
<div class="page-heading"><div><h1>Utilisateurs</h1><p>Supervision des comptes, rôles et profils prestataires.</p></div></div>
<form class="filter-bar" method="GET"><input name="q" value="{{ request('q') }}" placeholder="Rechercher par nom ou e-mail"><button class="btn btn-primary">Rechercher</button></form>
<div class="panel table-panel"><table class="admin-table">
<thead><tr><th>Utilisateur</th><th>E-mail</th><th>Rôles</th><th>Prestataire</th><th></th></tr></thead>
<tbody>
@forelse($users as $user)
<tr>
<td><strong>{{ $user->name ?? trim(($user->first_name ?? '').' '.($user->last_name ?? '')) ?: $user->email }}</strong></td><td>{{ $user->email }}</td>
<td>@forelse($user->roles as $role)<span class="badge">{{ $role->name }}</span>@empty — @endforelse</td>
<td>{{ $user->providerProfile ? 'Oui' : 'Non' }}</td>
<td><a class="btn btn-small btn-outline" href="{{ route('admin.users.show', $user) }}">Voir</a></td>
</tr>
@empty<tr><td colspan="5" class="empty">Aucun utilisateur.</td></tr>@endforelse
</tbody></table></div>
<div class="pagination-wrap">{{ $users->links() }}</div>
@endsection
