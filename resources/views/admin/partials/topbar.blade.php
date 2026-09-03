<header class="topbar">
    <div>
        <span class="topbar-label">Administration Service229</span>
    </div>
    <div class="admin-profile">
        <div class="admin-avatar">A</div>
        <div>
            <strong>{{ auth()->user()->name ?? trim((auth()->user()->first_name ?? '').' '.(auth()->user()->last_name ?? '')) ?: 'Administrateur' }}</strong>
            <small>Administrateur</small>
        </div>
    </div>
</header>
