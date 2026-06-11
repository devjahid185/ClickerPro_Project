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
    2: {21: 'শহীদ দিবস / আন্তর্জাতিক মাতৃভাষা দিবস'},
    3: {
      20: 'ঈদুল ফিতর*',
      21: 'ঈদুল ফিতর*',
      22: 'ঈদুল ফিতর*',
      26: 'স্বাধীনতা দিবস',
    },
    4: {14: 'পহেলা বৈশাখ'},
    5: {
      1: 'মে দিবস',
      27: 'ঈদুল আজহা*',
      28: 'ঈদুল আজহা*',
      29: 'ঈদুল আজহা*',
    },
    6: {26: 'আশুরা*'},
    8: {26: 'ঈদে মিলাদুন্নবী*'},
    9: {4: 'জন্মাষ্টমী*'},
    10: {20: 'বিজয়া দশমী (দুর্গাপূজা)*'},
    12: {16: 'বিজয় দিবস', 25: 'বড়দিন'},
  },
  2027: {
    2: {21: 'শহীদ দিবস / আন্তর্জাতিক মাতৃভাষা দিবস'},
    3: {
      10: 'ঈদুল ফিতর*',
      11: 'ঈদুল ফিতর*',
      12: 'ঈদুল ফিতর*',
      26: 'স্বাধীনতা দিবস',
    },
    4: {14: 'পহেলা বৈশাখ'},
    5: {
      1: 'মে দিবস',
      17: 'ঈদুল আজহা*',
      18: 'ঈদুল আজহা*',
      19: 'ঈদুল আজহা*',
    },
    6: {15: 'আশুরা*'},
    8: {15: 'ঈদে মিলাদুন্নবী*'},
    10: {9: 'বিজয়া দশমী*'},
    12: {16: 'বিজয় দিবস', 25: 'বড়দিন'},
  },
};

/// Number of public holidays in [when]'s month. Unknown years return 0
/// rather than guessing.
int bdHolidaysInMonth(DateTime when) {
  return _bdHolidays[when.year]?[when.month]?.length ?? 0;
}

/// The holiday day-numbers of [when]'s month (for calendar dots etc.).
List<int> bdHolidayDays(DateTime when) {
  return List.unmodifiable(_bdHolidays[when.year]?[when.month] ?? const []);
}

/// A single dated holiday entry for list display.
class BdHoliday {
  const BdHoliday({required this.date, required this.name});
  final DateTime date;
  final String name;
}

/// All holidays of [when]'s month with names, sorted by day. Days
/// without a mapped name fall back to a generic label.
List<BdHoliday> bdHolidaysOfMonth(DateTime when) {
  final names = _bdHolidayNames[when.year]?[when.month] ?? const <int, String>{};
  final days = _bdHolidays[when.year]?[when.month] ?? const <int>[];
  final sorted = [...days]..sort();
  return List.unmodifiable([
    for (final day in sorted)
      BdHoliday(
        date: DateTime(when.year, when.month, day),
        name: names[day] ?? 'সরকারি ছুটি',
      ),
  ]);
}
