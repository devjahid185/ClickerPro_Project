<?php

namespace App\Policies;

use App\Models\Invoice;
use App\Models\User;

/**
 * Authorization rules for invoices. Ownership is tracked via Invoice.owner_id.
 * No admin `before()` override — preserves pre-refactor uniform ownership.
 */
class InvoicePolicy
{
    public function view(User $user, Invoice $invoice): bool
    {
        return $invoice->owner_id === $user->id;
    }

    public function update(User $user, Invoice $invoice): bool
    {
        return $invoice->owner_id === $user->id;
    }
}
