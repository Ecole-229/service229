<script setup>
import { Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    serviceRequests: { type: Object, required: true },
});
</script>

<template>
    <AppLayout title="Demandes disponibles">
        <h1 class="mb-1 text-2xl font-bold text-gray-900">Demandes disponibles</h1>
        <p class="mb-6 text-sm text-gray-500">Demandes correspondant à vos services et zones déclarés.</p>

        <div v-if="serviceRequests.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune demande disponible pour le moment.</p>
        </div>

        <div v-else class="space-y-3">
            <Link
                v-for="sr in serviceRequests.data"
                :key="sr.id"
                :href="route('service-requests.show', sr.id)"
                class="block rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h2 class="font-semibold text-gray-900">{{ sr.title }}</h2>
                        <p class="mt-1 text-sm text-gray-500">
                            {{ sr.service_category?.name }} · {{ sr.zone?.name }}
                        </p>
                        <p v-if="sr.budget_estime" class="mt-2 text-sm font-semibold text-brand">
                            Budget : {{ sr.budget_estime }} FCFA
                        </p>
                        <p v-else class="mt-2 text-sm text-gray-400">Budget à discuter</p>
                    </div>
                    <span class="shrink-0 rounded-full bg-brand-light px-3 py-1 text-xs font-medium text-brand">
                        Nouveau
                    </span>
                </div>
            </Link>
        </div>
    </AppLayout>
</template>
