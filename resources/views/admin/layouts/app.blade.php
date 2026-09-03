<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Administration') — Service229</title>
    <link rel="stylesheet" href="{{ asset('css/service229-admin.css') }}">
</head>
<body>
<div class="admin-shell">
    @include('admin.partials.sidebar')

    <div class="admin-main">
        @include('admin.partials.topbar')

        <main class="admin-content">
            @if(session('success'))
                <div class="alert-success">{{ session('success') }}</div>
            @endif

            @if($errors->any())
                <div class="alert-error">
                    <strong>Veuillez corriger les éléments suivants :</strong>
                    <ul>
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            @yield('content')
        </main>
    </div>
</div>
</body>
</html>
