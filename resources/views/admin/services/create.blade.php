@extends('admin.layouts.app')
@section('title', 'Nouveau service')
@section('content')
<div class="page-heading"><div><h1>Nouveau service</h1><p>Ajouter un service au référentiel.</p></div></div>
<form class="panel form-panel" method="POST" action="{{ route('admin.services.store') }}">@csrf @include('admin.services._form')</form>
@endsection
