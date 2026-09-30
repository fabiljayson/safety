import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app actually ships translations for.
const List<String> _supportedLanguageCodes = ['en', 'fr'];

/// Language used when the device language is not translated, and on a fresh
/// install with no stored preference.
const String defaultLanguageCode = 'en';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale(defaultLanguageCode)) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    state = Locale(prefs.getString('language_code') ?? _deviceLanguage());
  }

  /// Picks the device language when it is one we translate, English otherwise.
  String _deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return _supportedLanguageCodes.contains(code) ? code : defaultLanguageCode;
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    state = locale;
  }
}

class AppTranslations {
  final Locale locale;
  const AppTranslations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'title': 'Safety',
      'login': 'Connexion',
      'register': 'Inscription',
      'email': 'Email',
      'password': 'Mot de passe',
      'name': 'Nom',
      'role': 'Rôle',
      'citizen': 'Citoyen',
      'parent': 'Parent',
      'authority': 'Autorité',
      'report_missing': 'Signaler une disparition',
      'logout': 'Déconnexion',
      'error': 'Erreur',
      'success_report': 'Alerte lancée avec succès !',
      'loading': 'Chargement...',
      'direct_stats': 'Statistiques en direct',
      'missing_children': 'Personnes recherchées',
      'certified_alerts': 'Alertes certifiées',
      'active_citizens': 'Citoyens actifs',
      'found_30d': 'Retrouvés (30j)',
      'your_reports': 'Vos signalements',
      'latest_alerts': 'Dernières Alertes',
      'certified': 'Certifiée',
      'pending': 'En attente',
      'missing': 'Disparu',
      'found': 'Retrouvé',
      'dark_mode': 'Mode Sombre',
      'language': 'Langue',
      'profile_info': 'Informations personnelles',
      'notif_prefs': 'Préférences de notifications',
      'security_privacy': 'Sécurité et Confidentialité',
      'help_center': 'Centre d\'aide',
      'about_safety': 'À propos de Safety',
      'safety_subtitle': 'Recherche et protection des personnes disparues',
      'app_version': 'Version 1.0.0',
      'sign_out': 'Se déconnecter',
      'map_title': 'Carte des Disparitions',
      'profile_title': 'Mon Profil',
      'reports_title': 'Mes Alertes',
      'home_title': 'Accueil',
      'hello': 'Bonjour',
      'welcome_back': 'Ensemble pour la recherche et la sécurité',
      'community_title': 'Communauté Safety',
      'community_info':
          'Partagez des témoignages ou des conseils pour aider la communauté.',
      'time_ago': 'Il y a 30 minutes',
      'comments': 'commentaires',
      'share': 'Partager',
      'later': 'Plus tard',
      'alert_launched': 'Alerte Lancée !',
      'ia_analysis_ready':
          'L\'IA a analysé la photo et votre signalement est prêt. Voulez-vous partager cette alerte ?',
      'critical_alert_btn': 'LANCER L\'ALERTE CRITIQUE',
      'add_child_photo': 'Ajouter une photo de l\'enfant',
      'basic_info': 'Informations de base',
      'physical_desc': 'Description physique',
      'child_name_hint': 'Nom complet de l\'enfant',
      'age_hint': 'Âge',
      'clothes_hint': 'Tenue vestimentaire au moment du départ',
      'desc_hint': 'Signes particuliers, lieu exact...',
      'ia_analyzing': 'IA : Analyse en cours...',
      'face_detected': 'Visage détecté',
      'my_position': 'Ma Position',
      'risk_zones': 'Zones Risque',
      'map_mode': 'Mode Carte',
      'no_reports': 'Vous n\'avez lancé aucune alerte.',
      'logout_confirm_title': 'Déconnexion',
      'logout_confirm_content':
          'Voulez-vous vraiment vous déconnecter de votre session ?',
      'cancel': 'ANNULER',
      'notifications': 'Notifications',
      'alert_kidnapping': 'Alerte Enlèvement',
      'notif_body':
          'Un signalement a été fait dans votre zone. Soyez vigilants.',
      'new_post': 'Nouveau message',
      'post_hint': 'Partagez votre message avec la communauté...',
      'publish': 'PUBLIER',
      'comment_hint': 'Écrire un commentaire...',
      'like': 'J\'aime',
      'no_account': 'Pas de compte ? S\'inscrire',
      'have_account': 'Déjà un compte ? Se connecter',
      // Added Keys
      'forgot_password_title': 'Mot de passe oublié ?',
      'code_sent': 'Code envoyé ! Vérifiez vos emails.',
      'reset_instructions':
          'Entrez le code à 6 chiffres reçu par email et votre nouveau mot de passe.',
      'forgot_instructions':
          'Entrez votre adresse email pour recevoir un code de réinitialisation.',
      'code_label': 'Code à 6 chiffres',
      'new_password_label': 'Nouveau mot de passe',
      'confirm_password_label': 'Confirmer le mot de passe',
      'receive_code_btn': 'RECEVOIR LE CODE',
      'reset_btn': 'RÉINITIALISER',
      'password_reset_success': 'Mot de passe réinitialisé !',
      'fill_fields': 'Veuillez remplir tous les champs',
      'enter_name': 'Veuillez entrer votre nom',
      'gps_required_alert':
          'Veuillez remplir tous les champs et autoriser le GPS.',
      'location_permission_denied':
          'Localisation indisponible. Autorisez la geolocalisation pour envoyer une alerte.',
      'retry': 'Reessayer',
      'location_service_off':
          'Activez la localisation de votre appareil pour envoyer une alerte.',
      'later_btn': 'Plus tard',
      'share_btn': 'PARTAGER',
      'processing_alert': 'Traitement de l\'alerte...',
      'disappeared_on': 'Disparu(e) le :',
      'particulars_desc_title': 'Signes particuliers & Description',
      'report_sighting_title': 'Signaler un aperçu',
      'sightings_reported_title': 'Aperçus signalés',
      'no_sightings_msg':
          'Aucun aperçu n\'a encore été signalé pour cet enfant.',
      'add_sighting_photo_hint': 'Ajouter une photo de l\'aperçu (Optionnel)',
      'gps_not_acquired': 'GPS non acquis',
      'activate_gps_btn': 'Activer GPS',
      'sighting_hint':
          'Où et comment avez-vous aperçu l\'enfant ? Détails sur sa tenue, les personnes à ses côtés...',
      'send_sighting_btn': 'ENVOYER LE SIGNALEMENT',
      'gps_sighting_required':
          'La localisation GPS est requise pour signaler un aperçu.',
      'sighting_success_msg': 'Signalement d\'aperçu envoyé avec succès !',
      'sighting_by': 'Par :',
      'sighting_at': 'à',
      'required': 'Champ requis',
      'alert_type_label': 'Type d\'alerte',
      'child_missing': 'Enfant disparu',
      'adult_missing': 'Adulte disparu',
      'wanted_person': 'Personne recherchée',
      'all_categories': 'Tous',
      'pending_approval': 'En attente de validation',
      'published_alert': 'Validée & Diffusée',
      'authority_notice_title': 'Validation obligatoire par les autorités',
      'authority_notice_desc':
          'Votre signalement sera vérifié et validé par les autorités avant diffusion publique et notifications d\'urgence.',
      'submit_for_review_btn': 'SOUMETTRE POUR VALIDATION',
      'alert_submitted_title': 'Signalement Enregistré !',
      'alert_submitted_desc':
          'Votre alerte a été transmise aux autorités. Une notification géolocalisée sera automatiquement diffusée dès sa validation officielle.',
      'filter_all': 'Tous',
      'filter_children': 'Enfants',
      'filter_adults': 'Adultes',
      'filter_wanted': 'Recherchés',
      'person_name_hint': 'Nom complet de la personne',
      'add_person_photo': 'Ajouter une photo',
      'year_old_one': 'an',
      'year_old_other': 'ans',
      'missing_since': 'Recherché depuis le',
      'nav_map': 'Carte',
      'nav_profile': 'Profil',
      'launch_alert_btn': 'LANCER UNE ALERTE',
      'share_alert_message':
          'ALERTE DISPARITION : {name}, {age} ans disparu(e). Aidez-nous à le/la retrouver ! #Safety',
      'report_and_details': 'Signaler & Détails',
      'no_description': 'Pas de description',
      'witness': 'Témoin',
      'understood': "OK, J'AI COMPRIS",
      'details': 'Détails',
      'close': 'Fermer',
      'user': 'Utilisateur',
      'points': 'Points',
      'connection_error_api':
          'Impossible de joindre le serveur. Vérifiez votre connexion.',
    },
    'en': {
      'title': 'Safety',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'role': 'Role',
      'citizen': 'Citizen',
      'parent': 'Parent',
      'authority': 'Authority',
      'report_missing': 'Report Missing Person',
      'logout': 'Logout',
      'error': 'Error',
      'success_report': 'Alert launched successfully!',
      'loading': 'Loading...',
      'direct_stats': 'Live Statistics',
      'missing_children': 'Missing Persons',
      'certified_alerts': 'Certified Alerts',
      'active_citizens': 'Active Citizens',
      'found_30d': 'Found (30d)',
      'your_reports': 'Your Reports',
      'latest_alerts': 'Latest Alerts',
      'certified': 'Certified',
      'pending': 'Pending',
      'missing': 'Missing',
      'found': 'Found',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'profile_info': 'Personal Information',
      'notif_prefs': 'Notification Preferences',
      'security_privacy': 'Security & Privacy',
      'help_center': 'Help Center',
      'about_safety': 'About Safety',
      'safety_subtitle': 'Missing persons search & rapid safety alerts',
      'app_version': 'Version 1.0.0',
      'sign_out': 'Sign Out',
      'map_title': 'Missing Map',
      'profile_title': 'My Profile',
      'reports_title': 'My Alerts',
      'home_title': 'Home',
      'hello': 'Hello',
      'welcome_back': 'Together for rapid search and safety',
      'community_title': 'Safety Community',
      'community_info': 'Share testimonials or tips to help the community.',
      'time_ago': '30 minutes ago',
      'comments': 'comments',
      'share': 'Share',
      'later': 'Later',
      'alert_launched': 'Alert Launched!',
      'ia_analysis_ready':
          'AI analyzed the photo and your report is ready. Do you want to share this alert?',
      'critical_alert_btn': 'LAUNCH CRITICAL ALERT',
      'add_child_photo': 'Add child photo',
      'basic_info': 'Basic Information',
      'physical_desc': 'Physical Description',
      'child_name_hint': 'Full name of the child',
      'age_hint': 'Age',
      'clothes_hint': 'Clothing at the time of departure',
      'desc_hint': 'Special signs, exact location...',
      'ia_analyzing': 'AI: Analysis in progress...',
      'face_detected': 'Face detected',
      'my_position': 'My Position',
      'risk_zones': 'Risk Zones',
      'map_mode': 'Map Mode',
      'no_reports': 'You have not launched any alerts.',
      'logout_confirm_title': 'Logout',
      'logout_confirm_content': 'Do you really want to sign out?',
      'cancel': 'CANCEL',
      'notifications': 'Notifications',
      'alert_kidnapping': 'Kidnapping Alert',
      'notif_body': 'A report has been made in your area. Be vigilant.',
      'new_post': 'New post',
      'post_hint': 'Share your message with the community...',
      'publish': 'PUBLISH',
      'comment_hint': 'Write a comment...',
      'like': 'Like',
      'no_account': 'No account? Register',
      'have_account': 'Already have an account? Login',
      // Added Keys
      'forgot_password_title': 'Forgot Password?',
      'code_sent': 'Code sent! Check your emails.',
      'reset_instructions':
          'Enter the 6-digit code received by email and your new password.',
      'forgot_instructions':
          'Enter your email address to receive a reset code.',
      'code_label': '6-digit code',
      'new_password_label': 'New password',
      'confirm_password_label': 'Confirm password',
      'receive_code_btn': 'RECEIVE CODE',
      'reset_btn': 'RESET',
      'password_reset_success': 'Password reset!',
      'fill_fields': 'Please fill in all fields',
      'enter_name': 'Please enter your name',
      'gps_required_alert': 'Please fill in all fields and allow GPS.',
      'location_permission_denied':
          'Location unavailable. Allow location access to send an alert.',
      'retry': 'Retry',
      'location_service_off':
          'Turn on your device location services to send an alert.',
      'later_btn': 'Later',
      'share_btn': 'SHARE',
      'processing_alert': 'Processing alert...',
      'disappeared_on': 'Disappeared on:',
      'particulars_desc_title': 'Special signs & Description',
      'report_sighting_title': 'Report Sighting',
      'sightings_reported_title': 'Reported Sightings',
      'no_sightings_msg': 'No sightings have been reported for this child yet.',
      'add_sighting_photo_hint': 'Add a photo of the sighting (Optional)',
      'gps_not_acquired': 'GPS not acquired',
      'activate_gps_btn': 'Activate GPS',
      'sighting_hint':
          'Where and how did you spot the child? Details on clothing, people accompanying them...',
      'send_sighting_btn': 'SEND REPORT',
      'gps_sighting_required': 'GPS location is required to report a sighting.',
      'sighting_success_msg': 'Sighting report sent successfully!',
      'sighting_by': 'By:',
      'sighting_at': 'at',
      'required': 'Required',
      'alert_type_label': 'Alert Type',
      'child_missing': 'Missing Child',
      'adult_missing': 'Missing Adult',
      'wanted_person': 'Wanted Person',
      'all_categories': 'All',
      'pending_approval': 'Pending Validation',
      'published_alert': 'Validated & Broadcasted',
      'authority_notice_title': 'Mandatory Authority Validation',
      'authority_notice_desc':
          'Your report will be reviewed and validated by authorities before public broadcast and emergency notifications.',
      'submit_for_review_btn': 'SUBMIT FOR REVIEW',
      'alert_submitted_title': 'Report Registered!',
      'alert_submitted_desc':
          'Your alert has been forwarded to the authorities. A geolocated alert will automatically be broadcast upon official approval.',
      'filter_all': 'All',
      'filter_children': 'Children',
      'filter_adults': 'Adults',
      'filter_wanted': 'Wanted',
      'person_name_hint': 'Full name of the person',
      'add_person_photo': 'Add photo',
      'year_old_one': 'year old',
      'year_old_other': 'years old',
      'missing_since': 'Missing since',
      'nav_map': 'Map',
      'nav_profile': 'Profile',
      'launch_alert_btn': 'LAUNCH AN ALERT',
      'share_alert_message':
          'MISSING PERSON ALERT: {name}, {age}, missing. Help us find them! #Safety',
      'report_and_details': 'Report & Details',
      'no_description': 'No description',
      'witness': 'Witness',
      'understood': 'GOT IT',
      'details': 'Details',
      'close': 'Close',
      'user': 'User',
      'points': 'Points',
      'connection_error_api':
          'Could not reach the server. Check your connection.',
    },
  };

  /// Every key defined for a language.
  ///
  /// Exposed so tooling and tests can assert that the English and French maps
  /// stay in lockstep; a key present in only one of them renders as raw
  /// snake_case in that language.
  static Set<String> keysFor(String languageCode) {
    return _localizedValues[languageCode]?.keys.toSet() ?? <String>{};
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  /// "5 years old" / "5 ans", with the correct singular form.
  ///
  /// French needs "an" for one and "ans" otherwise; picking the key by count
  /// keeps call sites free of locale comparisons.
  String ageLabel(int age) {
    return '$age ${translate(age == 1 ? 'year_old_one' : 'year_old_other')}';
  }

  /// "Missing since Sep 14, 2026", formatted for the active locale.
  String missingSince(DateTime date) {
    return '${translate('missing_since')} '
        '${DateFormat.yMMMd(locale.toString()).format(date)}';
  }

  /// Localised age for list rows, e.g. "8 - Missing".
  String ageOnly(int age) => age.toString();

  static AppTranslations of(BuildContext context) {
    return AppTranslations(Localizations.localeOf(context));
  }
}
