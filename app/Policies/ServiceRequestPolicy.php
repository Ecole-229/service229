<?php
namespace App\Policies;

use App\Models\ServiceRequest;
use App\Models\User;

class ServiceRequestPolicy
{
    public function view(User $user, ServiceRequest $serviceRequest): bool
    {
        return $serviceRequest->client_id === $user->id;
    }

    public function cancel(User $user, ServiceRequest $serviceRequest): bool
    {
        return $serviceRequest->client_id === $user->id
            && $serviceRequest->status !== ServiceRequest::STATUS_CLOSED;
    }
}
