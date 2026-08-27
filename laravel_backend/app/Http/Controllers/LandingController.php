<?php

namespace App\Http\Controllers;

use App\Models\AppSetting;

class LandingController extends Controller
{
    private function getValue(string $key, $default = null)
    {
        return AppSetting::getValue($key, $default);
    }

    public function index()
    {
        $downloadUrl = $this->getValue('app.android_url', asset('ClickerPro.apk'));
        $webUrl = 'https://web.graphy7.tech';

        $details = [
            [
                'icon' => 'App',
                'title' => 'Mobile App',
                'text' => 'Install the Android app for your team and run every shoot from the phone with offline support, payments, reminders and team chat.',
                'link' => $downloadUrl,
                'button' => 'Download APK',
            ],
            [
                'icon' => 'Web',
                'title' => 'Web App',
                'text' => 'Open the same studio platform in the browser for planning, reports and calendar overview work.',
                'link' => $webUrl,
                'button' => 'Open Web App',
            ],
            [
                'icon' => 'Team',
                'title' => 'Team and Roles',
                'text' => 'Invite managers and freelancers with a 6-digit passcode. Everyone sees the bookings, payouts and permissions their role allows.',
                'link' => '#features',
                'button' => 'See Features',
            ],
            [
                'icon' => 'BDT',
                'title' => 'Built for BDT',
                'text' => 'Bookings, invoices, dues and payouts in Bangladeshi Taka, with bKash, bank transfer and cash all tracked in one finance dashboard.',
                'link' => '#screens',
                'button' => 'See Screens',
            ],
        ];

        $reviews = [
            [
                'name' => 'Ayesha Rahman',
                'role' => 'Studio Owner',
                'text' => 'Graphy7 replaced our paper bookings and WhatsApp chaos. Now every shoot is organised and the team knows exactly what to do.',
            ],
            [
                'name' => 'Shakib Hasan',
                'role' => 'Lead Shooter',
                'text' => 'The event reminders and finance summary mean I never miss a payment or a shoot date anymore. It feels like the studio finally has one brain.',
            ],
            [
                'name' => 'Nadia Akter',
                'role' => 'Studio Manager',
                'text' => 'Our clients love the new invoices and team assignments. Everything looks premium and professional in one place.',
            ],
        ];

        return view('landing', [
            'heroTitle' => 'Run Your Photography Business With Confidence.',
            'heroSubtitle' => 'Built for Bangladesh studios that want bookings, teams and money managed in a single, modern platform.',
            'heroDescription' => 'Graphy7 gives you the mobile app and web dashboard to run your photography company like a pro.',
            'featureHeadline' => 'Smart tools for booking, team, finance and delivery.',
            'featureSubheadline' => 'Everything your photography company needs with a premium, professional user experience.',
            'details' => $details,
            'reviews' => $reviews,
            'appDownloadUrl' => $downloadUrl,
            'appWebUrl' => $webUrl,
        ]);
    }

    public function privacy()
    {
        return view('privacy-policy');
    }

    public function dataDeletion()
    {
        return view('data-deletion');
    }
}
