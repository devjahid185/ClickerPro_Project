<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

// Proves suspension ends an ALREADY-LOGGED-IN session immediately, which was
// the bug: is_active=false only blocked fresh logins while existing tokens
// kept working. Now setSuspend revokes tokens and the `active` middleware
// rejects any that survive.
class SuspendUserTest extends TestCase
{
    use RefreshDatabase;

    public function test_suspending_revokes_the_users_tokens(): void
    {
        $admin = User::factory()->create(['role' => 'ADMIN']);
        $admin->forceFill(['is_active' => true])->save();
        $victim = User::factory()->create(['role' => 'OWNER']);
        $victim->forceFill(['is_active' => true])->save();

        // Victim has a live session token.
        $token = $victim->createToken('auth_token')->plainTextToken;
        $this->assertCount(1, $victim->tokens);

        // Admin suspends them.
        Sanctum::actingAs($admin);
        $this->patchJson("/api/admin/users/{$victim->id}/suspend", ['suspended' => true])
            ->assertOk();

        $victim->refresh();
        $this->assertFalse((bool) $victim->is_active);
        $this->assertCount(0, $victim->tokens()->get(), 'tokens should be purged');
    }

    public function test_suspended_user_is_blocked_on_authenticated_requests(): void
    {
        // A suspended user who somehow still presents a token must be rejected
        // by the `active` middleware with a suspended-tagged 403.
        $victim = User::factory()->create(['role' => 'OWNER']);
        $victim->forceFill(['is_active' => false])->save();
        Sanctum::actingAs($victim);

        $this->getJson('/api/bookings')
            ->assertStatus(403)
            ->assertJsonPath('code', 'ACCOUNT_SUSPENDED');
    }

    public function test_active_user_passes_through_normally(): void
    {
        $ok = User::factory()->create(['role' => 'OWNER']);
        $ok->forceFill(['is_active' => true])->save();
        Sanctum::actingAs($ok);

        // An authenticated route proves the middleware lets active users
        // through — a 200 list, never the suspend 403.
        $this->getJson('/api/bookings')->assertOk();
    }
}
