<script setup>
import { router, useForm, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    serviceRequest: { type: Object, required: true },
});

const page = usePage();
const currentUserId = computed(() => page.props.auth?.user?.id);
const isClient = computed(() => props.serviceRequest.client_id === currentUserId.value);
const isProvider = computed(() => page.props.auth?.user?.estPrestataire && !isClient.value);

const myProposal = computed(() =>
    props.serviceRequest.proposals?.find((p) => p.provider_profile?.user?.id === currentUserId.value)
);

const canCancel = computed(() =>
    isClient.value && !['closed', 'cancelled'].includes(props.serviceRequest.status)
);

// Prestataire à contacter côté client : celui de la demande (Mode 1) ou celui
// dont le devis est accepté (Mode 2)
const contactableProviderProfileId = computed(() => {
    if (props.serviceRequest.provider_profile_id) return props.serviceRequest.provider_profile_id;
    const accepted = props.serviceRequest.proposals?.find((p) => p.status === 'accepted');
    return accepted?.provider_profile_id ?? null;
});

function contactProvider() {
    router.post(route('conversations.start-or-find'), {
        provider_profile_id: contactableProviderProfileId.value,
    });
}

function contactClient() {
    router.post(route('conversations.start-or-find'), {
        client_id: props.serviceRequest.client_id,
    });
}

function acceptProposal(proposalId) {
    if (!confirm('Accepter ce devis ? Les autres devis en attente seront automatiquement refusés.')) return;
    router.patch(route('proposals.accept', proposalId));
}

function rejectProposal(proposalId) {
    router.patch(route('proposals.reject', proposalId));
}

function cancelRequest() {
    if (!confirm('Annuler cette demande ?')) return;
    router.patch(route('service-requests.cancel', props.serviceRequest.id));
}

const proposalForm = useForm({
    montant: '',
    delai: '',
    description: '',
});

function submitProposal() {
    proposalForm.post(route('proposals.store', props.serviceRequest.id));
}
</script>

<template>
    <AppLayout :title="serviceRequest.title">
        <div class="mx-auto max-w-3xl">
            <div class="flex items-start justify-between">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">{{ serviceRequest.title }}</h1>
                    <p class="mt-1 text-sm text-gray-500">
                        {{ serviceRequest.service_category?.name }} · {{ serviceRequest.zone?.name }}
                        <span v-if="serviceRequest.budget_estime"> · Budget : {{ serviceRequest.budget_estime }} FCFA</span>
                    </p>
                </div>
                <button
                    v-if="canCancel"
                    class="shrink-0 text-sm font-medium text-red-600 hover:underline"
                    @click="cancelRequest"
                >
                    Annuler la demande
                </button>
            </div>

            <div v-if="serviceRequest.description" class="mt-4 rounded-xl bg-white p-5 text-gray-700">
                {{ serviceRequest.description }}
            </div>

            <!-- Contact -->
            <div class="mt-4 flex gap-3">
                <button
                    v-if="isClient && contactableProviderProfileId"
                    class="rounded-lg border border-brand px-4 py-2 text-sm font-semibold text-brand hover:bg-brand-light"
                    @click="contactProvider"
                >
                    💬 Envoyer un message au prestataire
                </button>
                <button
                    v-if="isProvider"
                    class="rounded-lg border border-brand px-4 py-2 text-sm font-semibold text-brand hover:bg-brand-light"
                    @click="contactClient"
                >
                    💬 Envoyer un message au client
                </button>
            </div>

            <div v-if="serviceRequest.photos?.length" class="mt-4 grid grid-cols-3 gap-3">
                <img
                    v-for="photo in serviceRequest.photos"
                    :key="photo.id"
                    :src="photo.url"
                    class="h-24 w-full rounded-lg object-cover"
                    alt="Photo de la demande"
                />
            </div>

            <!-- Formulaire de devis (prestataire uniquement, s'il n'a pas déjà répondu) -->
            <div
                v-if="isProvider && serviceRequest.status === 'published' && !myProposal"
                class="mt-8 rounded-xl border border-gray-200 bg-white p-5"
            >
                <h2 class="text-lg font-semibold text-gray-900">Envoyer un devis</h2>
                <form class="mt-4 space-y-4" @submit.prevent="submitProposal">
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Montant (FCFA)</label>
                            <input
                                v-model="proposalForm.montant"
                                type="number"
                                min="0"
                                class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                            />
                            <p v-if="proposalForm.errors.montant" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.montant }}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Délai</label>
                            <input
                                v-model="proposalForm.delai"
                                type="text"
                                placeholder="Ex : 3 jours"
                                class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                            />
                            <p v-if="proposalForm.errors.delai" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.delai }}</p>
                        </div>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Description de votre proposition</label>
                        <textarea
                            v-model="proposalForm.description"
                            rows="3"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        ></textarea>
                        <p v-if="proposalForm.errors.description" class="mt-1 text-sm text-red-600">{{ proposalForm.errors.description }}</p>
                    </div>
                    <button
                        type="submit"
                        :disabled="proposalForm.processing"
                        class="rounded-lg bg-accent px-5 py-2 text-sm font-semibold text-white hover:bg-accent-dark disabled:opacity-50"
                    >
                        Envoyer le devis
                    </button>
                </form>
            </div>

            <p v-else-if="isProvider && myProposal" class="mt-8 text-sm text-gray-500">
                Vous avez déjà envoyé un devis pour cette demande ({{ myProposal.montant }} FCFA — statut : {{ myProposal.status }}).
            </p>

            <!-- Devis reçus (client uniquement) -->
            <div v-if="isClient" class="mt-8">
                <h2 class="text-lg font-semibold text-gray-900">
                    Devis reçus <span class="text-gray-400">({{ serviceRequest.proposals?.length ?? 0 }})</span>
                </h2>

                <p v-if="!serviceRequest.proposals?.length" class="mt-3 text-sm text-gray-500">
                    Aucun devis reçu pour le moment.
                </p>

                <div v-else class="mt-4 space-y-4">
                    <div
                        v-for="proposal in serviceRequest.proposals"
                        :key="proposal.id"
                        class="rounded-xl border border-gray-200 bg-white p-5"
                    >
                        <div class="flex items-start justify-between">
                            <div>
                                <p class="font-semibold text-gray-900">
                                    {{ proposal.provider_profile?.user?.name ?? 'Prestataire' }}
                                </p>
                                <p class="mt-1 text-sm text-gray-500">Délai : {{ proposal.delai }}</p>
                                <p class="mt-2 text-sm text-gray-700">{{ proposal.description }}</p>
                            </div>
                            <p class="shrink-0 text-lg font-bold text-brand">{{ proposal.montant }} FCFA</p>
                        </div>

                        <div v-if="proposal.status === 'pending'" class="mt-4 flex gap-3">
                            <button
                                class="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-white hover:bg-accent-dark"
                                @click="acceptProposal(proposal.id)"
                            >
                                Accepter ce devis
                            </button>
                            <button
                                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
                                @click="rejectProposal(proposal.id)"
                            >
                                Refuser
                            </button>
                        </div>
                        <span
                            v-else
                            class="mt-4 inline-block rounded-full px-3 py-1 text-xs font-medium"
                            :class="{
                                'bg-brand-light text-brand': proposal.status === 'accepted',
                                'bg-gray-100 text-gray-500': proposal.status !== 'accepted',
                            }"
                        >
                            {{ proposal.status === 'accepted' ? 'Accepté' : 'Refusé' }}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
