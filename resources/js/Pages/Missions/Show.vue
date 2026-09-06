<script setup>
import { router, useForm, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    mission: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);
const isProvider = computed(() => props.mission.provider_profile?.user?.id === currentUserId.value);
const isClient = computed(() => props.mission.client?.id === currentUserId.value);

const steps = ['pending', 'in_progress', 'awaiting_confirmation', 'completed'];
const currentStepIndex = computed(() => steps.indexOf(props.mission.status));

function startMission() {
    router.patch(route('missions.start', props.mission.id));
}
function markAwaitingConfirmation() {
    router.patch(route('missions.mark-awaiting-confirmation', props.mission.id));
}
function confirmCompletion() {
    router.patch(route('missions.confirm-completion', props.mission.id));
}
function markPaid() {
    router.patch(route('missions.mark-paid', props.mission.id));
}

function contactOtherParty() {
    if (isClient.value) {
        router.post(route('conversations.start-or-find'), {
            provider_profile_id: props.mission.provider_profile_id,
        });
    } else {
        router.post(route('conversations.start-or-find'), {
            client_id: props.mission.client_id,
        });
    }
}

const reviewForm = useForm({ note: 5, commentaire: '' });

function submitReview() {
    reviewForm.post(route('reviews.store', props.mission.id));
}
</script>

<template>
    <AppLayout :title="mission.service_request?.title">
        <div class="mx-auto max-w-2xl">
            <h1 class="text-2xl font-bold text-gray-900">{{ mission.service_request?.title }}</h1>
            <p class="mt-1 text-sm text-gray-500">
                {{ isClient ? mission.provider_profile?.user?.name : mission.client?.name }}
            </p>
            <button
                class="mt-2 text-sm font-medium text-brand hover:underline"
                @click="contactOtherParty"
            >
                💬 Envoyer un message
            </button>

            <!-- Stepper de statut -->
            <div v-if="mission.status !== 'cancelled' && mission.status !== 'disputed'" class="mt-8 flex items-center">
                <template v-for="(step, index) in steps" :key="step">
                    <div class="flex flex-col items-center">
                        <div
                            class="flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold"
                            :class="index <= currentStepIndex ? 'bg-brand text-white' : 'bg-gray-200 text-gray-500'"
                        >
                            {{ index + 1 }}
                        </div>
                    </div>
                    <div
                        v-if="index < steps.length - 1"
                        class="mx-1 h-0.5 flex-1"
                        :class="index < currentStepIndex ? 'bg-brand' : 'bg-gray-200'"
                    ></div>
                </template>
            </div>
            <span
                v-else
                class="mt-6 inline-block rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-700"
            >
                {{ mission.status === 'cancelled' ? 'Mission annulée' : 'En litige' }}
            </span>

            <!-- Actions selon rôle et statut -->
            <div class="mt-8 space-y-3">
                <button
                    v-if="isProvider && mission.status === 'pending'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="startMission"
                >
                    Démarrer la mission
                </button>

                <button
                    v-if="isProvider && mission.status === 'in_progress'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="markAwaitingConfirmation"
                >
                    Signaler le travail comme terminé
                </button>

                <button
                    v-if="isClient && mission.status === 'awaiting_confirmation'"
                    class="w-full rounded-lg bg-accent px-4 py-3 font-semibold text-white hover:bg-accent-dark"
                    @click="confirmCompletion"
                >
                    Confirmer que le travail est terminé
                </button>

                <button
                    v-if="isClient && !mission.paiementEffectue && mission.status === 'completed'"
                    class="w-full rounded-lg border border-brand px-4 py-3 font-semibold text-brand hover:bg-brand-light"
                    @click="markPaid"
                >
                    Marquer comme payé
                </button>

                <p v-if="mission.paiementEffectue" class="text-center text-sm font-medium text-green-700">
                    ✓ Paiement effectué
                </p>
            </div>

            <!-- Avis -->
            <div v-if="mission.status === 'completed' && isClient && !mission.review" class="mt-8 rounded-xl border border-gray-200 bg-white p-5">
                <h2 class="font-semibold text-gray-900">Laisser un avis</h2>
                <form class="mt-4 space-y-4" @submit.prevent="submitReview">
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Note</label>
                        <div class="mt-1 flex gap-1">
                            <button
                                v-for="n in 5"
                                :key="n"
                                type="button"
                                class="text-2xl"
                                :class="n <= reviewForm.note ? 'text-accent' : 'text-gray-300'"
                                @click="reviewForm.note = n"
                            >
                                ★
                            </button>
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Commentaire (optionnel)</label>
                        <textarea
                            v-model="reviewForm.commentaire"
                            rows="3"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        ></textarea>
                    </div>
                    <button
                        type="submit"
                        :disabled="reviewForm.processing"
                        class="rounded-lg bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                    >
                        Publier l'avis
                    </button>
                </form>
            </div>

            <div v-else-if="mission.review" class="mt-8 rounded-xl border border-gray-200 bg-white p-5">
                <p class="text-sm font-medium text-gray-900">Votre avis : {{ mission.review.note }}/5</p>
                <p v-if="mission.review.commentaire" class="mt-1 text-sm text-gray-600">{{ mission.review.commentaire }}</p>
            </div>
        </div>
    </AppLayout>
</template>
