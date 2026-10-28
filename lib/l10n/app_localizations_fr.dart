// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PharmaGuide TN';

  @override
  String get searchHint => 'Rechercher un médicament (nom, DCI, Darija)...';

  @override
  String get searchByCategory => 'Recherche par Catégorie';

  @override
  String get filterRadius => 'Rayon de recherche';

  @override
  String get filterCnam => 'Conventionnée CNAM uniquement';

  @override
  String get filterGarde => 'Pharmacies de garde uniquement';

  @override
  String get holdRequest => 'Réserver pour 2h';

  @override
  String get holdActive => 'Réservations Actives';

  @override
  String get holdExpires => 'Expire dans';

  @override
  String get holdStatus_pending => 'En attente';

  @override
  String get holdStatus_confirmed => 'Confirmée';

  @override
  String get holdStatus_expired => 'Expirée';

  @override
  String get holdStatus_declined => 'Refusée';

  @override
  String get holdStatus_collected => 'Récupérée';

  @override
  String get drugInteractions => 'Interactions Médicamenteuses';

  @override
  String get emergencyBroadcast => 'Alerte d\'Urgence';

  @override
  String get offlinePhonebook => 'Annuaire Hors-Ligne';

  @override
  String get prescriptionOcr => 'Scanner Ordonnance';

  @override
  String get chronicReminders => 'Rappels Chroniques';

  @override
  String get mapTitle => 'Carte de Tunisie';

  @override
  String get favorites => 'Favoris';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get pharmacyOpen => 'Ouverte';

  @override
  String get pharmacyClosed => 'Fermée';

  @override
  String get pharmacyGarde => 'De garde';

  @override
  String get inStock => 'En stock';

  @override
  String get outOfStock => 'Rupture de stock';

  @override
  String get distance => 'Distance';

  @override
  String get callPharmacy => 'Appeler';

  @override
  String get getDirections => 'Itinéraire';

  @override
  String get requiresPrescription => 'Ordonnance obligatoire';

  @override
  String get cnamReimbursable => 'Remboursable CNAM';

  @override
  String get sideEffects => 'Effets indésirables';

  @override
  String get contraindications => 'Contre-indications';

  @override
  String get interactions => 'Interactions';

  @override
  String get genericAlternatives => 'Alternatives Génériques';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get close => 'Fermer';

  @override
  String get loading => 'Chargement...';

  @override
  String get errorOccurred => 'Une erreur est survenue';

  @override
  String get allGovernoratesLabel => 'Tous les 24 gouvernorats';

  @override
  String get welcomeTitle => 'Bienvenue sur PharmaGuide TN';

  @override
  String get welcomeSubtitle =>
      'Trouvez vos médicaments en pharmacie, partout en Tunisie';

  @override
  String get onboardingStep1Title => 'Recherchez votre médicament';

  @override
  String get onboardingStep1Desc =>
      'Par nom commercial, DCI, ou même en Darija tunisien';

  @override
  String get onboardingStep2Title => 'Localisez la pharmacie';

  @override
  String get onboardingStep2Desc =>
      'Voyez en temps réel quelles pharmacies ont votre médicament en stock';

  @override
  String get onboardingStep3Title => 'Réservez pour 2 heures';

  @override
  String get onboardingStep3Desc =>
      'Votre médicament vous attend au guichet pendant 2h';

  @override
  String get getStarted => 'Commencer';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';
}
