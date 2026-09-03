# Service229 — Module de Mme Titilola

Ce dossier réalise uniquement le périmètre attribué à **Mme Titilola** dans le guide UML du Groupe D :

- dashboard administrateur ;
- administration des catégories et services ;
- supervision des utilisateurs et demandes ;
- signalements ;
- statistiques ;
- activity logs ;
- Docker ;
- monitoring technique simple.

## Décisions du groupe respectées

- une personne = un seul `User` ;
- `ProviderProfile` reste facultatif ;
- application Laravel monolithique ;
- MySQL ;
- tables partagées : `users`, `roles`, `role_user`, `provider_profiles`, `service_categories`, `services`, `zones`, `provider_services`, `provider_zones`, `service_requests`, `proposals`, `missions`, `reviews`, `notifications`, `reports`, `activity_logs` ;
- statuts `ServiceRequest` : `draft`, `published`, `matched`, `assigned`, `cancelled`, `expired`, `closed` ;
- statuts `Proposal` : `pending`, `accepted`, `rejected`, `withdrawn` ;
- statuts `Mission` : `pending`, `in_progress`, `awaiting_confirmation`, `completed`, `cancelled`, `disputed` ;
- pas de paiement, messagerie temps réel ou géolocalisation avancée dans ce module.

## Important avant intégration

Le guide ne fixe pas la version exacte de Laravel, PHP ou MySQL. Les fichiers Docker fournis sont donc un **socle configurable**, sans changer l'architecture décidée par le groupe.

Les modèles/tables `users`, `provider_profiles`, `service_requests`, `missions` et `zones` sont des dépendances partagées avec les modules de Victorius et Abed. Le code Admin les **consulte** et ne recrée pas leur logique métier.

## Installation dans le projet du groupe

1. Copier les dossiers `app`, `resources`, `public`, `routes` et les migrations nécessaires dans le projet Laravel.
2. Ajouter dans `routes/web.php` :

```php
require __DIR__.'/admin.php';
```

3. Enregistrer l'alias middleware `admin` vers :

```php
App\Http\Middleware\EnsureAdmin::class
```

L'endroit exact dépend de la version Laravel utilisée par le groupe :
- versions récentes : `bootstrap/app.php` ;
- versions plus anciennes : `app/Http/Kernel.php`.

4. Vérifier que le modèle `User` possède une relation `roles()` vers la table pivot `role_user`.
5. Exécuter les migrations `reports` et `activity_logs` si elles n'existent pas encore dans la branche commune.
6. Ouvrir `/admin` avec un utilisateur ayant le rôle `admin`.

## Tables `service_categories` et `services`

Le module suppose le contrat décidé par le groupe :

- `service_categories`: `id`, `name` ;
- `services`: `id`, `category_id`, `name`.

Si les migrations sont déjà créées dans la branche commune, ne pas les recréer.

## Écrans livrés

- `/admin` — dashboard métier
- `/admin/categories`
- `/admin/services`
- `/admin/users`
- `/admin/requests`
- `/admin/reports`
- `/admin/statistics`
- `/admin/logs`
- `/admin/monitoring`

## Style

L'interface reprend les maquettes Service229 fournies :

- vert principal ;
- accent orange ;
- fond gris très clair ;
- cartes blanches arrondies ;
- sidebar latérale ;
- typographie système claire ;
- responsive desktop/mobile.

## Contrat de clé étrangère à confirmer avant merge

Le diagramme UML du guide affiche `Proposal.request_id` vers `ServiceRequest`. Le module de supervision utilise donc `proposals.request_id`. Si la migration commune du groupe a finalement retenu `service_request_id`, remplacer ce nom dans `ServiceRequestSupervisionController` avant le merge. Cette vérification fait partie de la checklist du groupe (« noms des tables et clés étrangères validés »).
