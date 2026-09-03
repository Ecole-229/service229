# Checklist d'intégration — Titilola

- [ ] La branche de travail part de `develop`.
- [ ] `users`, `roles`, `role_user`, `provider_profiles` existent dans le socle commun.
- [ ] `service_categories`, `services`, `zones` existent et respectent les noms validés.
- [ ] `service_requests`, `proposals`, `missions` existent dans le module de mise en relation.
- [ ] `User` expose `roles()`.
- [ ] `User` expose `providerProfile()`.
- [ ] Le middleware `admin` est enregistré.
- [ ] `routes/admin.php` est inclus depuis `routes/web.php`.
- [ ] Les migrations `reports` et `activity_logs` sont validées par le groupe avant `php artisan migrate`.
- [ ] Le CSS `public/css/service229-admin.css` est accessible.
- [ ] `/admin` est inaccessible à un utilisateur non admin.
- [ ] Le dashboard métier et le monitoring technique restent deux pages distinctes.
- [ ] Le scénario « carreleur à Tankpè » reste le test d'intégration principal du groupe.
