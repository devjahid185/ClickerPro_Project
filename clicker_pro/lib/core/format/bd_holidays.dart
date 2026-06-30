// lib/core/format/bd_holidays.dart
//
// Bangladesh public holidays, bundled so the dashboard's "Holidays This
// Month" card works fully offline. Fixed-date national days are exact;
// lunar (Islamic) and lunisolar (Hindu/Buddhist) observances are the
// commonly gazetted dates and may shift ±1 day with moon sighting —
// fine for a planning hint on a dashboard card.

/// month → list of holiday days for that year.
const Map<int, Map<int, List<int>>> _bdHolidays = {
  2026: {
    2: [21], // Shaheed Dibosh / International Mother Language Day
    3: [20, 21, 22, 26], // Eid-ul-Fitr* + Independence Day
    4: [14], // Pahela Baishakh
    5: [1, 27, 28, 29], // May Day + Eid-ul-Adha*
    6: [26], // Ashura*
    8: [26], // Eid-e-Miladunnabi*
    9: [4], // Janmashtami*
    10: [20], // Bijoya Dashami (Durga Puja)*
    12: [16, 25], // Victory Day + Christmas
  },
  2027: {
    2: [21],
    3: [10, 11, 12, 26], // Eid-ul-Fitr* + Independence Day
    4: [14],
    5: [1, 17, 18, 19], // May Day + Eid-ul-Adha*
    6: [15], // Ashura*
    8: [15], // Eid-e-Miladunnabi* (approx) — Janmashtami Aug 24*
    10: [9], // Bijoya Dashami*
    12: [16, 25],
  },
};

/// Holiday names keyed by year → month → day. Mirrors [_bdHolidays] so
/// the dashboard can show WHICH dates are holidays, not just a count.
const Map<int, Map<int, Map<int, String>>> _bdHolidayNames = {
  2026: {
    2: {21: 'Shaheed Day / Intl Mother Language Day'},
    3: {
      20: 'Eid-ul-Fitr*',
      21: 'Eid-ul-Fitr*',
      22: 'Eid-ul-Fitr*',
      26: 'Independence Day',
    },
    4: {14: 'Pohela Boishakh'},
    5: {
      1: 'May Day',
      27: 'Eid-ul-Adha*',
      28: 'Eid-ul-Adha*',
      29: 'Eid-ul-Adha*',
    },
    6: {26: 'Ashura*'},
    8: {26: 'Eid-e-Miladunnabi*'},
    9: {4: 'Janmashtami*'},
    10: {20: 'Bijoya Dashami (Durga Puja)*'},
    12: {16: 'Victory Day', 25: 'Christmas'},
  },
  2027: {
    2: {21: 'Shaheed Day / Intl Mother Language Day'},
    3: {
      10: 'Eid-ul-Fitr*',
      11: 'Eid-ul-Fitr*',
      12: 'Eid-ul-Fitr*',
      26: 'Independence Day',
    },
    4: {14: 'Pohela Boishakh'},
    5: {
      1: 'May Day',
      17: 'Eid-ul-Adha*',
      18: 'Eid-ul-Adha*',
      19: 'Eid-ul-Adha*',
    },
    6: {15: 'Ashura*'},
    8: {15: 'Eid-e-Miladunnabi*'},
    10: {9: 'Bijoya Dashami*'},
    12: {16: 'Victory Day', 25: 'Christmas'},
  },
};

/// Government weekly holidays in Bangladesh: Friday + Saturday. These apply
/// every week regardless of year, so the holiday list is never empty even in
/// months with no gazetted national day.
const Set<int> _weeklyHolidayWeekdays = {DateTime.friday, DateTime.saturday};

/// Every weekly-holiday day-number (Fri/Sat) in [when]'s month.
List<int> _weeklyHolidayDays(DateTime when) {
  final daysInMonth = DateTime(when.year, when.month + 1, 0).day;
  final out = <int>[];
  for (var day = 1; day <= daysInMonth; day++) {
    final wd = DateTime(when.year, when.month, day).weekday;
    if (_weeklyHolidayWeekdays.contains(wd)) out.add(day);
  }
  return out;
}

/// All holiday day-numbers (national + weekly Fri/Sat) in [when]'s month,
/// de-duplicated and sorted.
List<int> _allHolidayDays(DateTime when) {
  final national = _bdHolidays[when.year]?[when.month] ?? const <int>[];
  final set = <int>{...national, ..._weeklyHolidayDays(when)};
  final sorted = set.toList()..sort();
  return sorted;
}

/// Number of holidays in [when]'s month — national gazetted days plus the
/// weekly Friday/Saturday holidays. Unknown years still return the weekly
/// count (which is independent of the gazetted-date table).
int bdHolidaysInMonth(DateTime when) => _allHolidayDays(when).length;

/// The holiday day-numbers of [when]'s month (national + weekly), for
/// calendar dots etc.
List<int> bdHolidayDays(DateTime when) =>
    List.unmodifiable(_allHolidayDays(when));

/// A single dated holiday entry for list display.
class BdHoliday {
  const BdHoliday({required this.date, required this.name});
  final DateTime date;
  final String name;
}

/// All holidays of [when]'s month with names, sorted by day. National days use
/// their gazetted name; the weekly Friday/Saturday holidays are labelled by
/// weekday. National names win when a date is both (rare, e.g. Eid on a
/// Friday).
List<BdHoliday> bdHolidaysOfMonth(DateTime when) {
  final names = _bdHolidayNames[when.year]?[when.month] ?? const <int, String>{};
  final national = (_bdHolidays[when.year]?[when.month] ?? const <int>[]).toSet();
  final weekly = _weeklyHolidayDays(when).toSet();
  final allDays = (<int>{...national, ...weekly}).toList()..sort();

  return List.unmodifiable([
    for (final day in allDays)
      BdHoliday(
        date: DateTime(when.year, when.month, day),
        name: national.contains(day)
            ? (names[day] ?? 'Public Holiday')
            : 'Weekly Holiday (${_weekdayName(DateTime(when.year, when.month, day).weekday)})',
      ),
  ]);
}

String _weekdayName(int weekday) {
  switch (weekday) {
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    default:
      return 'Weekend';
  }
}
