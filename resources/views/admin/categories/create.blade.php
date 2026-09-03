@extends('admin.layouts.app')
@section('title', 'Nouvelle catégorie')
@section('content')
<div class="page-heading"><div><h1>Nouvelle catégorie</h1><p>Créer une catégorie du référentiel Service229.</p></div></div>
<form class="panel form-panel" method="POST" action="{{ route('admin.categories.store') }}">@csrf @include('admin.categories._form')</form>
@endsection
