// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aucorsa GO!';

  @override
  String get settings => 'Settings';

  @override
  String get info => 'About';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose between light and dark';

  @override
  String get ratingTitle => 'Enjoying the app?';

  @override
  String get ratingSubtitle => 'Leave your review in the store';

  @override
  String get freeSoftwareTitle => 'This is free software';

  @override
  String get freeSoftwareSubtitle => 'Source code available for everyone';

  @override
  String get authorTitle => 'Created by Chechu R.';

  @override
  String get authorSubtitle => 'Well-designed free applications';

  @override
  String get emailTitle => 'Send me an email';

  @override
  String get emailSubtitle => 'Report bugs or request features';

  @override
  String get dataOriginTitle => 'Not affiliated with AUCORSA';

  @override
  String get dataOriginSubtitle =>
      'This application is not affiliated with nor the official app developed by AUCORSA. All information related to bus lines, routes, stops, and arrival times is provided by AUCORSA, the company responsible for urban public transport.\n\nThe main goal of this app is to facilitate intuitive and accessible access to public information, enhancing the experience of public transport users. We aim to promote sustainable and efficient mobility by offering tools that encourage the use of public transport as a convenient and responsible alternative for urban mobility.\n\nThis independent initiative is committed to providing accurate and up-to-date data, though it is important to note that AUCORSA is the original source of all information. We recommend always verifying the data with official channels to ensure maximum accuracy.';

  @override
  String get licenseTitle => 'Free software licenses';

  @override
  String versionTitle(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String busLine(String lineNumber) {
    return 'Line $lineNumber';
  }

  @override
  String get busLines => 'Lines';

  @override
  String get busStopTileFavorite => 'Favorite';

  @override
  String get busStopTileNoEstimations => 'No estimations available';

  @override
  String get busStopTileNow => 'Now';

  @override
  String get systemTheme => 'System theme';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get favoritesPageTitle => 'Favorites';

  @override
  String get noFavoritesTitle => 'No favorites';

  @override
  String get noFavoritesSubtitle => 'Tap here to see all the stops';

  @override
  String get stops => 'Stops';

  @override
  String get allStops => 'All stops';

  @override
  String get feriaEventDescription => 'Special services by AUCORSA';

  @override
  String get events => 'Events';

  @override
  String get feriaDialogBody =>
      'Take advantage of the special bus lines that will take you to the Feria de Córdoba';

  @override
  String get deleteStopTitle => 'Remove stop';

  @override
  String get deleteStopSubtitle =>
      'Are you sure you want to remove this stop from your favorites?';

  @override
  String get deleteStopCta => 'Remove';

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get locationPermissionDescription =>
      'Location access is permanently denied. Please open settings and enable it manually.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get editStopTitle => 'Edit name';

  @override
  String get deleteBonobusDialogTitle => 'Remove bonobus';

  @override
  String get deleteBonobusDialogSubtitle =>
      'Are you sure you want to remove bonobus details?';

  @override
  String get bonobus => 'Bonobus';

  @override
  String get aucorsa => 'Aucorsa';

  @override
  String get consorcio => 'Consorcio de Transporte Metropolitano';

  @override
  String lastUpdated(String time) {
    return 'Last updated $time';
  }

  @override
  String get scanBonobusTitle => 'Scan your bonobus';

  @override
  String get scanBonobusSubtitle => 'Use your device to read your balance';

  @override
  String get topUpBonobusTitle => 'Top up bonobus';

  @override
  String get topUpBonobusSubtitle => 'Learn more about it here';

  @override
  String get deleteBonobusTitle => 'Remove details';

  @override
  String get deleteBonobusSubtitle => 'This will remove it from the app';

  @override
  String get addBonobusTitle => 'Add your bonobus';

  @override
  String get addBonobusSubtitle =>
      'Select your bonobus provider before adding your card details';

  @override
  String get scanBonobusPageTitle => 'Scan your bonobus';

  @override
  String get scanBonobusPageSubtitle =>
      'Hold your bonobus card near the back of your device to scan it';

  @override
  String get stopsList => 'Stops list';
}
