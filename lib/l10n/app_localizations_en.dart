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
  String get locationOutsideMapTitle => 'Location outside the map area';

  @override
  String get locationOutsideMapDescription =>
      'Your current location is outside the area covered by this offline map.';

  @override
  String get mapLoadError => 'The offline map could not be loaded.';

  @override
  String get retry => 'Try again';

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

  @override
  String get aucorsaAccountAccess => 'AUCORSA account';

  @override
  String get aucorsaAccountTitle => 'Connect your AUCORSA account';

  @override
  String get aucorsaAccountSubtitle =>
      'Sign in on AUCORSA\'s secure page to see all your linked cards, balances, and movements. Your password is never read or stored by this app.';

  @override
  String get aucorsaSignIn => 'Sign in';

  @override
  String get aucorsaCreateAccount => 'Create an account';

  @override
  String get chooseAnotherProvider => 'Choose another provider';

  @override
  String get aucorsaManageCards => 'Manage cards';

  @override
  String get aucorsaAddCard => 'Add card';

  @override
  String get aucorsaAddCardSubtitle =>
      'Link another card to your AUCORSA account';

  @override
  String get aucorsaCardNumber => 'Card number';

  @override
  String get aucorsaCardAdded => 'Card added';

  @override
  String get aucorsaNoCardsTitle => 'No linked cards';

  @override
  String get aucorsaNoCardsSubtitle =>
      'Add a card to your AUCORSA account, then return here to refresh it.';

  @override
  String get aucorsaCardMovements => 'Movement history';

  @override
  String get aucorsaCardMovementsSubtitle => 'View recent movements';

  @override
  String get aucorsaMovementOnlineTopUp => 'Online top-up';

  @override
  String get aucorsaMovementBusJourney => 'Bus journey';

  @override
  String get aucorsaMovementTransfer => 'Transfer';

  @override
  String get aucorsaDisconnect => 'Sign out';

  @override
  String get aucorsaDisconnectTitle => 'Sign out of AUCORSA?';

  @override
  String get aucorsaDisconnectSubtitle =>
      'This removes the AUCORSA website session from this device. Your account and linked cards will not be changed.';

  @override
  String get aucorsaDataError => 'AUCORSA data could not be loaded';

  @override
  String get retry => 'Retry';

  @override
  String get aucorsaSessionExpiredTitle => 'Session expired';

  @override
  String get aucorsaSessionExpiredSubtitle =>
      'Return to your cards and sign in to AUCORSA again.';

  @override
  String get aucorsaNoMovementsTitle => 'No movements';

  @override
  String get aucorsaNoMovementsSubtitle =>
      'AUCORSA did not return any movements for this page.';

  @override
  String aucorsaMovementsPage(int page) {
    return 'Page $page';
  }

  @override
  String get aucorsaRechargeActivated => 'Online top-up activated';

  @override
  String get aucorsaRechargePending =>
      'Online top-up pending activation. It will activate when the card is used on a bus validator.';

  @override
  String get aucorsaAvailableBalance => 'Available balance';
}
