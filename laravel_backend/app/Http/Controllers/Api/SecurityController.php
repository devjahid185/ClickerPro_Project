<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BlockedIp;
use App\Models\LoginActivity;
use Illuminate\Http\Request;

class SecurityController extends Controller
{
    public function loginActivity(Request $request)
    {
        $activities = LoginActivity::orderBy('created_at', 'desc')
            ->limit(100)->get()
            ->map(fn ($a) => [
                'id' => (string) $a->id,
                'email' => $a->email,
                'ip' => $a->ip,
                'success' => (bool) $a->success,
                'createdAt' => $a->created_at?->toIso8601String(),
            ]);

        return response()->json(['data' => $activities, 'total' => $activities->count()]);
    }

    public function blockIp(Request $request)
    {
        $data = $request->validate([
            'ip' => 'required|string|max:45',
            'reason' => 'nullable|string',
        ]);

        $blocked = BlockedIp::updateOrCreate(
            ['ip' => $data['ip']],
            ['reason' => $data['reason'] ?? null, 'blocked_at' => now()]
        );

        return response()->json(['data' => $blocked], 201);
    }

    public function unblockIp($ip)
    {
        $blocked = BlockedIp::where('ip', $ip)->first();

        if (!$blocked) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $blocked->delete();

        return response()->json(['message' => 'ok']);
    }

    public function blockedIps()
    {
        $ips = BlockedIp::orderBy('blocked_at', 'desc')->get()
            ->map(fn ($b) => [
                'ip' => $b->ip,
                'reason' => $b->reason,
                'createdAt' => ($b->blocked_at ?? $b->created_at)?->toIso8601String(),
            ]);
        return response()->json(['data' => $ips]);
    }

    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    //  Two-Factor Auth (TOTP, Google-Authenticator compatible)
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    public function twoFaStatus(Request $request)
    {
        return response()->json(['data' => ['enabled' => (bool) $request->user()->totp_enabled]]);
    }

    public function twoFaSetup(Request $request)
    {
        $user = $request->user();
        $secret = $this->randomBase32(32);
        $user->update(['totp_secret' => $secret, 'totp_enabled' => false]);

        $issuer = rawurlencode('Graphy7');
        $label = rawurlencode($user->email);
        $otpauth = "otpauth://totp/{$issuer}:{$label}?secret={$secret}&issuer={$issuer}";

        // Return a QR image URL (rendered client-side via a public QR service).
        $qr = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' . rawurlencode($otpauth);

        return response()->json(['data' => ['qr' => $qr, 'secret' => $secret, 'otpauth' => $otpauth]]);
    }

    public function twoFaVerify(Request $request)
    {
        $data = $request->validate(['token' => 'required|string']);
        $user = $request->user();

        if (!$user->totp_secret || !$this->verifyTotp($user->totp_secret, $data['token'])) {
            return response()->json(['message' => 'Invalid code'], 422);
        }

        $user->update(['totp_enabled' => true]);
        return response()->json(['data' => ['enabled' => true]]);
    }

    public function twoFaDisable(Request $request)
    {
        $request->user()->update(['totp_enabled' => false, 'totp_secret' => null]);
        return response()->json(['data' => ['enabled' => false]]);
    }

    // â”€â”€ TOTP helpers (RFC 6238 / 4226) â”€â”€
    private function randomBase32(int $length): string
    {
        $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $s = '';
        for ($i = 0; $i < $length; $i++) {
            $s .= $alphabet[random_int(0, 31)];
        }
        return $s;
    }

    private function verifyTotp(string $secret, string $token, int $window = 1): bool
    {
        $token = preg_replace('/\s+/', '', $token);
        $timeSlice = (int) floor(time() / 30);
        for ($i = -$window; $i <= $window; $i++) {
            if (hash_equals($this->totpAt($secret, $timeSlice + $i), str_pad($token, 6, '0', STR_PAD_LEFT))) {
                return true;
            }
        }
        return false;
    }

    private function totpAt(string $secret, int $timeSlice): string
    {
        $key = $this->base32Decode($secret);
        $bin = pack('N*', 0) . pack('N*', $timeSlice);
        $hash = hash_hmac('sha1', $bin, $key, true);
        $offset = ord($hash[19]) & 0xf;
        $code = (
            ((ord($hash[$offset]) & 0x7f) << 24) |
            ((ord($hash[$offset + 1]) & 0xff) << 16) |
            ((ord($hash[$offset + 2]) & 0xff) << 8) |
            (ord($hash[$offset + 3]) & 0xff)
        ) % 1000000;
        return str_pad((string) $code, 6, '0', STR_PAD_LEFT);
    }

    private function base32Decode(string $b32): string
    {
        $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $b32 = strtoupper($b32);
        $bits = '';
        foreach (str_split($b32) as $c) {
            $pos = strpos($alphabet, $c);
            if ($pos === false) continue;
            $bits .= str_pad(decbin($pos), 5, '0', STR_PAD_LEFT);
        }
        $bytes = '';
        foreach (str_split($bits, 8) as $byte) {
            if (strlen($byte) === 8) $bytes .= chr(bindec($byte));
        }
        return $bytes;
    }
}
