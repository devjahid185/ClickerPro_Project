<?php

namespace Tests\Feature;

use App\Models\CrashReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

// End-to-end proof of the crash/bug pipeline: a client (mobile/web/landing)
// POSTs a crash, the admin console lists it, resolves it, sees the count in
// stats, and deletes it. Non-admins must be blocked from the admin endpoints.
class CrashReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_any_client_can_post_a_crash_report_unauthenticated(): void
    {
        $res = $this->postJson('/api/crash-reports', [
            'error' => 'RangeError: index out of bounds',
            'stackTrace' => "#0 main.dart:42\n#1 widget.dart:10",
            'platform' => 'landing',
            'breadcrumbs' => [
                ['message' => 'opened /pricing', 'timestamp' => now()->toIso8601String()],
            ],
        ]);

        $res->assertCreated();
        $this->assertDatabaseHas('crash_reports', [
            'error' => 'RangeError: index out of bounds',
            'platform' => 'landing',
            'resolved_at' => null,
        ]);
    }

    public function test_admin_can_list_resolve_and_delete_reports(): void
    {
        $admin = User::factory()->create(['role' => 'ADMIN']);
        $reporter = User::factory()->create(['role' => 'OWNER', 'name' => 'Rahim']);

        $report = CrashReport::create([
            'user_id' => $reporter->id,
            'user_role' => 'OWNER',
            'error' => 'Null check operator used on a null value',
            'stack_trace' => '#0 booking_list.dart:88',
            'platform' => 'android',
            'app_version' => '3.8.0',
        ]);

        Sanctum::actingAs($admin);

        // List — newest/unresolved first, with the reporter joined in.
        $list = $this->getJson('/api/admin/crash-reports');
        $list->assertOk()
            ->assertJsonPath('data.0.error', 'Null check operator used on a null value')
            ->assertJsonPath('data.0.platform', 'android')
            ->assertJsonPath('data.0.userName', 'Rahim')
            ->assertJsonPath('data.0.resolved', false)
            ->assertJsonPath('unresolved', 1);

        // Resolve — stamps resolved_at and flips the flag.
        $this->patchJson("/api/admin/crash-reports/{$report->id}/resolve", ['resolved' => true])
            ->assertOk()
            ->assertJsonPath('data.resolved', true);
        $this->assertNotNull($report->fresh()->resolved_at);

        // Reopen — clears it.
        $this->patchJson("/api/admin/crash-reports/{$report->id}/resolve", ['resolved' => false])
            ->assertOk()
            ->assertJsonPath('data.resolved', false);
        $this->assertNull($report->fresh()->resolved_at);

        // Delete.
        $this->deleteJson("/api/admin/crash-reports/{$report->id}")->assertOk();
        $this->assertDatabaseMissing('crash_reports', ['id' => $report->id]);
    }

    public function test_admin_stats_include_unresolved_crash_count(): void
    {
        $admin = User::factory()->create(['role' => 'ADMIN']);
        CrashReport::create(['error' => 'A', 'platform' => 'web']);
        CrashReport::create(['error' => 'B', 'platform' => 'android', 'resolved_at' => now()]);

        Sanctum::actingAs($admin);

        $this->getJson('/api/admin/stats')
            ->assertOk()
            ->assertJsonPath('data.unresolvedCrashes', 1);
    }

    public function test_non_admin_cannot_read_crash_reports(): void
    {
        $owner = User::factory()->create(['role' => 'OWNER']);
        Sanctum::actingAs($owner);

        $this->getJson('/api/admin/crash-reports')->assertForbidden();
    }
}
