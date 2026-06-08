<?php
namespace App\Enums;

enum Shift: string {
    case DAY = 'DAY';
    case NIGHT = 'NIGHT';
    case BOTH = 'BOTH';
}
