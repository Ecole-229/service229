<?php
namespace App\Providers;

use App\Models\Conversation;
use App\Models\Mission;
use App\Models\Proposal;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Policies\ConversationPolicy;
use App\Policies\MissionPolicy;
use App\Policies\ProposalPolicy;
use App\Policies\ReviewPolicy;
use App\Policies\ServiceRequestPolicy;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [
        ServiceRequest::class => ServiceRequestPolicy::class,
        Proposal::class => ProposalPolicy::class,
        Mission::class => MissionPolicy::class,
        Review::class => ReviewPolicy::class,
        Conversation::class => ConversationPolicy::class,
    ];

    public function boot(): void
    {
        $this->registerPolicies();
    }
}
