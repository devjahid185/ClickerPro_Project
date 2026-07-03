// lib/core/db/app_database.dart
//
// Drift-backed local database. Source of truth for User, UserPreferences,
// NotificationPreferences, GearItem, TeamInvite, the Outbox queue, and the
// Bookings module entities (Booking, Client, Assignment, Payment, Package,
// StatusHistoryEntry, ReEditRequest, TaskProgress, PublicBookingRequest).
//
// Cross-platform:
//   • Android / iOS / Windows / macOS / Linux  → native sqlite3 file
//   • Web (Chrome, etc.)                       → IndexedDB-backed WASM
//
// `package:drift_flutter` `driftDatabase(...)` chooses the right backend at
// runtime so we don't need conditional imports.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'tables/expenses_table.dart';
import 'tables/gear_items_table.dart';
import 'tables/notification_preferences_table.dart';
import 'tables/outbox_table.dart';
import 'tables/team_invites_table.dart';
import 'tables/user_preferences_table.dart';
import 'tables/users_table.dart';

// Bookings module (schema v2)
import 'tables/assignments_table.dart';
import 'tables/bookings_table.dart';
import 'tables/clients_table.dart';
import 'tables/packages_table.dart';
import 'tables/payments_table.dart';
import 'tables/public_booking_requests_table.dart';
import 'tables/re_edit_requests_table.dart';
import 'tables/status_history_table.dart';
import 'tables/task_progress_table.dart';

import 'daos/expenses_dao.dart';
import 'daos/users_dao.dart';
import 'daos/preferences_dao.dart';
import 'daos/gear_dao.dart';
import 'daos/outbox_dao.dart';

// Bookings module DAOs (schema v2)
import 'daos/assignments_dao.dart';
import 'daos/bookings_dao.dart';
import 'daos/clients_dao.dart';
import 'daos/packages_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/public_booking_requests_dao.dart';
import 'daos/re_edit_requests_dao.dart';
import 'daos/status_history_dao.dart';
import 'daos/task_progress_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersTable,
    UserPreferencesTable,
    NotificationPreferencesTable,
    GearItemsTable,
    TeamInvitesTable,
    OutboxTable,
    ExpensesTable,
    // Bookings module
    BookingsTable,
    ClientsTable,
    AssignmentsTable,
    PaymentsTable,
    PackagesTable,
    StatusHistoryTable,
    ReEditRequestsTable,
    TaskProgressTable,
    PublicBookingRequestsTable,
  ],
  daos: [
    UsersDao,
    PreferencesDao,
    GearDao,
    OutboxDao,
    ExpensesDao,
    // Bookings module
    BookingsDao,
    ClientsDao,
    AssignmentsDao,
    PaymentsDao,
    PackagesDao,
    StatusHistoryDao,
    ReEditRequestsDao,
    TaskProgressDao,
    PublicBookingRequestsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 → v2: add the nine Bookings module tables.
      if (from == 1 && to >= 2) {
        await m.createTable(bookingsTable);
        await m.createTable(clientsTable);
        await m.createTable(assignmentsTable);
        await m.createTable(paymentsTable);
        await m.createTable(packagesTable);
        await m.createTable(statusHistoryTable);
        await m.createTable(reEditRequestsTable);
        await m.createTable(taskProgressTable);
        await m.createTable(publicBookingRequestsTable);
      }
      // v2 → v3: extend packages_table with MOD-25 fields.
      if (from <= 2 && to >= 3) {
        await m.addColumn(packagesTable, packagesTable.discount);
        await m.addColumn(packagesTable, packagesTable.printSize);
        await m.addColumn(packagesTable, packagesTable.printQuantity);
        await m.addColumn(packagesTable, packagesTable.albumText);
        await m.addColumn(packagesTable, packagesTable.deliveryMethod);
        await m.addColumn(packagesTable, packagesTable.trailersPerEvent);
        await m.addColumn(packagesTable, packagesTable.fullVideosPerEvent);
        await m.addColumn(packagesTable, packagesTable.itemsJson);
      }
      // v3 → v4: add expenses_table for offline caching.
      if (from <= 3 && to >= 4) {
        await m.createTable(expensesTable);
      }
      // v4 → v5: MOD-07 v6 — add clientName + clientPhone to bookings.
      if (from <= 4 && to >= 5) {
        await m.addColumn(bookingsTable, bookingsTable.clientName);
        await m.addColumn(bookingsTable, bookingsTable.clientPhone);
      }
      // v5 → v6: BUG-FIX — repair bookings whose clientId points at a row that
      // doesn't exist in clients_table (e.g. the placeholder 'pending', or ids
      // dropped during an incomplete v4→v5 sync). With the FK reference on
      // bookings.clientId such a dangling id corrupts the row and crashes the
      // booking editor ("Could not open the booking editor"). Null it out — the
      // booking keeps its clientName/clientPhone, so no client info is lost.
      // Runs for devices already on v5 AND for fresh upgrades passing through.
      if (from <= 5 && to >= 6) {
        await customStatement(
          "UPDATE bookings_table SET client_id = NULL "
          "WHERE client_id IS NOT NULL "
          "AND client_id NOT IN (SELECT id FROM clients_table)",
        );
      }
      // v6 → v7: users_table gains companyName. Without a local column the
      // edited Company Name silently vanished after every profile refresh.
      if (from <= 6 && to >= 7) {
        await m.addColumn(usersTable, usersTable.companyName);
      }
      // v7 → v8: MOD-25 — packages gain team-composition fields so picking
      // a package auto-fills photographer/cinematographer counts + chief.
      if (from <= 7 && to >= 8) {
        await m.addColumn(packagesTable, packagesTable.photographerCount);
        await m.addColumn(packagesTable, packagesTable.cinematographerCount);
        await m.addColumn(packagesTable, packagesTable.includesChief);
      }
      // v8 → v9: owner opt-in flag for showing payment on shared event
      // details. Default false — shared details hide money unless turned on.
      if (from <= 8 && to >= 9) {
        await m.addColumn(bookingsTable, bookingsTable.showPaymentInShare);
      }
      // v9 → v10: owner-uploaded invoice / letterhead image (like the
      // signature). Without a local column the uploaded invoice would vanish
      // after every profile refresh.
      if (from <= 9 && to >= 10) {
        await m.addColumn(usersTable, usersTable.invoiceUrl);
      }
    },
  );
}

QueryExecutor _openConnection() {
  // `driftDatabase` is the cross-platform helper from drift_flutter:
  //   • mobile / desktop → NativeDatabase under app docs dir
  //   • web              → WasmDatabase backed by IndexedDB
  if (kIsWeb) {
    return driftDatabase(
      name: 'clicker_pro',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  return driftDatabase(name: 'clicker_pro');
}
