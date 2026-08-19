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
  String get editBonobusTitle => 'Edit card number';

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
  String get aucorsaUseAccount => 'Sign in or create account';

  @override
  String get aucorsaAccountTitle => 'Connect your AUCORSA account';

  @override
  String get aucorsaMovementsAccountSubtitle =>
      'Sign in with your AUCORSA account to view the movements of this bonobus. This card must already be linked to that account. Your password is never read or stored by this app.';

  @override
  String get aucorsaMovementsHelpTitle => 'Help';

  @override
  String get aucorsaMovementsHelpIntro =>
      'AUCORSA only serves the movements of a card to a user account that has that card added, and it also requires the account and the bonobus to share the same DNI or NIF. That is why an account is needed: the app signs in to aucorsa.es for you and asks for the movements of the card with that session. Without an account that meets both conditions AUCORSA returns nothing, no matter how many times the card is scanned.';

  @override
  String get aucorsaMovementsHelpStepsTitle => 'What you need to do';

  @override
  String get aucorsaMovementsHelpStepAccountTitle =>
      'Create an AUCORSA account';

  @override
  String get aucorsaMovementsHelpStepAccountSubtitle =>
      'Create the account on aucorsa.es. AUCORSA asks for your name, an email address, a password and a DNI or NIF, which has to be the same one the bonobus is registered under. If you already have an account, go straight to step 4.';

  @override
  String get aucorsaMovementsHelpStepActivateTitle =>
      'Activate the account from your email';

  @override
  String get aucorsaMovementsHelpStepActivateSubtitle =>
      'AUCORSA sends a confirmation email right after registering. The account stays inactive until you open the link inside that email, and signing in before doing so always fails. Check your spam folder if it does not arrive.';

  @override
  String get aucorsaMovementsHelpStepCardTitle =>
      'Add this card to your account';

  @override
  String get aucorsaMovementsHelpStepCardSubtitle =>
      'In your account, open the My cards section of aucorsa.es and register the number printed on the bonobus. Only the cards linked to the account you sign in with report their movements.';

  @override
  String get aucorsaMovementsHelpStepSignInTitle => 'Sign in from the app';

  @override
  String get aucorsaMovementsHelpStepSignInSubtitle =>
      'Sign in with that same account. The session stays on this device, so you only have to do this again if AUCORSA closes it.';

  @override
  String get aucorsaMovementsHelpStepRefreshTitle => 'Refresh the history';

  @override
  String get aucorsaMovementsHelpStepRefreshSubtitle =>
      'Pull down on the movement list to ask AUCORSA for it again. A journey or a top-up can take a few minutes to show up there.';

  @override
  String get aucorsaCardNumber => 'Card number';

  @override
  String get aucorsaCardMovements => 'Movement history';

  @override
  String get aucorsaCardMovementsSubtitle => 'View recent movements';

  @override
  String get aucorsaMovementOnlineTopUp => 'Online top-up';

  @override
  String get aucorsaMovementOnlineTopUpPending => 'Pending online top-up';

  @override
  String get aucorsaMovementBusJourney => 'Bus journey';

  @override
  String get aucorsaMovementTransfer => 'Transfer';

  @override
  String get aucorsaDataError => 'AUCORSA data could not be loaded';

  @override
  String get aucorsaMovementsUnavailableTitle => 'Movement history unavailable';

  @override
  String get aucorsaMovementsUnavailableSubtitle =>
      'We couldn\'t load the movement history for this bonobus. Check the help button at the top and try again.';

  @override
  String get aucorsaNoMovementsTitle => 'No movements';

  @override
  String get aucorsaNoMovementsSubtitle =>
      'AUCORSA did not return any movements for this bonobus. Check the help button at the top to make sure this card is linked to your account.';
}
