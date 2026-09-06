<script setup>
import { useForm, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    serviceRequest: { type: Object, required: true },
    serviceCategories: { type: Array, default: () => [] },
    zones: { type: Array, default: () => [] },
});

const form = useForm({
    service_category_id: props.serviceRequest.service_category_id ?? '',
    zone_id: props.serviceRequest.zone_id ?? '',
    title: props.serviceRequest.title ?? '',
    description: props.serviceRequest.description ?? '',
    budget_estime: props.serviceRequest.budget_estime ?? '',
    date_intervention: props.serviceRequest.date_intervention ?? '',
    photos: [],
    as_draft: false,
});

function onPhotosChange(event) {
    form.photos = Array.from(event.target.files);
}

function submit(asDraft) {
    form.as_draft = asDraft;
    form.transform((data) => ({ ...data, _method: 'put' })).post(
        route('service-requests.update', props.serviceRequest.id),
        { forceFormData: true }
    );
}

function destroyDraft() {
    if (!confirm('Supprimer définitivement ce brouillon ? Cette action est irréversible.')) return;
    router.delete(route('service-requests.destroy', props.serviceRequest.id));
}
</script>

<template>
    <AppLayout title="Continuer le brouillon">
        <div class="mx-auto max-w-3xl">
            <div class="flex items-center justify-between">
                <h1 class="text-2xl font-bold text-gray-900">Continuer votre brouillon</h1>
                <button class="text-sm font-medium text-red-600 hover:underline" @click="destroyDraft">
                    Supprimer ce brouillon
                </button>
            </div>

            <form class="mt-8 space-y-6" @submit.prevent>
                <div>
                    <label for="service_category_id" class="block text-sm font-medium text-gray-700">Service</label>
                    <select
                        id="service_category_id"
                        v-model="form.service_category_id"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    >
                        <option value="" disabled>Choisissez un service</option>
                        <option v-for="category in serviceCategories" :key="category.id" :value="category.id">
                            {{ category.name }}
                        </option>
                    </select>
                    <p v-if="form.errors.service_category_id" class="mt-1 text-sm text-red-600">
                        {{ form.errors.service_category_id }}
                    </p>
                </div>

                <div>
                    <label for="title" class="block text-sm font-medium text-gray-700">Titre de la demande</label>
                    <input
                        id="title"
                        v-model="form.title"
                        type="text"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    />
                    <p v-if="form.errors.title" class="mt-1 text-sm text-red-600">{{ form.errors.title }}</p>
                </div>

                <div>
                    <label for="description" class="block text-sm font-medium text-gray-700">Description détaillée</label>
                    <textarea
                        id="description"
                        v-model="form.description"
                        rows="4"
                        class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                    ></textarea>
                    <p v-if="form.errors.description" class="mt-1 text-sm text-red-600">{{ form.errors.description }}</p>
                </div>

                <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <div>
                        <label for="zone_id" class="block text-sm font-medium text-gray-700">Lieu</label>
                        <select
                            id="zone_id"
                            v-model="form.zone_id"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        >
                            <option value="" disabled>Choisissez une zone</option>
                            <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
                        </select>
                        <p v-if="form.errors.zone_id" class="mt-1 text-sm text-red-600">{{ form.errors.zone_id }}</p>
                    </div>

                    <div>
                        <label for="date_intervention" class="block text-sm font-medium text-gray-700">
                            Date d'intervention souhaitée
                        </label>
                        <input
                            id="date_intervention"
                            v-model="form.date_intervention"
                            type="date"
                            class="mt-1 block w-full rounded-lg border-gray-300 focus:border-brand focus:ring-brand"
                        />
                        <p v-if="form.errors.date_intervention" class="mt-1 text-sm text-red-600">
                            {{ form.errors.date_intervention }}
                        </p>
                    </div>
                </div>

                <div>
                    <label for="budget_estime" class="block text-sm font-medium text-gray-700">
                        Budget estimé <span class="font-normal text-gray-400">(Optionnel)</span>
                    </label>
                    <div class="relative mt-1">
                        <input
                            id="budget_estime"
                            v-model="form.budget_estime"
                            type="number"
                            min="0"
                            class="block w-full rounded-lg border-gray-300 pr-16 focus:border-brand focus:ring-brand"
                        />
                        <span class="absolute inset-y-0 right-3 flex items-center text-sm text-gray-400">FCFA</span>
                    </div>
                    <p v-if="form.errors.budget_estime" class="mt-1 text-sm text-red-600">{{ form.errors.budget_estime }}</p>
                </div>

                <div v-if="serviceRequest.photos?.length" class="grid grid-cols-4 gap-3">
                    <img
                        v-for="photo in serviceRequest.photos"
                        :key="photo.id"
                        :src="photo.url"
                        class="h-20 w-full rounded-lg object-cover"
                        alt="Photo déjà ajoutée"
                    />
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700">
                        Ajouter d'autres photos <span class="font-normal text-gray-400">(Optionnel)</span>
                    </label>
                    <label
                        for="photos"
                        class="mt-1 flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-gray-300 px-6 py-10 text-center hover:border-brand"
                    >
                        <span class="font-semibold text-brand">Ajouter des photos de votre besoin</span>
                        <span class="mt-1 text-xs text-gray-400">JPG, PNG jusqu'à 5MB — 5 photos maximum</span>
                        <input id="photos" type="file" accept="image/png,image/jpeg" multiple class="hidden" @change="onPhotosChange" />
                    </label>
                    <p v-if="form.photos.length" class="mt-2 text-sm text-gray-500">
                        {{ form.photos.length }} nouvelle(s) photo(s) sélectionnée(s)
                    </p>
                </div>

                <div class="flex flex-col gap-3 border-t border-gray-100 pt-6 sm:flex-row">
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg bg-accent px-6 py-3 text-center font-semibold text-white transition hover:bg-accent-dark disabled:opacity-50"
                        @click="submit(false)"
                    >
                        Publier ma demande
                    </button>
                    <button
                        type="button"
                        :disabled="form.processing"
                        class="flex-1 rounded-lg border border-brand px-6 py-3 text-center font-semibold text-brand transition hover:bg-brand-light disabled:opacity-50"
                        @click="submit(true)"
                    >
                        Continuer plus tard (garder en brouillon)
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
