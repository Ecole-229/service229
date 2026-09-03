@extends('admin.layouts.app')
@section('title', 'Services')
@section('content')
<div class="page-heading">
    <div><h1>Services</h1><p>Administrer les services proposés sur Service229.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.services.create') }}">+ Nouveau service</a>
</div>
<form class="filter-bar" method="GET">
    <select name="category" onchange="this.form.submit()">
        <option value="">Toutes les catégories</option>
        @foreach($categories as $category)<option value="{{ $category->id }}" @selected(request('category') == $category->id)>{{ $category->name }}</option>@endforeach
    </select>
</form>
<div class="panel table-panel">
<table class="admin-table">
<thead><tr><th>Service</th><th>Catégorie</th><th>Action</th></tr></thead>
<tbody>
@forelse($services as $service)
<tr><td><strong>{{ $service->name }}</strong></td><td>{{ $service->category?->name ?? '—' }}</td><td><a class="btn btn-small btn-outline" href="{{ route('admin.services.edit', $service) }}">Modifier</a></td></tr>
@empty<tr><td colspan="3" class="empty">Aucun service.</td></tr>@endforelse
</tbody>
</table>
</div>
<div class="pagination-wrap">{{ $services->links() }}</div>
@endsection
