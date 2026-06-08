<?php
namespace App\Enums;

enum CouponType: string {
    case PERCENT = 'PERCENT';
    case FLAT = 'FLAT';
    case PRO_DAYS = 'PRO_DAYS';
}
