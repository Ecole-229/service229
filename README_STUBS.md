# Fichiers STUB temporaires — à lire avant de les utiliser

Ces fichiers ne remplacent PAS le travail de Victorius et Mme Titilola.
Ils servent uniquement à débloquer ton développement/tests en attendant
qu'ils livrent leurs vraies tables.

## Fichiers concernés

- `2026_08_20_090000_add_est_client_et_est_prestataire_to_users_table.php`
- `2026_08_20_090100_create_provider_profiles_table.php`
- `2026_08_20_090200_create_service_categories_table.php`
- `2026_08_20_090300_create_zones_table.php`
- `app/Models/ProviderProfile.php`
- `app/Models/ServiceCategory.php`
- `app/Models/Zone.php`
- `database/factories/ProviderProfileFactory.php`
- `database/factories/ServiceCategoryFactory.php`
- `database/factories/ZoneFactory.php`
- `database/seeders/ScenarioCarreleurTankpeSeeder.php` (peut être gardé,
  il n'a pas besoin d'être supprimé — juste adapté si les noms de colonnes
  changent)

## Comment les utiliser maintenant

```bash
php artisan migrate
php artisan db:seed --class=ScenarioCarreleurTankpeSeeder
```

Ça te crée un client, un prestataire, une ServiceRequest publiée et un
Proposal en attente — de quoi tester tout ton pôle (accepter le devis,
créer la mission, la terminer, laisser un avis...) sans aucune vraie
donnée de Victorius/Titilola.

## Quand Victorius/Titilola livrent leur vrai travail

1. Supprime les 4 migrations stub listées ci-dessus (`database/migrations/`)
2. Supprime les 3 models stub (`app/Models/`)
3. Supprime les 3 factories stub (`database/factories/`)
4. `php artisan migrate:fresh` pour repartir sur les vraies tables
5. Vérifie que la colonne `provider_profiles.user_id` existe bien chez
   Victorius avec ce nom exact — sinon, ajuste les relations Eloquent
   dans `ServiceRequest`, `Proposal`, `Mission`, `Conversation`, `Review`
   (partout où `->providerProfile->user_id` est utilisé)
6. Adapte `ScenarioCarreleurTankpeSeeder` si les noms de colonnes
   diffèrent, sinon garde-le tel quel — utile pour les démos/tests
