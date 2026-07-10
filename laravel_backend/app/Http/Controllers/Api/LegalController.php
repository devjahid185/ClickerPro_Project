<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class LegalController extends Controller
{
    public function privacy($lang = 'en')
    {
        $content = [
            'en' => 'Graphy7 Privacy Policy. We collect the account details you provide (name, email, phone) and a device id and language for sync. We use Firebase Cloud Messaging to deliver push notifications; we do not use analytics or advertising trackers. Your data is stored securely and never sold to third parties. You may export or delete your data at any time from Settings, or by contacting support@graphy7.app.',
            'bn' => 'Graphy7 গোপনীয়তা নীতি। আমরা আপনার দেওয়া অ্যাকাউন্ট তথ্য (নাম, ইমেইল, ফোন) এবং সিঙ্কের জন্য ডিভাইস আইডি ও ভাষা সংগ্রহ করি। পুশ নোটিফিকেশন পাঠাতে আমরা Firebase Cloud Messaging ব্যবহার করি; কোনো অ্যানালিটিক্স বা বিজ্ঞাপন ট্র্যাকার ব্যবহার করি না। আপনার ডেটা নিরাপদে সংরক্ষিত এবং তৃতীয় পক্ষের কাছে বিক্রি করা হয় না। আপনি যেকোনো সময় Settings থেকে ডেটা এক্সপোর্ট বা মুছে ফেলতে পারেন।',
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
            'en' => 'Graphy7 Terms of Service. By using Graphy7, you agree to use our platform for lawful photography business management. We reserve the right to suspend accounts that violate our terms. The FREE plan includes basic features; the PRO plan unlocks premium features. Subscriptions renew automatically unless cancelled.',
            'bn' => 'Graphy7 সেবার শর্তাবলী। Graphy7 ব্যবহার করে, আপনি বৈধ ফটোগ্রাফি ব্যবসা পরিচালনার জন্য আমাদের প্ল্যাটফর্ম ব্যবহার করতে সম্মত হন। আমরা আমাদের শর্ত লঙ্ঘনকারী অ্যাকাউন্ট স্থগিত করার অধিকার সংরক্ষণ করি।',
        ];

        return response()->json([
            'data' => [
                'lang' => $lang,
                'content' => $content[$lang] ?? $content['en'],
            ],
        ]);
    }
}
