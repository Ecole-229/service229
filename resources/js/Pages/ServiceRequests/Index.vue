<script setup>
import { Link, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    serviceRequests: { type: Object, required: true },
});

const statusLabels = {
    draft: { text: 'Brouillon', class: 'bg-gray-100 text-gray-600' },
    published: { text: 'En attente de devis', class: 'bg-amber-100 text-amber-700' },
    matched: { text: 'Propositions reçues', class: 'bg-blue-100 text-blue-700' },
    assigned: { text: 'Artisan assigné', class: 'bg-brand-light text-brand' },
    cancelled: { text: 'Annulée', class: 'bg-gray-100 text-gray-500' },
    expired: { text: 'Expirée', class: 'bg-gray-100 text-gray-500' },
    closed: { text: 'Terminée', class: 'bg-green-100 text-green-700' },
};

function destroyDraft(id) {
    if (!confirm('Supprimer définitivement ce brouillon ?')) return;
    router.delete(route('service-requests.destroy', id));
}
</script>

<template>
    <AppLayout title="Mes demandes">
        <div class="mb-6 flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">Mes demandes</h1>
            <Link
                :href="route('service-requests.create')"
                class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
            >
                + Nouvelle demande
            </Link>
        </div>

        <div v-if="serviceRequests.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Vous n'avez encore publié aucune demande.</p>
            <Link :href="route('service-requests.create')" class="mt-3 inline-block font-semibold text-brand hover:underline">
                Publier votre première demande
            </Link>
        </div>

        <div v-else class="space-y-3">
            <div
                v-for="sr in serviceRequests.data"
                :key="sr.id"
                class="rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <Link :href="sr.status === 'draft' ? undefined : route('service-requests.show', sr.id)" class="block">
                    <div class="flex items-start justify-between gap-4">
                        <div class="min-w-0">
                            <h2 class="truncate font-semibold text-gray-900">{{ sr.title }}</h2>
                            <p class="mt-1 text-sm text-gray-500">
                                {{ sr.service_category?.name }} · {{ sr.zone?.name }}
                            </p>
                            <p v-if="sr.proposals?.length" class="mt-2 text-sm text-brand">
                                {{ sr.proposals.length }} devis reçu(s)
                            </p>
                        </div>
                        <span
                            class="shrink-0 rounded-full px-3 py-1 text-xs font-medium"
                            :class="statusLabels[sr.status]?.class"
                        >
                            {{ statusLabels[sr.status]?.text ?? sr.status }}
                        </span>
                    </div>
                </Link>

                <!-- Actions spécifiques aux brouillons -->
                <div v-if="sr.status === 'draft'" class="mt-4 flex gap-3 border-t border-gray-100 pt-4">
                    <Link
                        :href="route('service-requests.edit', sr.id)"
                        class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                    >
                        Continuer la demande
                    </Link>
                    <button
                        class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
                        @click="destroyDraft(sr.id)"
                    >
                        Supprimer
                    </button>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
