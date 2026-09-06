<?php
namespace App\Policies;

use App\Models\ServiceRequest;
use App\Models\User;

class ServiceRequestPolicy
{
    public function view(User $user, ServiceRequest $serviceRequest): bool
    {
        // Le client propriétaire peut toujours voir sa demande
        if ($serviceRequest->client_id === $user->id) {
            return true;
        }

        // Un prestataire peut voir le détail d'une demande PUBLIÉE (pour
        // pouvoir y répondre) ou de celle sur laquelle il a déjà un devis
        if ($user->estPrestataire) {
            if ($serviceRequest->status === ServiceRequest::STATUS_PUBLISHED) {
                return true;
            }

            $providerProfile = \App\Models\ProviderProfile::where('user_id', $user->id)->first();

            return $providerProfile && $serviceRequest->proposals()
                ->where('provider_profile_id', $providerProfile->id)
                ->exists();
        }

        return false;
    }

    public function cancel(User $user, ServiceRequest $serviceRequest): bool
    {
        return $serviceRequest->client_id === $user->id
            && $serviceRequest->status !== ServiceRequest::STATUS_CLOSED;
    }
}
