import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'PharmaGuide TN'**
  String get appTitle;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un médicament (nom, DCI, Darija)...'**
  String get searchHint;

  /// No description provided for @searchByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Recherche par Catégorie'**
  String get searchByCategory;

  /// No description provided for @filterRadius.
  ///
  /// In fr, this message translates to:
  /// **'Rayon de recherche'**
  String get filterRadius;

  /// No description provided for @filterCnam.
  ///
  /// In fr, this message translates to:
  /// **'Conventionnée CNAM uniquement'**
  String get filterCnam;

  /// No description provided for @filterGarde.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacies de garde uniquement'**
  String get filterGarde;

  /// No description provided for @holdRequest.
  ///
  /// In fr, this message translates to:
  /// **'Réserver pour 2h'**
  String get holdRequest;

  /// No description provided for @holdActive.
  ///
  /// In fr, this message translates to:
  /// **'Réservations Actives'**
  String get holdActive;

  /// No description provided for @holdExpires.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans'**
  String get holdExpires;

  /// No description provided for @holdStatus_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get holdStatus_pending;

  /// No description provided for @holdStatus_confirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get holdStatus_confirmed;

  /// No description provided for @holdStatus_expired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get holdStatus_expired;

  /// No description provided for @holdStatus_declined.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get holdStatus_declined;

  /// No description provided for @holdStatus_collected.
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get holdStatus_collected;

  /// No description provided for @drugInteractions.
  ///
  /// In fr, this message translates to:
  /// **'Interactions Médicamenteuses'**
  String get drugInteractions;

  /// No description provided for @emergencyBroadcast.
  ///
  /// In fr, this message translates to:
  /// **'Alerte d\'Urgence'**
  String get emergencyBroadcast;

  /// No description provided for @offlinePhonebook.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire Hors-Ligne'**
  String get offlinePhonebook;

  /// No description provided for @prescriptionOcr.
  ///
  /// In fr, this message translates to:
  /// **'Scanner Ordonnance'**
  String get prescriptionOcr;

  /// No description provided for @chronicReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels Chroniques'**
  String get chronicReminders;

  /// No description provided for @mapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte de Tunisie'**
  String get mapTitle;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @pharmacyOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte'**
  String get pharmacyOpen;

  /// No description provided for @pharmacyClosed.
  ///
  /// In fr, this message translates to:
  /// **'Fermée'**
  String get pharmacyClosed;

  /// No description provided for @pharmacyGarde.
  ///
  /// In fr, this message translates to:
  /// **'De garde'**
  String get pharmacyGarde;

  /// No description provided for @inStock.
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get outOfStock;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @callPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get callPharmacy;

  /// No description provided for @getDirections.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get getDirections;

  /// No description provided for @requiresPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance obligatoire'**
  String get requiresPrescription;

  /// No description provided for @cnamReimbursable.
  ///
  /// In fr, this message translates to:
  /// **'Remboursable CNAM'**
  String get cnamReimbursable;

  /// No description provided for @sideEffects.
  ///
  /// In fr, this message translates to:
  /// **'Effets indésirables'**
  String get sideEffects;

  /// No description provided for @contraindications.
  ///
  /// In fr, this message translates to:
  /// **'Contre-indications'**
  String get contraindications;

  /// No description provided for @interactions.
  ///
  /// In fr, this message translates to:
  /// **'Interactions'**
  String get interactions;

  /// No description provided for @genericAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Alternatives Génériques'**
  String get genericAlternatives;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorOccurred;

  /// No description provided for @allGovernoratesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tous les 24 gouvernorats'**
  String get allGovernoratesLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur PharmaGuide TN'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez vos médicaments en pharmacie, partout en Tunisie'**
  String get welcomeSubtitle;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez votre médicament'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Par nom commercial, DCI, ou même en Darija tunisien'**
  String get onboardingStep1Desc;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In fr, this message translates to:
  /// **'Localisez la pharmacie'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Voyez en temps réel quelles pharmacies ont votre médicament en stock'**
  String get onboardingStep2Desc;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In fr, this message translates to:
  /// **'Réservez pour 2 heures'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Votre médicament vous attend au guichet pendant 2h'**
  String get onboardingStep3Desc;

  /// No description provided for @getStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;
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
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
