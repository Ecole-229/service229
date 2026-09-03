@extends('admin.layouts.app')
@section('title', 'Modifier la catégorie')
@section('content')
<div class="page-heading"><div><h1>Modifier la catégorie</h1><p>{{ $category->name }}</p></div></div>
<form class="panel form-panel" method="POST" action="{{ route('admin.categories.update', $category) }}">@csrf @method('PUT') @include('admin.categories._form')</form>
@endsection
