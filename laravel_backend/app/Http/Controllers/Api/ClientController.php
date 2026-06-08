<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ClientRequest;
use App\Models\Client;
use App\Models\Event;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    public function index(Request $request)
    {
        $query = Client::where('owner_id', $request->user()->id)->orderBy('name');

        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        return response()->json(['data' => $query->get()]);
    }

    public function show(Request $request, $id)
    {
        $client = Client::where('owner_id', $request->user()->id)->find($id);

        if (!$client) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $bookings = Event::where('owner_id', $request->user()->id)
            ->where('client_name', $client->name)
            ->orderBy('date', 'desc')
            ->get(['id', 'title', 'date', 'status', 'price']);

        return response()->json(['data' => array_merge($client->toArray(), ['bookings' => $bookings])]);
    }

    public function store(ClientRequest $request)
    {
        $data = $request->validated();

        $data['owner_id'] = $request->user()->id;
        $client = Client::create($data);

        return response()->json(['data' => $client], 201);
    }

    public function update(ClientRequest $request, $id)
    {
        $client = Client::where('owner_id', $request->user()->id)->find($id);

        if (!$client) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validated();

        $client->update(array_filter($data, fn($v) => $v !== null));

        return response()->json(['data' => $client->fresh()]);
    }

    public function destroy(Request $request, $id)
    {
        $client = Client::where('owner_id', $request->user()->id)->find($id);

        if (!$client) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $client->delete();

        return response()->json(['message' => 'ok']);
    }
}
