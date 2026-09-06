<script setup>
import { Link, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    stats: {
        type: Object,
        default: () => ({ demandes_actives: 0, propositions_recues: 0, missions_en_cours: 0, missions_terminees: 0 }),
    },
    recentServiceRequests: { type: Array, default: () => [] },
});

const page = usePage();
const userName = computed(() => page.props.auth?.user?.name ?? '');

const statCards = computed(() => [
    { label: 'Demandes actives', value: props.stats.demandes_actives, icon: '📋' },
    { label: 'Propositions reçues', value: props.stats.propositions_recues, icon: '📩' },
    { label: 'Mission en cours', value: props.stats.missions_en_cours, icon: '💼', highlight: true },
    { label: 'Missions terminées', value: props.stats.missions_terminees, icon: '✅' },
]);

const statusLabels = {
    draft: 'Brouillon',
    published: 'En attente de devis',
    matched: 'Propositions reçues',
    assigned: 'Artisan assigné',
    cancelled: 'Annulée',
    expired: 'Expirée',
    closed: 'Terminée',
};
</script>

<template>
    <AppLayout title="Tableau de bord">
        <h1 class="text-2xl font-bold text-gray-900">Bonjour {{ userName }} 👋</h1>
        <p class="mt-1 text-sm text-gray-500">Voici un aperçu de vos activités récentes.</p>

        <div class="mt-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
            <div
                v-for="card in statCards"
                :key="card.label"
                class="rounded-xl p-5"
                :class="card.highlight ? 'bg-brand text-white' : 'border border-gray-200 bg-white'"
            >
                <span class="text-2xl">{{ card.icon }}</span>
                <p class="mt-3 text-2xl font-bold">{{ card.value }}</p>
                <p class="text-sm" :class="card.highlight ? 'text-white/80' : 'text-gray-500'">{{ card.label }}</p>
            </div>
        </div>

        <div class="mt-10 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900">Mes demandes récentes</h2>
            <Link :href="route('service-requests.index')" class="text-sm font-medium text-brand hover:underline">
                Voir tout
            </Link>
        </div>

        <div v-if="recentServiceRequests.length === 0" class="mt-4 rounded-xl border border-dashed border-gray-300 p-8 text-center">
            <p class="text-gray-500">Aucune demande pour le moment.</p>
            <Link :href="route('service-requests.create')" class="mt-2 inline-block font-semibold text-brand hover:underline">
                Publier votre première demande
            </Link>
        </div>

        <div v-else class="mt-4 space-y-3">
            <Link
                v-for="sr in recentServiceRequests"
                :key="sr.id"
                :href="sr.status === 'draft' ? route('service-requests.edit', sr.id) : route('service-requests.show', sr.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4 hover:border-brand"
            >
                <div>
                    <p class="font-semibold text-gray-900">{{ sr.title }}</p>
                    <p class="text-sm text-gray-500">{{ sr.service_category?.name }} · {{ sr.zone?.name }}</p>
                </div>
                <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-600">
                    {{ statusLabels[sr.status] ?? sr.status }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
