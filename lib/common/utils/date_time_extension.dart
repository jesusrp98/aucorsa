import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// A short, locale-aware label such as `Jul 6, 6:33 PM`, dropping the year
  /// whenever it matches the current one.
  String get shortDateTimeLabel {
    final dateFormat = year == DateTime.now().year
        ? DateFormat.MMMd()
        : DateFormat.yMMMd();
    return dateFormat
        .addPattern('jm', ', ')
        .format(this)
        .replaceFirst(RegExp(r',(?=\s*\d{4}\b)'), '');
  }
}
