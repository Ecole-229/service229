<script setup>
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps({
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const page = usePage();
const isAuthenticated = !!page.props.auth?.user;

const serviceCategoryId = ref('');
const zoneId = ref('');

function search() {
    router.get(route('search.index'), {
        service_category_id: serviceCategoryId.value || undefined,
        zone_id: zoneId.value || undefined,
    });
}
</script>

<template>
    <Head title="Accueil" />

    <div class="min-h-screen bg-gray-50">
        <!-- Barre de navigation publique -->
        <header class="border-b border-gray-200 bg-white">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <Link href="/" class="text-lg font-bold text-brand">Service229</Link>
                <div v-if="!isAuthenticated" class="flex items-center gap-3">
                    <Link :href="route('login')" class="text-sm font-medium text-gray-600 hover:text-brand">Connexion</Link>
                    <Link
                        :href="route('register')"
                        class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                    >
                        Sign Up
                    </Link>
                </div>
                <Link v-else :href="route('dashboard')" class="text-sm font-medium text-brand hover:underline">
                    Mon tableau de bord
                </Link>
            </div>
        </header>

        <!-- Hero -->
        <section class="bg-gray-50 px-6 py-16 text-center">
            <h1 class="mx-auto max-w-2xl text-3xl font-bold text-gray-900 sm:text-4xl">
                Trouvez le bon professionnel près de chez vous
            </h1>
            <p class="mx-auto mt-3 max-w-xl text-gray-500">
                Trouvez rapidement un artisan ou prestataire de confiance selon votre besoin et votre quartier au Bénin.
            </p>

            <div class="mx-auto mt-8 flex max-w-2xl flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm sm:flex-row sm:items-center">
                <select
                    v-model="serviceCategoryId"
                    class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand"
                >
                    <option value="">Quel service recherchez-vous ?</option>
                    <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                        {{ category.name }}
                    </option>
                </select>
                <select
                    v-model="zoneId"
                    class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand"
                >
                    <option value="">Où ?</option>
                    <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                </select>
                <button
                    class="rounded-lg bg-brand px-6 py-2.5 text-sm font-semibold text-white hover:bg-brand-dark"
                    @click="search"
                >
                    Rechercher
                </button>
                <Link
                    v-if="isAuthenticated"
                    :href="route('service-requests.create')"
                    class="rounded-lg border border-brand px-6 py-2.5 text-center text-sm font-semibold text-brand hover:bg-brand-light"
                >
                    Publier une demande
                </Link>
            </div>
        </section>

        <!-- Catégories populaires -->
        <section class="mx-auto max-w-6xl px-6 py-12">
            <h2 class="text-xl font-bold text-gray-900">Catégories populaires</h2>
            <p class="mt-1 text-sm text-gray-500">Explorez les services les plus demandés</p>

            <div class="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
                <button
                    v-for="category in serviceCategories"
                    :key="category.id"
                    class="rounded-xl border border-gray-200 bg-white p-5 text-center transition hover:border-brand"
                    @click="() => { serviceCategoryId = category.id; search(); }"
                >
                    <p class="font-medium text-gray-800">{{ category.name }}</p>
                </button>
            </div>
        </section>

        <!-- Comment ça marche -->
        <section class="bg-white px-6 py-16 text-center">
            <h2 class="text-xl font-bold text-gray-900">Comment ça marche ?</h2>
            <div class="mx-auto mt-8 grid max-w-3xl grid-cols-1 gap-8 sm:grid-cols-3">
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">1</div>
                    <p class="mt-3 font-semibold text-gray-900">Recherchez</p>
                    <p class="mt-1 text-sm text-gray-500">Décrivez votre besoin et trouvez les artisans disponibles près de chez vous.</p>
                </div>
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">2</div>
                    <p class="mt-3 font-semibold text-gray-900">Comparez</p>
                    <p class="mt-1 text-sm text-gray-500">Consultez les profils et les devis des prestataires.</p>
                </div>
                <div>
                    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-light font-bold text-brand">3</div>
                    <p class="mt-3 font-semibold text-gray-900">Choisissez</p>
                    <p class="mt-1 text-sm text-gray-500">Contactez l'artisan idéal et convenez d'un rendez-vous en toute confiance.</p>
                </div>
            </div>
        </section>
    </div>
</template>
