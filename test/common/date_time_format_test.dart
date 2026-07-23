import 'package:aucorsa/common/utils/date_time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => Intl.defaultLocale = 'en');

  test('omits the year when formatting a date in the current year', () {
    expect(
      formatShortDateTime(
        DateTime(2026, 7, 6, 18, 33),
        now: DateTime(2026, 7, 19),
      ),
      'Jul 6, 6:33\u202fPM',
    );
  });

  test('includes the year when formatting a date from another year', () {
    expect(
      formatShortDateTime(
        DateTime(2025, 7, 6, 18, 33),
        now: DateTime(2026, 7, 19),
      ),
      'Jul 6 2025, 6:33\u202fPM',
    );
  });
}
