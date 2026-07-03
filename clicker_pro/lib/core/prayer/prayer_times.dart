// lib/core/prayer/prayer_times.dart
//
// Offline prayer-time computation. Pure Dart — no packages, no network, no
// GPS. Given a date and a location it computes the five daily prayer times
// (plus sunrise) from the sun's position using the standard astronomical
// algorithm, so the dashboard's নামাজের সময় widget works fully offline.
//
// Defaults to Dhaka, Bangladesh and the "Karachi" convention (Fajr 18°, Isha
// 18°) with Hanafi Asr (shadow factor 2), which matches how most Bangladeshi
// studios read their prayer schedule.

import 'dart:math' as math;

/// One computed prayer schedule for a specific date + location.
class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// The five daily prayers in order (sunrise is informational, not a prayer).
  List<({String name, DateTime time})> get schedule => [
        (name: 'Fajr', time: fajr),
        (name: 'Sunrise', time: sunrise),
        (name: 'Dhuhr', time: dhuhr),
        (name: 'Asr', time: asr),
        (name: 'Maghrib', time: maghrib),
        (name: 'Isha', time: isha),
      ];

  /// The next upcoming entry from [now] (wrapping to tomorrow's Fajr after
  /// Isha would be handled by the caller recomputing for the next day; here
  /// we return null once every time today has passed).
  ({String name, DateTime time})? nextAfter(DateTime now) {
    for (final e in schedule) {
      if (e.time.isAfter(now)) return e;
    }
    return null;
  }
}

/// Computes [PrayerTimes] for [date] at ([latitude], [longitude]) using the
/// device's local timezone offset. Defaults to Dhaka.
class PrayerTimesCalculator {
  const PrayerTimesCalculator({
    this.latitude = 23.8103,
    this.longitude = 90.4125,
    this.fajrAngle = 18.0,
    this.ishaAngle = 18.0,
    this.asrShadowFactor = 2, // Hanafi
  });

  final double latitude;
  final double longitude;
  final double fajrAngle;
  final double ishaAngle;

  /// 1 = Shafi/Maliki/Hanbali, 2 = Hanafi.
  final int asrShadowFactor;

  PrayerTimes forDate(DateTime date) {
    // Local midnight of the requested day, and the timezone offset in hours.
    final day = DateTime(date.year, date.month, date.day);
    final tzHours = day.timeZoneOffset.inMinutes / 60.0;

    final jd = _julianDate(day.year, day.month, day.day);
    // Sun declination + equation of time for solar noon.
    final sun = _sunPosition(jd);
    final decl = sun.declination;
    final eqt = sun.equationOfTime; // minutes

    // Solar noon (Dhuhr) in local time, hours.
    final dhuhr = 12.0 + tzHours - longitude / 15.0 - eqt / 60.0;

    // Hour angle (in hours) for the sun at a given ALTITUDE above the horizon
    // (negative = below the horizon, e.g. −0.833° for sunrise, −18° for Fajr).
    double hourAngleForAltitude(double altitudeDeg) {
      final lat = _rad(latitude);
      final d = _rad(decl);
      final alt = _rad(altitudeDeg);
      final cosH =
          (math.sin(alt) - math.sin(lat) * math.sin(d)) /
              (math.cos(lat) * math.cos(d));
      // Clamp so extreme latitudes don't produce NaN.
      final clamped = cosH.clamp(-1.0, 1.0);
      return _deg(math.acos(clamped)) / 15.0;
    }

    // Sunrise/sunset sit 0.833° below the horizon (atmospheric refraction).
    final riseSet = hourAngleForAltitude(-0.833);
    final sunrise = dhuhr - riseSet;
    final maghrib = dhuhr + riseSet;

    final fajr = dhuhr - hourAngleForAltitude(-fajrAngle);
    final isha = dhuhr + hourAngleForAltitude(-ishaAngle);

    // Asr: the sun's altitude when an object's shadow equals its own length
    // times the school's shadow factor, plus the noon shadow.
    final asrAltitude = _deg(
      math.atan(
        1 /
            (asrShadowFactor +
                math.tan(_rad((latitude - decl).abs()))),
      ),
    );
    final asr = dhuhr + hourAngleForAltitude(asrAltitude);

    DateTime at(double hours) {
      // Wrap negative / >24 into range then map to a DateTime on `day`.
      var h = hours % 24;
      if (h < 0) h += 24;
      final totalMinutes = (h * 60).round();
      return day.add(Duration(minutes: totalMinutes));
    }

    return PrayerTimes(
      fajr: at(fajr),
      sunrise: at(sunrise),
      dhuhr: at(dhuhr),
      asr: at(asr),
      maghrib: at(maghrib),
      isha: at(isha),
    );
  }

  // ── Astronomy helpers ────────────────────────────────────────────────

  double _rad(double deg) => deg * math.pi / 180.0;
  double _deg(double rad) => rad * 180.0 / math.pi;

  double _julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  ({double declination, double equationOfTime}) _sunPosition(double jd) {
    final d = jd - 2451545.0; // days since J2000
    final g = _rad((357.529 + 0.98560028 * d) % 360); // mean anomaly
    final q = (280.459 + 0.98564736 * d) % 360; // mean longitude
    final l = _rad(
      (q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) % 360,
    ); // ecliptic longitude

    final e = _rad(23.439 - 0.00000036 * d); // obliquity
    final declination = _deg(math.asin(math.sin(e) * math.sin(l)));

    // Equation of time in minutes.
    final ra = _deg(math.atan2(math.cos(e) * math.sin(l), math.cos(l))) / 15.0;
    final eqt = (q / 15.0) - ra;
    // Normalize to [-20, 20]-ish minutes range.
    var eqtMin = eqt * 60.0;
    if (eqtMin > 720) eqtMin -= 1440;
    if (eqtMin < -720) eqtMin += 1440;
    return (declination: declination, equationOfTime: eqtMin);
  }
}
