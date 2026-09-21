<?php
namespace App\Services\Marketplace;

use App\Models\ServiceRequest;
use App\Models\ServiceRequestPhoto;
use App\Models\User;
use Illuminate\Http\UploadedFile;

class ServiceRequestService
{
    /**
     * Crée une demande — couvre les deux modes (contact direct / besoin
     * ouvert) et les deux statuts (brouillon / publiée).
     *
     * @param  UploadedFile[]  $photos
     */
    public function create(User $client, array $data, array $photos, bool $asDraft): ServiceRequest
    {
        $isDirectContact = ! empty($data['provider_profile_id']);

        $status = match (true) {
            $isDirectContact => ServiceRequest::STATUS_ASSIGNED,
            $asDraft => ServiceRequest::STATUS_DRAFT,
            default => ServiceRequest::STATUS_PUBLISHED,
        };

        $serviceRequest = ServiceRequest::create([
            ...$data,
            'client_id' => $client->id,
            'status' => $status,
        ]);

        $this->attachPhotos($serviceRequest, $photos);

        return $serviceRequest;
    }

    /**
     * Met à jour un brouillon (seul statut modifiable librement).
     *
     * @param  UploadedFile[]  $photos
     */
    public function update(ServiceRequest $serviceRequest, array $data, array $photos, bool $asDraft): ServiceRequest
    {
        $status = $asDraft ? ServiceRequest::STATUS_DRAFT : ServiceRequest::STATUS_PUBLISHED;

        $serviceRequest->update([...$data, 'status' => $status]);

        $this->attachPhotos($serviceRequest, $photos);

        return $serviceRequest->fresh();
    }

    /**
     * Suppression définitive — réservée aux brouillons (voir Policy).
     */
    public function delete(ServiceRequest $serviceRequest): void
    {
        foreach ($serviceRequest->photos as $photo) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($photo->chemin_fichier);
        }

        $serviceRequest->delete();
    }

    public function cancel(ServiceRequest $serviceRequest): void
    {
        $serviceRequest->update(['status' => ServiceRequest::STATUS_CANCELLED]);
    }

    /**
     * @param  UploadedFile[]  $photos
     */
    private function attachPhotos(ServiceRequest $serviceRequest, array $photos): void
    {
        foreach ($photos as $photo) {
            $path = $photo->store('service-requests', 'public');

            ServiceRequestPhoto::create([
                'service_request_id' => $serviceRequest->id,
                'chemin_fichier' => $path,
            ]);
        }
    }
}
