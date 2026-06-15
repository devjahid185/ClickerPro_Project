// lib/features/profile/data/user_api.dart
//
// Profile endpoints against the Laravel backend.
//
// Laravel wraps responses in `{data: ...}` and persists ONLY these profile
// columns (ProfileController::update allowlist): name, phone, bio,
// business_name, avatar. The richer local fields (whatsapp, bkash, bank
// details, signature, logo, specialization, …) live on the device and are
// preserved by the repository merge — they are simply not sent.

import '../../../core/network/api_client.dart';

class UserApi {
  UserApi(this._client);

  final ApiClient _client;

  /// Unwraps `{data: ...}` (tolerating flat legacy responses) and digs out
  /// the user map whether it arrives as `data`, `data.user`, or `user`.
  Map<String, dynamic> _user(dynamic r) {
    if (r is! Map) return <String, dynamic>{};
    final d = r['data'];
    final inner = d is Map ? d : r;
    final u = inner['user'];
    if (u is Map) return u.cast<String, dynamic>();
    return inner.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _client.get('/api/profile');
    return _user(r);
  }

  /// PATCH /api/profile — translates the local camelCase profile JSON to
  /// the snake_case columns the Laravel validator accepts.
  Future<Map<String, dynamic>> patchProfile(
    Map<String, dynamic> partial,
  ) async {
    final body = <String, dynamic>{
      if (partial['name'] != null) 'name': partial['name'],
      if (partial['phone'] != null) 'phone': partial['phone'],
      if (partial['bio'] != null) 'bio': partial['bio'],
      if (partial['companyName'] != null)
        'business_name': partial['companyName'],
      if (partial['avatarUrl'] != null) 'avatar': partial['avatarUrl'],
      // Studio logo + digital signature — now persisted server-side so the
      // "Uploaded / Attached" state survives a reload.
      if (partial['logoUrl'] != null) 'logo_url': partial['logoUrl'],
      if (partial['signatureUrl'] != null)
        'signature_url': partial['signatureUrl'],
      // Payout details — persisted so a team owner can see how to pay this
      // member from the member-profile sheet.
      if (partial['bkash'] != null) 'bkash_number': partial['bkash'],
      if (partial['bankDetails'] != null)
        'bank_details': partial['bankDetails'],
    };
    final r = await _client.patch('/api/profile', body: body);
    return _user(r);
  }

  /// Uploads an image to `POST /api/files/upload` and returns its ABSOLUTE
  /// url (the server answers with a relative `/storage/...` path).
  Future<String> uploadImage(String filePath) async {
    final r = await _client.postMultipart(
      '/api/files/upload',
      filePath: filePath,
    );
    final d = (r is Map && r['data'] is Map)
        ? (r['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final url = (d['url'] ?? '').toString();
    if (url.isEmpty) {
      throw Exception('Upload succeeded but no URL was returned');
    }
    return url.startsWith('http') ? url : '${_client.baseUrl}$url';
  }

  Future<Map<String, dynamic>?> getLifetimeStats() async {
    try {
      final r = await _client.get('/api/profile/stats');
      if (r is Map) {
        final d = r['data'];
        return (d is Map ? d : r).cast<String, dynamic>();
      }
      return null;
    } catch (_) {
      // Backend may not yet expose this endpoint; surface nulls so UI still renders.
      return null;
    }
  }

  Future<Map<String, dynamic>> addGear({
    required String name,
    String? brand,
  }) async {
    final body = <String, dynamic>{'name': name, 'brand': ?brand};
    final r = await _client.post('/api/profile/gear', body: body);
    if (r is Map) {
      final d = r['data'];
      final g = (d is Map ? d : r)['gear'];
      if (g is Map) return g.cast<String, dynamic>();
      if (d is Map) return d.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  Future<void> removeGear(String gearId) async {
    await _client.delete('/api/profile/gear/$gearId');
  }
}
