import 'package:aucorsa/common/utils/date_time_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => Intl.defaultLocale = 'en');

  final currentYear = DateTime.now().year;

  test('omits the year when formatting a date in the current year', () {
    expect(
      DateTime(currentYear, 7, 6, 18, 33).shortDateTimeLabel,
      'Jul 6, 6:33 PM',
    );
  });

  test('includes the year when formatting a date from another year', () {
    expect(
      DateTime(currentYear - 1, 7, 6, 18, 33).shortDateTimeLabel,
      'Jul 6 ${currentYear - 1}, 6:33 PM',
    );
  });
}
