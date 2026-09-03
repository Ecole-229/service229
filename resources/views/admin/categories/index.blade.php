@extends('admin.layouts.app')
@section('title', 'Catégories')
@section('content')
<div class="page-heading">
    <div><h1>Catégories</h1><p>Administrer le référentiel des catégories de services.</p></div>
    <a class="btn btn-primary" href="{{ route('admin.categories.create') }}">+ Nouvelle catégorie</a>
</div>
<div class="panel table-panel">
<table class="admin-table">
    <thead><tr><th>Catégorie</th><th>Services</th><th>Action</th></tr></thead>
    <tbody>
    @forelse($categories as $category)
        <tr><td><strong>{{ $category->name }}</strong></td><td>{{ $category->services_count }}</td><td><a class="btn btn-small btn-outline" href="{{ route('admin.categories.edit', $category) }}">Modifier</a></td></tr>
    @empty
        <tr><td colspan="3" class="empty">Aucune catégorie.</td></tr>
    @endforelse
    </tbody>
</table>
</div>
<div class="pagination-wrap">{{ $categories->links() }}</div>
@endsection
