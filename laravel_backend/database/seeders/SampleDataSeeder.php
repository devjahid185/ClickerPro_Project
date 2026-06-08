<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Client;
use App\Models\Event;
use App\Models\Payment;
use App\Models\Package;
use App\Models\GearItem;
use App\Models\Expense;
use Illuminate\Database\Seeder;

class SampleDataSeeder extends Seeder
{
    public function run(): void
    {
        $owner = User::where('email', 'owner@test.com')->first();
        if (!$owner) {
            $this->command->warn('owner@test.com not found — run DatabaseSeeder first.');
            return;
        }

        // Avoid duplicating sample data on re-run.
        if (Event::where('owner_id', $owner->id)->exists()) {
            $this->command->info('Sample data already present for Test Owner — skipping.');
            return;
        }

        // ── Clients ──
        $clientData = [
            ['name' => 'Nadia Rahman',   'phone' => '01711000001', 'email' => 'nadia@example.com'],
            ['name' => 'Karim Ahmed',    'phone' => '01711000002', 'email' => 'karim@example.com'],
            ['name' => 'Fatema Begum',   'phone' => '01711000003', 'email' => 'fatema@example.com'],
            ['name' => 'TechCorp Ltd',   'phone' => '01711000004', 'email' => 'events@techcorp.com'],
            ['name' => 'Sadia & Rifat',  'phone' => '01711000005', 'email' => 'sadia@example.com'],
        ];
        $clients = [];
        foreach ($clientData as $c) {
            $clients[] = Client::create(array_merge($c, ['owner_id' => $owner->id]));
        }

        // ── Packages ──
        $packages = [
            ['name' => 'Wedding Premium', 'base_price' => 85000, 'coverage_hours' => 10, 'has_video' => true,  'has_drone' => true,  'has_album' => true,  'notes' => '2 photographers + cinematographer, 300 edited photos, premium album, drone coverage'],
            ['name' => 'Holud Standard',  'base_price' => 35000, 'coverage_hours' => 5,  'has_video' => true,  'has_drone' => false, 'has_album' => false, 'notes' => '1 photographer + videographer, 150 edited photos, highlight trailer'],
            ['name' => 'Portrait Session','base_price' => 8000,  'coverage_hours' => 2,  'has_video' => false, 'has_drone' => false, 'has_album' => false, 'notes' => '1 photographer, 30 edited photos, online gallery'],
            ['name' => 'Corporate Event', 'base_price' => 25000, 'coverage_hours' => 6,  'has_video' => true,  'has_drone' => false, 'has_album' => false, 'notes' => 'Event coverage, 200 photos, edited recap video'],
        ];
        foreach ($packages as $p) {
            Package::create(array_merge($p, ['owner_id' => $owner->id]));
        }

        // ── Bookings (events) with varied statuses, shifts, dates ──
        $today = now();
        $bookings = [
            ['title' => 'Nadia & Karim Wedding',   'client' => 0, 'event_type' => 'Wedding',   'shift' => 'BOTH',  'venue' => 'Gulshan Club, Dhaka',     'price' => 85000, 'advance' => 30000, 'status' => 'CONFIRMED',     'days' => 5],
            ['title' => 'Karim Family Portrait',    'client' => 1, 'event_type' => 'Portrait',  'shift' => 'DAY',   'venue' => 'Studio, Dhanmondi',      'price' => 8000,  'advance' => 8000,  'status' => 'COMPLETED',     'days' => -10],
            ['title' => 'Fatema Holud Ceremony',    'client' => 2, 'event_type' => 'Holud',     'shift' => 'NIGHT', 'venue' => 'Community Center, Uttara','price' => 35000, 'advance' => 15000, 'status' => 'PENDING',       'days' => 12],
            ['title' => 'TechCorp Annual Day',      'client' => 3, 'event_type' => 'Corporate', 'shift' => 'DAY',   'venue' => 'Radisson Blu, Dhaka',     'price' => 25000, 'advance' => 25000, 'status' => 'SHOT_COMPLETE', 'days' => -3],
            ['title' => 'Sadia & Rifat Engagement', 'client' => 4, 'event_type' => 'Engagement','shift' => 'NIGHT', 'venue' => 'Le Meridien, Dhaka',     'price' => 28000, 'advance' => 10000, 'status' => 'CONFIRMED',     'days' => 2],
            ['title' => 'Nadia Reception',          'client' => 0, 'event_type' => 'Reception', 'shift' => 'NIGHT', 'venue' => 'Sheraton, Dhaka',        'price' => 60000, 'advance' => 20000, 'status' => 'PENDING',       'days' => 8],
            ['title' => 'Corporate Product Shoot',  'client' => 3, 'event_type' => 'Corporate', 'shift' => 'DAY',   'venue' => 'Motijheel Office',       'price' => 18000, 'advance' => 0,     'status' => 'DELIVERED',     'days' => -20],
        ];

        foreach ($bookings as $b) {
            $price = $b['price'];
            $advance = $b['advance'];
            $event = Event::create([
                'owner_id'     => $owner->id,
                'client_id'    => $clients[$b['client']]->id,
                'title'        => $b['title'],
                'event_type'   => $b['event_type'],
                'date'         => $today->copy()->addDays($b['days'])->toDateString(),
                'venue'        => $b['venue'],
                'shift'        => $b['shift'],
                'status'       => $b['status'],
                'price'        => $price,
                'advance_paid' => $advance,
                'due_amount'   => $price - $advance,
            ]);

            // Record an advance payment where applicable
            if ($advance > 0) {
                Payment::create([
                    'event_id'    => $event->id,
                    'recorded_by' => $owner->id,
                    'amount'      => $advance,
                    'kind'        => 'ADVANCE',
                    'method'      => ['CASH', 'BKASH', 'NAGAD', 'BANK'][array_rand([0,1,2,3])],
                    'note'        => 'Booking advance',
                    'paid_at'     => $today->copy()->addDays($b['days'] - 2)->toDateString(),
                ]);
            }
            // Full-paid bookings get a due-clearing payment
            if ($price - $advance === 0 && $price > 0 && $advance < $price) {
                // already covered
            } elseif (in_array($b['status'], ['COMPLETED', 'DELIVERED']) && $price - $advance > 0) {
                Payment::create([
                    'event_id'    => $event->id,
                    'recorded_by' => $owner->id,
                    'amount'      => $price - $advance,
                    'kind'        => 'DUE',
                    'method'      => 'CASH',
                    'note'        => 'Final settlement',
                    'paid_at'     => $today->copy()->addDays($b['days'] + 1)->toDateString(),
                ]);
            }
        }

        // ── Gear ──
        $gear = [
            ['name' => 'Canon EOS R5',        'category' => 'Camera',  'serial_number' => 'CR5-001', 'condition' => 'GOOD', 'purchase_value' => 450000, 'is_available' => true],
            ['name' => 'Sony A7 IV',          'category' => 'Camera',  'serial_number' => 'SA7-002', 'condition' => 'GOOD', 'purchase_value' => 280000, 'is_available' => false],
            ['name' => 'Canon RF 24-70mm',    'category' => 'Lens',    'serial_number' => 'RF24-03', 'condition' => 'GOOD', 'purchase_value' => 220000, 'is_available' => true],
            ['name' => 'Godox AD600 Strobe',  'category' => 'Lighting','serial_number' => 'GX6-004', 'condition' => 'FAIR', 'purchase_value' => 65000,  'is_available' => true],
            ['name' => 'DJI Mavic 3 Drone',   'category' => 'Drone',   'serial_number' => 'DJM-005', 'condition' => 'GOOD', 'purchase_value' => 320000, 'is_available' => true],
            ['name' => 'Manfrotto Tripod',    'category' => 'Support', 'serial_number' => 'MFT-006', 'condition' => 'FAIR', 'purchase_value' => 18000,  'is_available' => true],
        ];
        foreach ($gear as $g) {
            GearItem::create(array_merge($g, ['owner_id' => $owner->id]));
        }

        // ── Expenses ──
        $expenses = [
            ['title' => 'Travel to Gulshan venue', 'amount' => 1200, 'category' => 'Travel', 'days' => -2],
            ['title' => 'Team lunch on shoot day', 'amount' => 2500, 'category' => 'Food',   'days' => -3],
            ['title' => 'Album printing',          'amount' => 8000, 'category' => 'Print',  'days' => -8],
            ['title' => 'Memory cards (2x 128GB)',  'amount' => 6500, 'category' => 'Gear',   'days' => -15],
            ['title' => 'Mobile recharge',         'amount' => 500,  'category' => 'Phone',  'days' => -1],
        ];
        foreach ($expenses as $e) {
            Expense::create([
                'owner_id' => $owner->id,
                'title'    => $e['title'],
                'amount'   => $e['amount'],
                'category' => $e['category'],
                'date'     => $today->copy()->addDays($e['days'])->toDateString(),
            ]);
        }

        $this->command->info('Sample data seeded: ' . count($clients) . ' clients, ' . count($bookings) . ' bookings, ' . count($gear) . ' gear, ' . count($expenses) . ' expenses.');
    }
}
