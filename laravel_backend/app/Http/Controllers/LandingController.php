<?php

namespace App\Http\Controllers;

use App\Models\AppSetting;
use Illuminate\Http\Request;

class LandingController extends Controller
{
    private function getValue(string $key, $default = null)
    {
        return AppSetting::getValue($key, $default);
    }

    public function index()
    {
        $downloadUrl = $this->getValue('app.android_url', asset('ClickerPro.apk'));
        $webUrl = $this->getValue('app.web_url', url('/'));

        $details = [
            [
                'icon' => '📱',
                'title' => $this->getValue('landing.detail_mobile_title', 'Mobile App'),
                'text' => $this->getValue('landing.detail_mobile_text', 'Install the Android app for your team and run every shoot from the phone with offline support, payments, reminders and team chat.'),
                'link' => $downloadUrl,
                'button' => $this->getValue('landing.detail_mobile_cta', 'Download APK'),
            ],
            [
                'icon' => '🌐',
                'title' => $this->getValue('landing.detail_web_title', 'Web App'),
                'text' => $this->getValue('landing.detail_web_text', 'Open the same studio platform in the browser for easy planning, reports and calendar overviews.'),
                'link' => $webUrl,
                'button' => $this->getValue('landing.detail_web_cta', 'Open Web App'),
            ],
            [
                'icon' => '👥',
                'title' => $this->getValue('landing.detail_team_title', 'Team & Roles'),
                'text' => $this->getValue('landing.detail_team_text', 'Invite managers and freelancers with a 6-digit passcode. Everyone sees exactly the bookings, payouts and permissions their role allows.'),
                'link' => '#features',
                'button' => $this->getValue('landing.detail_team_cta', 'See Features'),
            ],
            [
                'icon' => '৳',
                'title' => $this->getValue('landing.detail_finance_title', 'Built for BDT'),
                'text' => $this->getValue('landing.detail_finance_text', 'Bookings, invoices, dues and payouts in Bangladeshi Taka — with bKash, bank transfer and cash all tracked in one finance dashboard.'),
                'link' => '#screens',
                'button' => $this->getValue('landing.detail_finance_cta', 'See Screens'),
            ],
        ];

        $reviews = [
            [
                'name' => $this->getValue('landing.review_1_name', 'Ayesha Rahman'),
                'role' => $this->getValue('landing.review_1_role', 'Studio Owner'),
                'text' => $this->getValue('landing.review_1_text', 'Clicker Pro replaced our paper bookings and WhatsApp chaos. Now every shoot is organised and the team knows exactly what to do.'),
            ],
            [
                'name' => $this->getValue('landing.review_2_name', 'Shakib Hasan'),
                'role' => $this->getValue('landing.review_2_role', 'Lead Shooter'),
                'text' => $this->getValue('landing.review_2_text', 'The event reminders and finance summary mean I never miss a payment or a shoot date anymore. It feels like the studio finally has one brain.'),
            ],
            [
                'name' => $this->getValue('landing.review_3_name', 'Nadia Akter'),
                'role' => $this->getValue('landing.review_3_role', 'Studio Manager'),
                'text' => $this->getValue('landing.review_3_text', 'Our clients love the new invoices and team assignments. Everything looks premium and professional in one place.'),
            ],
        ];

        return view('landing', [
            'heroTitle' => $this->getValue('landing.hero_title', 'Run Your Photography Business With Confidence.'),
            'heroSubtitle' => $this->getValue('landing.hero_subtitle', 'Built for Bangladesh studios that want bookings, teams and money managed in a single, modern platform.'),
            'heroDescription' => $this->getValue('landing.hero_description', 'Clicker Pro gives you the mobile app and web dashboard to run your photography company like a pro.'),
            'featureHeadline' => $this->getValue('landing.feature_headline', 'Smart tools for booking, team, finance and delivery.'),
            'featureSubheadline' => $this->getValue('landing.feature_subheadline', 'Everything your photography company needs with a premium, professional user experience.'),
            'details' => $details,
            'reviews' => $reviews,
            'appDownloadUrl' => $downloadUrl,
            'appWebUrl' => $webUrl,
        ]);
    }
}
