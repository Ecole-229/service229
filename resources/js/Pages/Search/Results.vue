<script setup>
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps({
    providers: { type: Array, default: () => [] },
    filters: { type: Object, default: () => ({}) },
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const page = usePage();
const isAuthenticated = !!page.props.auth?.user;

const serviceCategoryId = ref(props.filters.service_category_id ?? '');
const zoneId = ref(props.filters.zone_id ?? '');

function search() {
    router.get(route('search.index'), {
        service_category_id: serviceCategoryId.value || undefined,
        zone_id: zoneId.value || undefined,
    });
}

function requestService(providerProfileId) {
    if (!isAuthenticated) {
        router.visit(route('login'));
        return;
    }
    router.visit(route('service-requests.create', { provider_profile_id: providerProfileId }));
}
</script>

<template>
    <Head title="Résultats de recherche" />

    <div class="min-h-screen bg-gray-50">
        <header class="border-b border-gray-200 bg-white">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
                <Link href="/" class="text-lg font-bold text-brand">Service229</Link>
                <Link v-if="isAuthenticated" :href="route('dashboard')" class="text-sm font-medium text-brand hover:underline">
                    Mon tableau de bord
                </Link>
                <Link v-else :href="route('login')" class="text-sm font-medium text-gray-600 hover:text-brand">Connexion</Link>
            </div>
        </header>

        <div class="mx-auto max-w-6xl px-6 py-10">
            <h1 class="text-2xl font-bold text-gray-900">
                {{ providers.length }} prestataire(s) trouvé(s)
            </h1>

            <div class="mt-6 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm sm:flex-row">
                <select v-model="serviceCategoryId" class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand">
                    <option value="">Tous les services</option>
                    <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                        {{ category.name }}
                    </option>
                </select>
                <select v-model="zoneId" class="flex-1 rounded-lg border-gray-200 text-sm focus:border-brand focus:ring-brand">
                    <option value="">Toutes les zones</option>
                    <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                </select>
                <button class="rounded-lg bg-brand px-6 py-2 text-sm font-semibold text-white hover:bg-brand-dark" @click="search">
                    Rechercher
                </button>
            </div>

            <div v-if="providers.length === 0" class="mt-8 rounded-xl border border-dashed border-gray-300 p-12 text-center">
                <p class="text-gray-500">Aucun prestataire ne correspond à cette recherche pour le moment.</p>
            </div>

            <div v-else class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div
                    v-for="provider in providers"
                    :key="provider.id"
                    class="rounded-xl border border-gray-200 bg-white p-5"
                >
                    <div class="flex items-center gap-3">
                        <div class="flex h-12 w-12 items-center justify-center rounded-full bg-brand-light text-lg font-semibold text-brand">
                            {{ provider.user?.name?.charAt(0) }}
                        </div>
                        <div>
                            <p class="font-semibold text-gray-900">{{ provider.user?.name }}</p>
                            <p v-if="provider.services?.length" class="text-sm text-gray-500">
                                {{ provider.services.map((s) => s.name).join(', ') }}
                            </p>
                        </div>
                    </div>
                    <p v-if="provider.zones?.length" class="mt-3 text-sm text-gray-500">
                        📍 {{ provider.zones.map((z) => z.name).join(', ') }}
                    </p>
                    <button
                        class="mt-4 w-full rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                        @click="requestService(provider.id)"
                    >
                        Demander ce service
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>
