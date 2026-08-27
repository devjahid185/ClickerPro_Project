<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Booking (event) API shape. Reproduces the previous controller `flatten()`
 * helper EXACTLY — the full event attributes plus the convenience
 * client_name / client_phone fields the frontends read at the top level.
 *
 * IMPORTANT: keep this output byte-for-byte compatible with the old shape.
 * The `client` relation should be eager-loaded by the caller.
 */
class BookingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // Start from the full model attributes (same as $event->toArray()).
        $data = parent::toArray($request);

        // Flattened client fields (same as the old flatten()). The Flutter
        // web bundle has its own local clients table with a studio+phone
        // unique key; sending the nested client relation can make older web
        // builds try to insert the same phone under a different local id.
        // Keep the stable top-level fields every screen already reads.
        $data['client_name'] = $this->client?->name;
        $data['client_phone'] = $this->client?->phone;
        unset($data['client']);

        return $data;
    }
}
