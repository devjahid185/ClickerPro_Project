<?php
namespace App\Enums;

enum PaymentMethod: string {
    case CASH = 'CASH';
    case BKASH = 'BKASH';
    case NAGAD = 'NAGAD';
    case BANK = 'BANK';
    case CARD = 'CARD';
    case OTHER = 'OTHER';
}
