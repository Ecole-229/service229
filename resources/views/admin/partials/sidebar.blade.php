<aside class="sidebar">
    <div class="brand">
        <span class="brand-icon">🛠</span>
        <span>Service229</span>
    </div>
    <div class="sidebar-caption">Espace Administrateur</div>

    <nav class="sidebar-nav">
        <a class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}" href="{{ route('admin.dashboard') }}">▦ <span>Tableau de bord</span></a>
        <a class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}" href="{{ route('admin.users.index') }}">👥 <span>Utilisateurs</span></a>
        <a class="{{ request()->routeIs('admin.categories.*') ? 'active' : '' }}" href="{{ route('admin.categories.index') }}">▦ <span>Catégories</span></a>
        <a class="{{ request()->routeIs('admin.services.*') ? 'active' : '' }}" href="{{ route('admin.services.index') }}">🧰 <span>Services</span></a>
        <a class="{{ request()->routeIs('admin.requests.*') ? 'active' : '' }}" href="{{ route('admin.requests.index') }}">📋 <span>Demandes</span></a>
        <a class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}" href="{{ route('admin.reports.index') }}">⚑ <span>Signalements</span></a>
        <a class="{{ request()->routeIs('admin.statistics.*') ? 'active' : '' }}" href="{{ route('admin.statistics.index') }}">▥ <span>Statistiques</span></a>
        <a class="{{ request()->routeIs('admin.logs.*') ? 'active' : '' }}" href="{{ route('admin.logs.index') }}">≡ <span>Logs</span></a>
        <a class="{{ request()->routeIs('admin.monitoring.*') ? 'active' : '' }}" href="{{ route('admin.monitoring.index') }}">◉ <span>Monitoring</span></a>
    </nav>
</aside>
