# Dossier Technique : SafeChild Platform 🛡️

## 1. Présentation du Projet
**SafeChild** est une plateforme intégrée (Mobile + Web) dédiée à la recherche immédiate d'**enfants disparus**, d'**adultes vulnérables disparus** et de **personnes recherchées**, avec un système de validation préalable par les autorités pour garantir l'intégrité des alertes diffusées.p

## 2. Architecture Globale
Le système repose sur une architecture **Client-Serveur** :
*   **Backend (API) :** Laravel 11/12 (PHP 8.3) - Gestion des données, sécurité et notifications géolocalisées.
*   **Frontend Mobile :** Flutter (Dart) - Application multiplateforme (Android/iOS).
*   **Frontend Web :** Blade + Tailwind CSS - Interface d'administration et de validation pour les autorités.
*   **Base de Données :** MySQL - Stockage persistant et relationnel.

---

## 3. Spécifications Techniques

### 📱 Application Mobile (Flutter)
*   **Gestion d'État :** Riverpod (Architecture robuste et réactive).
*   **Navigation :** Système d'onglets (Home, My Reports, Map, Profile) avec `IndexedStack` pour la persistance de l'état.
*   **Cartographie :** Flutter Map (OpenStreetMap) - Visualisation avec filtres par catégorie, marqueurs différenciés et zones de danger.
*   **IA Embarquée :** Google ML Kit (Face Detection) - Analyse automatique des photos lors des signalements.
*   **Base de Données Locale :** Hive - Mode hors-ligne pour la consultation des alertes.
*   **Multilingue :** Service de localisation personnalisé (Français/Anglais).

### 🌐 Backend & API (Laravel)
*   **Authentification :** Laravel Sanctum (Système de jetons API sécurisés).
*   **Workflow d'Autorité :** Validation préalable obligatoire des alertes citoyennes avant diffusion publique et envoi des notifications.
*   **Géo-calculs :** Implémentation de la formule de **Haversine** pour le ciblage des alertes dans un rayon de 10km.
*   **Notifications :**
    *   **Push :** Firebase Cloud Messaging (FCM) avec messages contextualisés par type d'alerte.
    *   **SMS :** Passerelle Twilio (Prête pour production).
    *   **Email :** Mailable Laravel avec support SMTP/Mailtrap.
*   **Génération de Rapports :** DomPDF pour l'exportation des données officielles.

---

## 4. Fonctionnalités Clés Implémentées

1.  **Multi-catégories d'Alertes :** Prise en charge des enfants disparus (👶), adultes/vulnérables disparus (🧓) et avis de personnes recherchées (🚨).
2.  **Validation Préalable Obligatoire :** Toute alerte créée par un citoyen est mise en attente de vérification par les autorités policières avant d'être diffusée publiquement.
3.  **Diffusion Géociblée au Moment de la Validation :** Dès validation par l'autorité, diffusion instantanée d'une notification push aux citoyens dans un rayon de 10 km.
4.  **Signalements Citoyens (Sightings) :** Déclaration de repérages de témoins avec photo et coordonnées GPS directes.
5.  **Zones de Danger (Heatmap) :** Analyse de densité des signalements visualisée par des cercles de chaleur sur la carte.
6.  **Tableau de Bord Autorités :** Interface de supervision, filtres multi-catégories, validation/diffusion en un clic et export PDF officiel.

---

## 5. Sécurité et Confidentialité
*   **Hashage :** Mots de passe cryptés via l'algorithme Bcrypt (Laravel standard).
*   **Protection des Données :** Utilisation de `FlutterSecureStorage` pour les tokens sur mobile.
*   **Accès Restreint :** Interface web réservée exclusivement aux comptes ayant le rôle `authority`.
*   **Trafic :** Support du protocole HTTPS (configuré via `usesCleartextTraffic` pour le développement local).

---

## 6. Guide de Déploiement Local (Mode Hors-ligne)

### Pré-requis
*   PHP 8.3+ & Composer
*   Node.js & NPM
*   Flutter SDK
*   Serveur MySQL (
    XAMPP/WAMP)

### Installation Backend
```bash
cd safechild-api
composer install
npm install
npm run build
php artisan migrate
php artisan serve
```

### Installation Mobile
```bash
# Brancher le téléphone en USB (Débogage actif)
adb reverse tcp:8000 tcp:8000
cd safechild_app
flutter pub get
flutter run
```

---

## 7. Évolutions Futures
*   **IA de reconnaissance faciale :** Comparaison biométrique entre signalements et base de données.
*   **Tracking GPS Direct :** Suivi en temps réel d'un suspect aperçu par un témoin.
*   **Intégration Blockchain :** Horodatage immuable des preuves et signalements.

---
*Document généré le : 19 Mai 2026*
