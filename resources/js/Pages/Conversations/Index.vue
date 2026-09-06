<script setup>
import { Link, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    conversations: { type: Array, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);

function otherPartyName(conversation) {
    const isClient = conversation.client_id === currentUserId.value;
    return isClient
        ? conversation.provider_profile?.user?.name
        : conversation.client?.name;
}
</script>

<template>
    <AppLayout title="Messagerie">
        <h1 class="mb-6 text-2xl font-bold text-gray-900">Messagerie</h1>

        <div v-if="conversations.length === 0" class="rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <p class="text-gray-500">Aucune conversation pour le moment.</p>
        </div>

        <div v-else class="space-y-2">
            <Link
                v-for="conversation in conversations"
                :key="conversation.id"
                :href="route('conversations.show', conversation.id)"
                class="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4 transition hover:border-brand hover:shadow-sm"
            >
                <div class="flex items-center gap-3">
                    <div class="flex h-10 w-10 items-center justify-center rounded-full bg-brand-light text-sm font-semibold text-brand">
                        {{ otherPartyName(conversation)?.charAt(0) }}
                    </div>
                    <div>
                        <p class="font-semibold text-gray-900">{{ otherPartyName(conversation) }}</p>
                        <p v-if="conversation.service_request" class="text-sm text-gray-500">
                            {{ conversation.service_request.title }}
                        </p>
                    </div>
                </div>
                <span
                    v-if="conversation.unread_count > 0"
                    class="rounded-full bg-accent px-2 py-0.5 text-xs font-semibold text-white"
                >
                    {{ conversation.unread_count }}
                </span>
            </Link>
        </div>
    </AppLayout>
</template>
