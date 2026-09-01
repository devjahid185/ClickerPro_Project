<?php
namespace App\Enums;

enum PaymentKind: string {
    case ADVANCE = 'ADVANCE';
    case DUE = 'DUE';
    case PAID = 'PAID';
    case EXTRA = 'EXTRA';
    case PAYOUT = 'PAYOUT';
}
