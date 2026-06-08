<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class LegalController extends Controller
{
    public function privacy($lang = 'en')
    {
        $content = [
            'en' => 'ClickerPro Privacy Policy. We collect your personal information to provide photography studio management services. Your data is stored securely and never sold to third parties. You may request data deletion at any time by contacting support@clickerpro.app.',
            'bn' => 'ClickerPro গোপনীয়তা নীতি। আমরা ফটোগ্রাফি স্টুডিও ম্যানেজমেন্ট সেবা প্রদানের জন্য আপনার ব্যক্তিগত তথ্য সংগ্রহ করি। আপনার ডেটা নিরাপদে সংরক্ষিত এবং তৃতীয় পক্ষের কাছে বিক্রি করা হয় না।',
        ];

        return response()->json([
            'data' => [
                'lang' => $lang,
                'content' => $content[$lang] ?? $content['en'],
            ],
        ]);
    }

    public function terms($lang = 'en')
    {
        $content = [
            'en' => 'ClickerPro Terms of Service. By using ClickerPro, you agree to use our platform for lawful photography business management. We reserve the right to suspend accounts that violate our terms. The FREE plan includes basic features; the PRO plan unlocks premium features. Subscriptions renew automatically unless cancelled.',
            'bn' => 'ClickerPro সেবার শর্তাবলী। ClickerPro ব্যবহার করে, আপনি বৈধ ফটোগ্রাফি ব্যবসা পরিচালনার জন্য আমাদের প্ল্যাটফর্ম ব্যবহার করতে সম্মত হন। আমরা আমাদের শর্ত লঙ্ঘনকারী অ্যাকাউন্ট স্থগিত করার অধিকার সংরক্ষণ করি।',
        ];

        return response()->json([
            'data' => [
                'lang' => $lang,
                'content' => $content[$lang] ?? $content['en'],
            ],
        ]);
    }
}
