@extends('admin.layouts.app')
@section('title', 'Modifier le service')
@section('content')
<div class="page-heading"><div><h1>Modifier le service</h1><p>{{ $service->name }}</p></div></div>
<form class="panel form-panel" method="POST" action="{{ route('admin.services.update', $service) }}">@csrf @method('PUT') @include('admin.services._form')</form>
@endsection
