<?php
namespace App\Enums;

enum UserRole: string {
    case OWNER = 'OWNER';
    case FREELANCER = 'FREELANCER';
    case BOTH = 'BOTH';
    case MANAGER = 'MANAGER';
    case ADMIN = 'ADMIN';
}
