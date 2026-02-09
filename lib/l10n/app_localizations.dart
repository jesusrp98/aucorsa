import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Aucorsa GO!'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get info;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose between light and dark'**
  String get appearanceSubtitle;

  /// No description provided for @ratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying the app?'**
  String get ratingTitle;

  /// No description provided for @ratingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave your review in the store'**
  String get ratingSubtitle;

  /// No description provided for @freeSoftwareTitle.
  ///
  /// In en, this message translates to:
  /// **'This is free software'**
  String get freeSoftwareTitle;

  /// No description provided for @freeSoftwareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Source code available for everyone'**
  String get freeSoftwareSubtitle;

  /// No description provided for @authorTitle.
  ///
  /// In en, this message translates to:
  /// **'Created by Chechu R.'**
  String get authorTitle;

  /// No description provided for @authorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Well-designed free applications'**
  String get authorSubtitle;

  /// No description provided for @emailTitle.
  ///
  /// In en, this message translates to:
  /// **'Send me an email'**
  String get emailTitle;

  /// No description provided for @emailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report bugs or request features'**
  String get emailSubtitle;

  /// No description provided for @dataOriginTitle.
  ///
  /// In en, this message translates to:
  /// **'Not affiliated with AUCORSA'**
  String get dataOriginTitle;

  /// No description provided for @dataOriginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This application is not affiliated with nor the official app developed by AUCORSA. All information related to bus lines, routes, stops, and arrival times is provided by AUCORSA, the company responsible for urban public transport.\n\nThe main goal of this app is to facilitate intuitive and accessible access to public information, enhancing the experience of public transport users. We aim to promote sustainable and efficient mobility by offering tools that encourage the use of public transport as a convenient and responsible alternative for urban mobility.\n\nThis independent initiative is committed to providing accurate and up-to-date data, though it is important to note that AUCORSA is the original source of all information. We recommend always verifying the data with official channels to ensure maximum accuracy.'**
  String get dataOriginSubtitle;

  /// No description provided for @licenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Free software licenses'**
  String get licenseTitle;

  /// No description provided for @versionTitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String versionTitle(String version, String buildNumber);

  /// No description provided for @busLine.
  ///
  /// In en, this message translates to:
  /// **'Line {lineNumber}'**
  String busLine(String lineNumber);

  /// No description provided for @busLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get busLines;

  /// No description provided for @busStopTileFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get busStopTileFavorite;

  /// No description provided for @busStopTileNoEstimations.
  ///
  /// In en, this message translates to:
  /// **'No estimations available'**
  String get busStopTileNoEstimations;

  /// No description provided for @busStopTileNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get busStopTileNow;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @favoritesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesPageTitle;

  /// No description provided for @noFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavoritesTitle;

  /// No description provided for @noFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap here to see all the stops'**
  String get noFavoritesSubtitle;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops;

  /// No description provided for @allStops.
  ///
  /// In en, this message translates to:
  /// **'All stops'**
  String get allStops;

  /// No description provided for @feriaEventDescription.
  ///
  /// In en, this message translates to:
  /// **'Special services by AUCORSA'**
  String get feriaEventDescription;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @feriaDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Take advantage of the special bus lines that will take you to the Feria de Córdoba'**
  String get feriaDialogBody;

  /// No description provided for @deleteStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get deleteStopTitle;

  /// No description provided for @deleteStopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this stop from your favorites?'**
  String get deleteStopSubtitle;

  /// No description provided for @deleteStopCta.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deleteStopCta;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Location access is permanently denied. Please open settings and enable it manually.'**
  String get locationPermissionDescription;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @editStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editStopTitle;

  /// No description provided for @deleteBonobusDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove bonobus'**
  String get deleteBonobusDialogTitle;

  /// No description provided for @deleteBonobusDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove bonobus details?'**
  String get deleteBonobusDialogSubtitle;

  /// No description provided for @bonobus.
  ///
  /// In en, this message translates to:
  /// **'Bonobus'**
  String get bonobus;

  /// No description provided for @aucorsa.
  ///
  /// In en, this message translates to:
  /// **'Aucorsa'**
  String get aucorsa;

  /// No description provided for @consorcio.
  ///
  /// In en, this message translates to:
  /// **'Consorcio de Transporte Metropolitano'**
  String get consorcio;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String lastUpdated(String time);

  /// No description provided for @scanBonobusTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan your bonobus'**
  String get scanBonobusTitle;

  /// No description provided for @scanBonobusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your device to read your balance'**
  String get scanBonobusSubtitle;

  /// No description provided for @topUpBonobusTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up bonobus'**
  String get topUpBonobusTitle;

  /// No description provided for @topUpBonobusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn more about it here'**
  String get topUpBonobusSubtitle;

  /// No description provided for @deleteBonobusTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove details'**
  String get deleteBonobusTitle;

  /// No description provided for @deleteBonobusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will remove it from the app'**
  String get deleteBonobusSubtitle;

  /// No description provided for @addBonobusTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your bonobus'**
  String get addBonobusTitle;

  /// No description provided for @addBonobusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your bonobus provider before adding your card details'**
  String get addBonobusSubtitle;

  /// No description provided for @scanBonobusPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan your bonobus'**
  String get scanBonobusPageTitle;

  /// No description provided for @scanBonobusPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold your bonobus card near the back of your device to scan it'**
  String get scanBonobusPageSubtitle;

  /// No description provided for @stopsList.
  ///
  /// In en, this message translates to:
  /// **'Stops list'**
  String get stopsList;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
