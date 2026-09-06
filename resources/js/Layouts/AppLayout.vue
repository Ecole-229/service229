<script setup>
import { computed, ref } from 'vue';
import { Head, Link, usePage } from '@inertiajs/vue3';

defineProps({
    title: { type: String, default: '' },
});

const page = usePage();
const user = page.props.auth?.user;

const navItems = computed(() => {
    const items = [
        { label: 'Tableau de bord', route: 'dashboard' },
        { label: 'Nouvelle demande', route: 'service-requests.create' },
        { label: 'Mes demandes', route: 'service-requests.index' },
        { label: 'Mes missions', route: 'missions.index' },
        { label: 'Messagerie', route: 'conversations.index' },
        { label: 'Notifications', route: 'notifications.index' },
    ];

    if (user?.estPrestataire) {
        items.splice(3, 0, { label: 'Demandes disponibles', route: 'service-requests.browse' });
    }

    return items;
});

const sidebarOpen = ref(false);
</script>

<template>
    <Head :title="title" />

    <div class="min-h-screen bg-gray-50">
        <!-- Barre du haut (mobile) -->
        <div class="flex items-center justify-between border-b border-gray-200 bg-white px-4 py-3 md:hidden">
            <Link :href="route('dashboard')" class="text-lg font-bold text-brand">Service229</Link>
            <button @click="sidebarOpen = !sidebarOpen" class="text-gray-600" aria-label="Ouvrir le menu">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
            </button>
        </div>

        <div class="flex">
            <!-- Sidebar -->
            <aside
                class="fixed inset-y-0 left-0 z-30 w-64 transform border-r border-gray-200 bg-white transition-transform md:static md:translate-x-0"
                :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
            >
                <div class="hidden border-b border-gray-100 p-6 md:block">
                    <Link :href="route('dashboard')" class="text-xl font-bold text-brand">Service229</Link>
                </div>

                <nav class="flex flex-col gap-1 p-4">
                    <Link
                        v-for="item in navItems"
                        :key="item.route"
                        :href="route(item.route)"
                        class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 transition hover:bg-brand-light hover:text-brand"
                        :class="{ 'bg-brand-light text-brand': route().current(item.route + '*') }"
                    >
                        {{ item.label }}
                    </Link>
                </nav>

                <div class="absolute bottom-0 w-64 border-t border-gray-100 p-4">
                    <div class="mb-3 flex items-center gap-3">
                        <div class="flex h-9 w-9 items-center justify-center rounded-full bg-brand-light text-sm font-semibold text-brand">
                            {{ user?.name?.charAt(0) }}
                        </div>
                        <div class="min-w-0">
                            <p class="truncate text-sm font-medium text-gray-900">{{ user?.name }}</p>
                        </div>
                    </div>
                    <Link
                        :href="route('logout')"
                        method="post"
                        as="button"
                        class="w-full rounded-lg border border-gray-200 px-3 py-2 text-left text-sm text-gray-600 hover:bg-gray-50"
                    >
                        Se déconnecter
                    </Link>
                </div>
            </aside>

            <!-- Contenu -->
            <main class="min-h-screen flex-1 p-6 md:p-10">
                <slot />
            </main>
        </div>
    </div>
</template>
