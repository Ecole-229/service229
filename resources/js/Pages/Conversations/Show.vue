<script setup>
import { useForm, usePage } from '@inertiajs/vue3';
import { computed, nextTick, onMounted, ref } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    conversation: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);

const isClient = computed(() => props.conversation.client_id === currentUserId.value);
const otherPartyName = computed(() =>
    isClient.value ? props.conversation.provider_profile?.user?.name : props.conversation.client?.name
);

const form = useForm({ content: '' });
const messagesEnd = ref(null);

function send() {
    if (!form.content.trim()) return;
    form.post(route('messages.store', props.conversation.id), {
        preserveScroll: true,
        onSuccess: () => {
            form.reset();
            nextTick(() => messagesEnd.value?.scrollIntoView());
        },
    });
}

onMounted(() => messagesEnd.value?.scrollIntoView());
</script>

<template>
    <AppLayout :title="otherPartyName">
        <div class="mx-auto flex h-[calc(100vh-8rem)] max-w-2xl flex-col">
            <h1 class="border-b border-gray-200 pb-4 text-lg font-semibold text-gray-900">
                {{ otherPartyName }}
                <span v-if="conversation.service_request" class="block text-sm font-normal text-gray-500">
                    {{ conversation.service_request.title }}
                </span>
            </h1>

            <div class="flex-1 space-y-3 overflow-y-auto py-4">
                <div
                    v-for="message in conversation.messages"
                    :key="message.id"
                    class="flex"
                    :class="message.sender_id === currentUserId ? 'justify-end' : 'justify-start'"
                >
                    <div
                        class="max-w-xs rounded-2xl px-4 py-2 text-sm"
                        :class="message.sender_id === currentUserId
                            ? 'bg-brand text-white'
                            : 'bg-gray-100 text-gray-800'"
                    >
                        {{ message.content }}
                    </div>
                </div>
                <div ref="messagesEnd"></div>
            </div>

            <form class="flex gap-2 border-t border-gray-200 pt-4" @submit.prevent="send">
                <input
                    v-model="form.content"
                    type="text"
                    placeholder="Écrire un message..."
                    class="flex-1 rounded-full border-gray-300 focus:border-brand focus:ring-brand"
                />
                <button
                    type="submit"
                    :disabled="form.processing || !form.content.trim()"
                    class="rounded-full bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                >
                    Envoyer
                </button>
            </form>
        </div>
    </AppLayout>
</template>
