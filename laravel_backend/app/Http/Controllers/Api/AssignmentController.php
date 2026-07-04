<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\ChecksEventOwnership;
use App\Models\Assignment;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    use ChecksEventOwnership;

    public function index(Request $request, $eventId)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // Public columns only — the full User row would leak
        // manager_permissions, tokens and email to teammates.
        $assignments = Assignment::where('event_id', $eventId)
            ->with('user:id,name,avatar,role,phone')
            ->get();

        return response()->json(['data' => $assignments]);
    }

    public function store($eventId, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'role' => 'nullable|string|max:100',
            'payout' => 'nullable|numeric|min:0',
            'payout_paid' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        // Distributor rule: a FREELANCER may add crew to an event only when
        // they are assigned to it themselves, and only in the SAME role they
        // were given (assigned as cinematographer → may add cinematographers
        // only). Owners/managers are unrestricted.
        $caller = $request->user();
        if ($caller->role === 'FREELANCER') {
            $own = Assignment::where('event_id', $eventId)
                ->where('user_id', $caller->id)
                ->first();
            if (!$own) {
                return response()->json([
                    'message' => 'You are not assigned to this event.',
                ], 403);
            }
            // chiefPhotographer distributes photographers, so photographer
            // variants collapse to one bucket for the comparison.
            $norm = function (string $r): string {
                $r = strtoupper($r);
                return str_contains($r, 'PHOTOGRAPHER') ? 'PHOTOGRAPHER' : $r;
            };
            $ownRole = $norm((string) $own->role);
            $newRole = $norm((string) ($data['role'] ?? ''));
            if ($ownRole !== '' && $newRole !== $ownRole) {
                return response()->json([
                    'message' => 'You can only add people in your own role ('
                        . strtolower($ownRole) . ').',
                ], 403);
            }
            // Distributors hand out work; they don't set someone else's pay.
            unset($data['payout'], $data['payout_paid']);
        }

        $data['event_id'] = $eventId;

        $assignment = Assignment::create($data);

        return response()->json(
            ['data' => $assignment->load('user:id,name,avatar,role,phone')],
            201
        );
    }

    public function update($eventId, $id, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $assignment = Assignment::where('event_id', $eventId)->find($id);

        if (!$assignment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'role' => 'nullable|string|max:100',
            'payout' => 'nullable|numeric|min:0',
            'payout_paid' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        $assignment->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(
            ['data' => $assignment->fresh()->load('user:id,name,avatar,role,phone')]
        );
    }

    public function destroy($eventId, $id, Request $request)
    {
        if (!$this->ownsEvent($request, $eventId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $assignment = Assignment::where('event_id', $eventId)->find($id);

        if (!$assignment) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // A freelancer distributor may only remove THEMSELVES (stepping
        // aside after re-assigning the shoot) — never another crew member.
        $caller = $request->user();
        if ($caller->role === 'FREELANCER'
            && (int) $assignment->user_id !== (int) $caller->id) {
            return response()->json([
                'message' => 'You can only remove your own assignment.',
            ], 403);
        }

        $assignment->delete();

        return response()->json(['message' => 'ok']);
    }
}
