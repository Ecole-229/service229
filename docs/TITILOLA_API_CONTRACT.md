# Service229 — Contrat API du pôle Titilola

## Architecture

Laravel + Vue 3 + Inertia + API REST `/api/v1` + Sanctum + MySQL.

Les pages restent gérées par Inertia/Vue. L API sert les données dynamiques et
les opérations métier. Le code API ne doit pas recréer les modèles et migrations
déjà intégrés par Abed.

## Responsabilité Titilola

- ServiceCategory
- Service
- Zone
- ProviderProfile (supervision / services / zones)
- provider_services
- provider_zones
- administration
- socle API
- sécurité API
- ActivityLog / monitoring / infrastructure

## Endpoints créés automatiquement

### Public

- GET `/api/v1/categories`
- GET `/api/v1/categories/{category}`
- GET `/api/v1/services`
- GET `/api/v1/services/{service}`
- GET `/api/v1/zones`
- GET `/api/v1/zones/{zone}`
- GET `/api/v1/providers`
- GET `/api/v1/providers/{provider}`

### Prestataire authentifié

- GET `/api/v1/provider-profile`
- PUT `/api/v1/provider-profile/services`
- PUT `/api/v1/provider-profile/zones`

### Admin

- GET `/api/v1/admin/dashboard`
- POST/PUT/DELETE `/api/v1/admin/categories`
- POST/PUT/DELETE `/api/v1/admin/services`
- POST/PUT/DELETE `/api/v1/admin/zones`

## Points volontairement NON automatisés

Ces éléments dépendent du schéma exact et doivent être validés avant codage :

1. création/activation complète d un ProviderProfile si la table comporte des
   champs obligatoires supplémentaires ;
2. champ exact de validation administrative du ProviderProfile ;
3. endpoints Reports/Disputes si leur contrat métier est encore en évolution ;
4. modification destructive d une migration existante ;
5. `migrate:fresh`, qui ne doit jamais être lancé automatiquement.

## Contrat métier partagé

- `users.estClient` : capacité Client
- `users.estPrestataire` : capacité Prestataire
- `roles/role_user` : autorisations spéciales, notamment Admin
- `services.category_id` -> `service_categories.id`
- `provider_services` relie ProviderProfile et Service
- `provider_zones` relie ProviderProfile et Zone

## Prochaine validation commune Titilola + Abed

Valider le scénario :

Client -> Carrelage + Tankpè -> Providers -> ServiceRequest -> Proposal ->
Mission -> Conversation/Message -> Notification -> Review -> Dashboard Admin.
