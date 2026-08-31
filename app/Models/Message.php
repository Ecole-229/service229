<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_id',
        'content',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    // --- Relations ---

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    // Le client OU le prestataire — tous deux stockés dans users
    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    // --- Helpers ---

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }
}
