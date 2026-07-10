<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Enums\UserRole;
use App\Enums\Plan;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    // Mass-assignable, user-safe attributes only.
    // SECURITY: privilege fields (role, plan, is_active, manager_permissions)
    // are intentionally NOT fillable — they must be set explicitly via
    // authorized code paths (admin endpoints, invite flow) using forceFill(),
    // so unfiltered input can never escalate a user's role/plan.
    protected $fillable = [
        'name', 'email', 'phone', 'password', 'staff_position',
        'business_name', 'bio', 'avatar',
        'logo_url', 'signature_url',
        'bkash_number', 'bank_details',
        'public_booking_token',
        'totp_secret', 'totp_enabled',
        'currency_code', 'vat_enabled', 'vat_rate_pct', 'vat_label',
    ];

    // Privilege fields — never mass-assignable.
    protected $guarded = [
        'role', 'plan', 'is_active', 'manager_permissions',
    ];

    protected $hidden = ['password', 'remember_token', 'totp_secret'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_active_at' => 'datetime',
        'manager_permissions' => 'array',
        'totp_enabled' => 'boolean',
        'is_active' => 'boolean',
        'vat_enabled' => 'boolean',
        'vat_rate_pct' => 'decimal:2',
        'password' => 'hashed',
    ];

    public function events()
    {
        return $this->hasMany(Event::class, 'owner_id');
    }

    public function clients()
    {
        return $this->hasMany(Client::class, 'owner_id');
    }

    public function assignments()
    {
        return $this->hasMany(Assignment::class, 'user_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'recorded_by');
    }

    public function expenses()
    {
        return $this->hasMany(Expense::class, 'owner_id');
    }

    public function gearItems()
    {
        return $this->hasMany(GearItem::class, 'owner_id');
    }

    public function packages()
    {
        return $this->hasMany(Package::class, 'owner_id');
    }

    public function broadcasts()
    {
        return $this->hasMany(Broadcast::class, 'created_by');
    }

    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function supportTickets()
    {
        return $this->hasMany(SupportTicket::class);
    }

    public function loginActivities()
    {
        return $this->hasMany(LoginActivity::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'ADMIN';
    }

    public function isOwner(): bool
    {
        return in_array($this->role, ['OWNER', 'BOTH']);
    }

    /**
     * Resolves the id of the studio (owner account) this user's bookings,
     * clients, packages, etc. belong to.
     *
     * OWNER/BOTH accounts own their studio outright — their own id IS the
     * studio id. MANAGER/FREELANCER accounts are linked to a studio via
     * `manager_permissions.ownerId` (set by TeamController::attachToTeam
     * when they join via invite code / email invite); falls back to their
     * own id when unlinked so an unattached account still resolves to
     * itself rather than throwing.
     */
    public function studioId(): int
    {
        if ($this->isOwner()) {
            return (int) $this->id;
        }
        $linked = is_array($this->manager_permissions)
            ? ($this->manager_permissions['ownerId'] ?? null)
            : null;
        return $linked !== null ? (int) $linked : (int) $this->id;
    }

    public function isPro(): bool
    {
        return $this->plan === 'PRO';
    }
}
