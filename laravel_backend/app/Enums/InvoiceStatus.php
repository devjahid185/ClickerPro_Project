<?php
namespace App\Enums;

enum InvoiceStatus: string {
    case DRAFT = 'DRAFT';
    case SENT = 'SENT';
    case PAID = 'PAID';
    case OVERDUE = 'OVERDUE';
}
