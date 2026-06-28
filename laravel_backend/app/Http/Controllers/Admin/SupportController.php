<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use App\Models\SupportTicket;
use Illuminate\Http\Request;

/**
 * Admin → Support & FAQ (Blade). Support tickets (reply/close) plus FAQ CRUD.
 */
class SupportController extends Controller
{
    public function index()
    {
        return view('admin.support.index', [
            'tickets' => SupportTicket::with('user')->orderBy('created_at', 'desc')->get(),
            'faqs'    => Faq::orderBy('created_at')->get(),
        ]);
    }

    public function reply(Request $request, $id)
    {
        $data = $request->validate([
            'admin_reply' => ['required', 'string'],
            'status'      => ['nullable', 'string', 'in:OPEN,CLOSED,PENDING'],
        ]);
        $ticket = SupportTicket::findOrFail($id);
        $ticket->update([
            'admin_reply' => $data['admin_reply'],
            'status'      => $data['status'] ?? 'CLOSED',
        ]);

        return back()->with('status', 'Reply sent.');
    }

    public function storeFaq(Request $request)
    {
        $data = $request->validate([
            'question' => ['required', 'string'],
            'answer'   => ['required', 'string'],
        ]);
        $data['is_active'] = $request->boolean('is_active', true);
        Faq::create($data);

        return back()->with('status', 'FAQ added.');
    }

    public function destroyFaq($id)
    {
        Faq::findOrFail($id)->delete();
        return back()->with('status', 'FAQ deleted.');
    }
}
