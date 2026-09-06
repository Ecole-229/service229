<script setup>
import { Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    missions: { type: Object, required: true },
});

const statusLabels = {
    pending: { text: 'En attente', class: 'bg-gray-100 text-gray-600' },
    in_progress: { text: 'En cours', class: 'bg-blue-100 text-blue-700' },
    awaiting_confirmation: { text: 'À confirmer', class: 'bg-amber-100 text-amber-700' },
    completed: { text: 'Terminée', class: 'bg-green-100 text-green-700' },
    cancelled: { text: 'Annulée', class: 'bg-gray-100 text-gray-500' },
    disputed: { text: 'Litige', class: 'bg-red-100 text-red-700' },
};
</script>

<template>
    <AppLayout title="Mes missions">
        <h1 class="mb-6 text-2xl font-bold text-gray-900">Mes missions</h1>

        <div v-if="missions.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune mission pour le moment.</p>
        </div>

        <div v-else class="space-y-3">
            <Link
                v-for="mission in missions.data"
                :key="mission.id"
                :href="route('missions.show', mission.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-5 transition hover:border-brand hover:shadow-sm"
            >
                <div>
                    <h2 class="font-semibold text-gray-900">{{ mission.service_request?.title }}</h2>
                    <p class="mt-1 text-sm text-gray-500">
                        {{ mission.provider_profile?.user?.name ?? mission.client?.name }}
                    </p>
                </div>
                <span
                    class="shrink-0 rounded-full px-3 py-1 text-xs font-medium"
                    :class="statusLabels[mission.status]?.class"
                >
                    {{ statusLabels[mission.status]?.text ?? mission.status }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
