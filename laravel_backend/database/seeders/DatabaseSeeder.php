<?php

namespace Database\Seeders;

use App\Models\Broadcast;
use App\Models\FeatureFlag;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user. role/plan/is_active are guarded fields, so set them via
        // forceFill after the safe attributes.
        $admin = User::updateOrCreate(
            ['email' => 'admin@clickerpro.app'],
            [
                'name' => 'ClickerPro Admin',
                'email' => 'admin@clickerpro.app',
                'password' => Hash::make('Admin@1234'),
                'public_booking_token' => Str::uuid(),
            ]
        );
        $admin->forceFill(['role' => 'ADMIN', 'plan' => 'PRO', 'is_active' => true])->save();

        // Test owner
        $owner = User::updateOrCreate(
            ['email' => 'owner@test.com'],
            [
                'name' => 'Test Owner',
                'email' => 'owner@test.com',
                'password' => Hash::make('Test@1234'),
                'business_name' => 'Test Studio',
                'public_booking_token' => Str::uuid(),
            ]
        );
        $owner->forceFill(['role' => 'OWNER', 'plan' => 'FREE', 'is_active' => true])->save();

        // Feature flags
        $flags = [
            ['key' => 'chat', 'label' => 'Team Chat', 'requires_pro' => false, 'is_enabled' => true],
            ['key' => 'reports', 'label' => 'Reports', 'requires_pro' => false, 'is_enabled' => true],
            ['key' => 'gear', 'label' => 'Gear Inventory', 'requires_pro' => false, 'is_enabled' => true],
        ];

        foreach ($flags as $flag) {
            FeatureFlag::updateOrCreate(['key' => $flag['key']], $flag);
        }

        // Admin user reference for broadcasts
        $admin = User::where('email', 'admin@clickerpro.app')->first();

        // Broadcasts
        $broadcasts = [
            [
                'title' => 'Welcome to ClickerPro',
                'body' => 'Thanks for joining! ClickerPro helps you manage your photography studio effortlessly. Explore bookings, clients, gear, and more.',
                'is_active' => true,
                'target_role' => null,
                'created_by' => $admin?->id,
            ],
            [
                'title' => 'Upgrade to PRO',
                'body' => 'Unlock advanced reports, team management, and more with ClickerPro PRO. Contact us to upgrade your plan today!',
                'is_active' => true,
                'target_role' => 'OWNER',
                'created_by' => $admin?->id,
            ],
        ];

        foreach ($broadcasts as $broadcast) {
            Broadcast::create($broadcast);
        }
    }
}
