<?php
namespace App\Providers;

use App\Events\MessageSent;
use App\Events\MissionCompleted;
use App\Events\ProposalAccepted;
use App\Events\ProposalCreated;
use App\Events\ReviewCreated;
use App\Listeners\NotifyClientMissionCompleted;
use App\Listeners\NotifyClientOfNewProposal;
use App\Listeners\NotifyProviderOfNewReview;
use App\Listeners\NotifyProviderOfProposalAccepted;
use App\Listeners\NotifyRecipientOfNewMessage;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    /**
     * Mapping Event -> Listener(s).
     * Ajoute ici toute nouvelle notification automatique (section "Notifications"
     * du document de référence : jamais de création manuelle, toujours via Event).
     */
    protected $listen = [
        ProposalCreated::class => [
            NotifyClientOfNewProposal::class,
        ],
        ProposalAccepted::class => [
            NotifyProviderOfProposalAccepted::class,
        ],
        MissionCompleted::class => [
            NotifyClientMissionCompleted::class,
        ],
        MessageSent::class => [
            NotifyRecipientOfNewMessage::class,
        ],
        ReviewCreated::class => [
            NotifyProviderOfNewReview::class,
        ],
    ];

    public function boot(): void
    {
        //
    }
}
