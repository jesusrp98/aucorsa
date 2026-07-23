import 'package:intl/intl.dart';

String formatShortDateTime(DateTime dateTime, {DateTime? now}) {
  final currentDate = now ?? DateTime.now();
  final dateFormat = dateTime.year == currentDate.year
      ? DateFormat.MMMd()
      : DateFormat.yMMMd();
  return dateFormat
      .addPattern('jm', ', ')
      .format(dateTime)
      .replaceFirst(RegExp(r',(?=\s*\d{4}\b)'), '');
}
