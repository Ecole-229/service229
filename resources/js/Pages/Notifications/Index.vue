<script setup>
import { Link, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

defineProps({
    notifications: { type: Object, required: true },
});

function markAllAsRead() {
    router.patch(route('notifications.mark-all-as-read'));
}

function openNotification(notification) {
    if (!notification.lu) {
        router.patch(route('notifications.mark-as-read', notification.id));
    }
    if (notification.lien_associe) {
        router.visit(notification.lien_associe);
    }
}
</script>

<template>
    <AppLayout title="Notifications">
        <div class="mb-6 flex items-center justify-between">
            <h1 class="text-2xl font-bold text-gray-900">Notifications</h1>
            <button class="text-sm font-medium text-brand hover:underline" @click="markAllAsRead">
                Tout marquer comme lu
            </button>
        </div>

        <div v-if="notifications.data.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune notification pour le moment.</p>
        </div>

        <div v-else class="space-y-2">
            <button
                v-for="notification in notifications.data"
                :key="notification.id"
                class="flex w-full items-start gap-3 rounded-xl border p-4 text-left transition hover:border-brand"
                :class="notification.lu ? 'border-gray-200 bg-white' : 'border-brand-light bg-brand-light/40'"
                @click="openNotification(notification)"
            >
                <span
                    v-if="!notification.lu"
                    class="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-accent"
                ></span>
                <span v-else class="mt-1.5 h-2 w-2 shrink-0"></span>
                <span class="text-sm text-gray-700">{{ notification.message }}</span>
            </button>
        </div>
    </AppLayout>
</template>
