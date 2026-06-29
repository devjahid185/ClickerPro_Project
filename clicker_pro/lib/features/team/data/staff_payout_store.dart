// lib/features/team/data/staff_payout_store.dart
//
// Offline-first storage for the owner-side staff payout sheet.
//
// The sheet itself is computed on the backend, so when the backend is
// unreachable there is nothing to load and "mark paid" has nowhere to go —
// which is exactly why staff payments appeared broken offline. This store
// fixes that with two SharedPreferences-backed pieces:
//
//   1. A cached copy of the last sheet the server returned.
//   2. A set of assignment ids the owner marked paid locally (when the
//      server could not be reached). These overrides are replayed on top of
//      the cached/served sheet so a settled payout stays settled across
//      restarts until the backend confirms it.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/staff_payout.dart';

class StaffPayoutStore {
  static const _sheetKey = 'staff_payout_sheet_v1';
  static const _paidKey = 'staff_payout_local_paid_v1';

  /// Persist the latest sheet from the server for offline rendering.
  Future<void> cacheSheet(StaffPayoutSheet sheet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sheetKey, jsonEncode(sheet.toJson()));
  }

  Future<StaffPayoutSheet?> readCachedSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sheetKey);
    if (raw == null) return null;
    try {
      return StaffPayoutSheet.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> readLocalPaid() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_paidKey) ?? const <String>[]).toSet();
  }

  /// Record [assignmentIds] as locally paid (offline settle). Pass every
  /// assignment id for a member to settle them all at once.
  Future<void> addLocalPaid(Iterable<String> assignmentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_paidKey) ?? const <String>[]).toSet()
      ..addAll(assignmentIds.where((id) => id.isNotEmpty));
    await prefs.setStringList(_paidKey, current.toList());
  }

  /// Once the server confirms payment, the local override is redundant —
  /// drop it so the two sources can't drift.
  Future<void> clearLocalPaid(Iterable<String> assignmentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final drop = assignmentIds.toSet();
    final current = (prefs.getStringList(_paidKey) ?? const <String>[])
        .where((id) => !drop.contains(id))
        .toList();
    await prefs.setStringList(_paidKey, current);
  }

  /// Re-derive a sheet with the locally-paid overrides applied so totals,
  /// per-member due, and per-event PAID badges all stay consistent.
  StaffPayoutSheet applyLocalPaid(StaffPayoutSheet sheet, Set<String> paid) {
    if (paid.isEmpty) return sheet;

    final members = sheet.members.map((m) {
      final items = m.items
          .map((it) => paid.contains(it.assignmentId) ? it.copyWith(paid: true) : it)
          .toList(growable: false);
      final memberPaid = items
          .where((it) => it.paid)
          .fold<double>(0, (s, it) => s + it.amount);
      final due = (m.earned - memberPaid) > 0 ? m.earned - memberPaid : 0.0;
      return m.copyWith(paid: memberPaid, due: due, items: items);
    }).toList(growable: false);

    final totalPaid = members.fold<double>(0, (s, m) => s + m.paid);
    return StaffPayoutSheet(
      totalEarned: sheet.totalEarned,
      totalPaid: totalPaid,
      members: members,
    );
  }
}
