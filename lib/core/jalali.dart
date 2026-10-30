/// Jalali (Solar Hijri) calendar utilities powered by the well-known
/// jalaali-js algorithm. Dates are plain [DateTime] values (Gregorian) at
/// local midnight; only presentation uses the Jalali form.
library;

class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  String toString() => '$year/$month/$day';
}

class Jalali {
  static const monthNames = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const weekDays = <String>[
    'شنبه',
    'یک‌شنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنج‌شنبه',
    'جمعه',
  ];

  static const weekDaysShort = <String>[
    'ش',
    'ی',
    'د',
    'س',
    'چ',
    'پ',
    'ج',
  ];

  static int _div(int a, int b) => (a / b).truncate();
  static int _mod(int a, int b) => a - _div(a, b) * b;

  static int _g2d(int gy, int gm, int gd) {
    var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
        _div(153 * _mod(gm + 9, 12) + 2, 5) +
        gd -
        34840408;
    d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
    return d;
  }

  static List<int> _d2g(int jdn) {
    var j = 4 * jdn + 139361631;
    j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
    final i = _div(_mod(j, 1461), 4) * 5 + 308;
    final gd = _div(_mod(i, 153), 5) + 1;
    final gm = _mod(_div(i, 153), 12) + 1;
    final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
    return [gy, gm, gd];
  }

  static Map<String, int> _jalCal(int jy) {
    const breaks = [
      -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 1701, //
      1796, 1856, 1917, 2008, 2121, 2160, 2201, 2262, 2324, 2394, 2456, 3178,
    ];
    final bl = breaks.length;
    final gy = jy + 621;
    var leapJ = -14;
    var jp = breaks[0];
    var jm = 0;
    var jump = 0;
    var leap = 0;

    if (jy < jp || jy >= breaks[bl - 1]) {
      // Out of the supported range — the algorithm still works for the
      // neighbouring years, so fall back to the closest supported band.
      jp = breaks[0];
    }

    for (var i = 1; i < bl; i++) {
      jm = breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      leapJ = leapJ + _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
      jp = jm;
    }
    var n = jy - jp;
    leapJ = leapJ + _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
    if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;

    final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
    final march = 20 + leapJ - leapG;

    if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
    leap = _mod(_mod(n + 1, 33) - 1, 4);
    if (leap == -1) leap = 4;

    return {'leap': leap, 'gy': gy, 'march': march};
  }

  static JalaliDate fromDateTime(DateTime date) {
    final jdn = _g2d(date.year, date.month, date.day);
    var gy = _d2g(jdn)[0];
    var jy = gy - 621;
    final r = _jalCal(jy);
    final jdn1f = _g2d(gy, 3, r['march']!);
    var k = jdn - jdn1f;
    var jm = 0;
    var jd = 0;

    if (k >= 0) {
      if (k <= 185) {
        jm = 1 + _div(k, 31);
        jd = _mod(k, 31) + 1;
        return JalaliDate(jy, jm, jd);
      }
      k -= 186;
    } else {
      jy -= 1;
      k += 179;
      if (r['leap'] == 1) k += 1;
    }
    jm = 7 + _div(k, 30);
    jd = _mod(k, 30) + 1;
    return JalaliDate(jy, jm, jd);
  }

  static String monthName(int month) => monthNames[(month - 1).clamp(0, 11)];

  /// Index of the day inside a Saturday-first week (0 = Saturday).
  static int weekIndex(DateTime date) => (date.weekday % 7 + 1) % 7;

  static String dayName(DateTime date) => weekDays[weekIndex(date)];

  static String dayNameShort(DateTime date) => weekDaysShort[weekIndex(date)];
}

String faDigits(Object? value) {
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final s = value?.toString() ?? '';
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final i = en.indexOf(ch);
    sb.write(i == -1 ? ch : fa[i]);
  }
  return sb.toString();
}

String two(int n) => n < 10 ? '0$n' : '$n';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime fromKey(String key) => DateTime.parse(key);

String todayKey() => dateKey(DateTime.now());

String jalaliLong(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${Jalali.dayName(d)} ${faDigits(j.day)} ${Jalali.monthName(j.month)} ${faDigits(j.year)}';
}

String jalaliShort(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${faDigits(j.day)} ${Jalali.monthName(j.month)}';
}

String jalaliNumeric(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${faDigits(j.year)}/${faDigits(j.month)}/${faDigits(j.day)}';
}

/// "امروز" / "فردا" / "دیروز" when applicable, otherwise the short date.
String friendlyDate(DateTime d) {
  final today = dateOnly(DateTime.now());
  final diff = dateOnly(d).difference(today).inDays;
  return switch (diff) {
    0 => 'امروز',
    1 => 'فردا',
    -1 => 'دیروز',
    _ => jalaliShort(d),
  };
}

/// Saturday-first start of the week containing [d].
DateTime startOfWeek(DateTime d) {
  final date = dateOnly(d);
  return date.subtract(Duration(days: Jalali.weekIndex(date)));
}

int daysInJalaliMonth(int year, int month) {
  final start = jalaliToDateTime(year, month, 1);
  final next = month == 12
      ? jalaliToDateTime(year + 1, 1, 1)
      : jalaliToDateTime(year, month + 1, 1);
  return next.difference(start).inDays;
}

/// Exact Jalali -> Gregorian conversion (same math as jalaali-js `j2d`).
DateTime jalaliToDateTime(int jy, int jm, int jd) {
  final r = Jalali._jalCal(jy);
  final jdn = Jalali._g2d(r['gy']!, 3, r['march']!) +
      (jm - 1) * 31 -
      Jalali._div(jm, 7) * (jm - 7) +
      jd -
      1;
  final g = Jalali._d2g(jdn);
  return DateTime(g[0], g[1], g[2]);
}
