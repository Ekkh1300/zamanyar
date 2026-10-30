import 'jalali.dart';

String greetingFor(int hour) {
  if (hour < 5) return 'شب به‌خیر';
  if (hour < 12) return 'صبح به‌خیر';
  if (hour < 17) return 'ظهر به‌خیر';
  if (hour < 20) return 'عصر به‌خیر';
  return 'شب به‌خیر';
}

/// "۱ ساعت و ۲۵ دقیقه" style human readable duration.
String prettyMinutes(int minutes) {
  if (minutes <= 0) return '۰ دقیقه';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${faDigits(m)} دقیقه';
  if (m == 0) return '${faDigits(h)} ساعت';
  return '${faDigits(h)} ساعت و ${faDigits(m)} دقیقه';
}

/// "۱:۲۵" clock style for totals above an hour.
String clockMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${faDigits(h)}:${faDigits(two(m))}';
}

String clockSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${faDigits(two(m))}:${faDigits(two(s))}';
}

String faTimeOfDay(String hhmm) {
  if (hhmm.isEmpty) return '';
  return faDigits(hhmm);
}

const _quotes = <String>[
  'تمرکز فقط این نیست که به چه چیزی فکر می‌کنی؛ این است که چه چیزی را نادیده می‌گیری.',
  'موفقیت مجموعه‌ای از عادت‌های کوچک است که هر روز تکرار می‌شوند.',
  'بهترین زمان برای شروع، همین حالاست؛ نه فردا.',
  'هر جلسهٔ تمرکز، یک آجر برای بنای آیندهٔ توست.',
  'آرام باش، منظم باش، ادامه بده.',
  'بدون برنامه، تلاش پراکنده می‌شود؛ با برنامه، تلاش معنا پیدا می‌کند.',
  '۲۵ دقیقهٔ متمرکز بهتر از ۳ ساعت پراکنده است.',
  'اگر نمی‌توانی پرواز کنی، بدو؛ اگر نمی‌توانی بدو، راه برو؛ فقط حرکت کن.',
  'پیشرفت کوچک، همیشه بهتر از هیچ است.',
  'خودت را با دیروزِ خودت مقایسه کن، نه با دیگران.',
];

String quoteOfToday(DateTime now) {
  final dayIndex = now.difference(DateTime(2020, 1, 1)).inDays;
  return _quotes[dayIndex.abs() % _quotes.length];
}
