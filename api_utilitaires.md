# APIs et services utilitaires — App Mobile Patient Gab'Pharma

**Date :** 14 juillet 2026
**Rôle du document :** lister, en dehors de l'API métier Django déjà couverte par `api_contrat_besoins.md`, les **services tiers externes** (clés API, comptes fournisseurs) et **paquets techniques** dont l'app mobile Patient aura besoin pour passer du mode démonstration à une app réellement opérationnelle. Pour chacun : libellé, description, comment l'obtenir, comment l'intégrer.

**Point de départ important, déjà tranché côté web** (`documentation/vitrine.md`, 9 juillet 2026) : le projet a explicitement choisi **OpenStreetMap + Leaflet (gratuit, sans clé API)** plutôt que Google Maps pour la cartographie, et un simple lien d'itinéraire Google Maps sans clé pour le bouton « Itinéraire ». **Recommandation : reproduire la même décision côté mobile**, sauf si tu veux explicitement une expérience carte native Google Maps (auquel cas il faut un compte de facturation Google Cloud — détaillé en §3).

---

## 1. Paiement réel — eBilling (Digitech Africa)

**Libellé :** passerelle de paiement Mobile Money / carte (Airtel Money, Moov Money, Visa).

**Description :** c'est **le seul fournisseur de paiement déjà retenu et scaffoldé** côté backend (`EBILLING_*` dans `gabpharma/settings.py` et `.env.example`, module `apps/payments/ebilling.py`). Aujourd'hui `EBILLING_ENABLED=false` : les paiements Airtel Money/Moov Money/Visa affichés dans l'app Flutter sont **simulés** (tirage aléatoire succès/échec ~70/30, comme documenté dans `CLAUDE.md`). C'est le point bloquant n°1 avant tout paiement réel, aussi bien web que mobile.

**Procédure d'acquisition :**
1. Contacter Digitech Africa (opérateur d'eBilling / Billing Easy) pour ouvrir un compte marchand Gab'Pharma — portail de test déjà connu : `https://test.billing-easy.net`.
2. Fournir les documents KYC entreprise (registre de commerce, pièce d'identité du représentant légal, RIB/compte bancaire ou Mobile Money de règlement).
3. Obtenir dans un premier temps des **identifiants de test/sandbox** (`EBILLING_USERNAME`, `EBILLING_SHARED_KEY`) pour valider le flux de bout en bout (checkout → paiement → callback).
4. Une fois validé, demander le **passage en production** : nouveaux identifiants, domaine HTTPS public confirmé pour le callback (`/paiements/ebilling/callback/`), et confirmation explicite du format/de l'authentification du callback — point de vigilance déjà noté dans `api_contrat.md` §7 (« l'authentification du callback eBilling doit encore être confirmée par le prestataire avant production »).
5. **Ne jamais committer les identifiants réels** — ils vont dans un fichier `.env` non versionné (voir `.env.example`, déjà en place).

**Procédure d'intégration :**
- **Côté Django (déjà fait à 90 %)** : renseigner les variables d'environnement (`EBILLING_ENABLED=true`, `EBILLING_USERNAME`, `EBILLING_SHARED_KEY`, `EBILLING_API_BASE_URL` de prod), confirmer `EBILLING_CALLBACK_CONTRACT_VERIFIED=true` seulement après validation du prestataire, puis tester avec `python manage.py test apps.payments`.
- **Côté Flutter :** rien à intégrer directement — le mobile appelle toujours `POST /mobile/patient/checkout/`. Le champ `payment.hosted_page_url` (déjà prévu dans le contrat API, `null` en mode simulé) devient une vraie URL eBilling à ouvrir dans un **WebView** ou via `url_launcher` (navigateur externe) pour que le patient saisisse son code Mobile Money. Ajouter le paquet `webview_flutter` si on choisit l'intégration in-app plutôt que le navigateur externe.
- Adapter l'écran 13 (Paiement) pour distinguer visuellement « paiement simulé » (état actuel) et « paiement réel eBilling » une fois la bascule faite, et supprimer le tirage aléatoire ~70/30 qui n'aura plus lieu d'être.

---

## 2. Notifications push — Firebase Cloud Messaging (FCM)

**Libellé :** notifications push (commande acceptée, livraison en cours, réponse support, etc.) reçues même app fermée.

**Description :** explicitement listé comme **hors contrat actuel** dans `api_contrat.md` §9. Aujourd'hui, l'écran 20 (Notifications) ne fonctionne qu'en flux agrégé tiré à l'ouverture de l'app (`GET /mobile/notifications/`) — rien n'arrive si l'app est fermée ou en arrière-plan.

**Procédure d'acquisition :**
1. Créer un projet sur [Firebase Console](https://console.firebase.google.com) (compte Google du studio/de l'entreprise, pas un compte personnel).
2. Ajouter une application Android (package `ga.gabpharma.gabpharma_patient`, déjà visible dans les commandes ADB du projet) → télécharger `google-services.json`.
3. Ajouter une application iOS si besoin (bundle id équivalent) → télécharger `GoogleService-Info.plist`.
4. Dans Firebase Console → Paramètres du projet → Comptes de service : générer une **clé de compte de service** (JSON) pour que le **backend Django** puisse envoyer des push (via `firebase-admin` côté Python).
5. Gratuit dans l'immense majorité des cas d'usage (FCM n'est pas facturé à l'envoi).

**Procédure d'intégration :**
- **Flutter :**
  - Ajouter les paquets `firebase_core` et `firebase_messaging` à `pubspec.yaml`.
  - Placer `google-services.json` dans `android/app/`, appliquer le plugin Gradle Google Services (`android/build.gradle` + `android/app/build.gradle`).
  - Placer `GoogleService-Info.plist` dans `ios/Runner/` si iOS visé.
  - Initialiser Firebase dans `main()`, demander la permission de notification (Android 13+/iOS), récupérer le `fcm_token` de l'appareil et l'envoyer au backend via un nouvel endpoint mobile (`POST /mobile/devices/` — à créer, avec un modèle `DeviceToken` côté Django : `user`, `token`, `platform`, `created_at`).
  - Gérer la réception au premier plan (`FirebaseMessaging.onMessage`), en arrière-plan (`onBackgroundMessage`) et au clic sur la notification (navigation vers l'écran cible via `target_type`/`target_id`, déjà présents dans le payload `GET /mobile/notifications/`).
- **Django :** ajouter `firebase-admin` à `requirements.txt`, créer un service d'envoi (ex. `apps/notifications/push.py`) déclenché aux mêmes points que les entrées du flux agrégé actuel (transition de commande, transition de livraison, nouvelle réponse de ticket).

---

## 3. Cartographie — deux options

### 3.1 Option recommandée : OpenStreetMap + Leaflet équivalent Flutter (gratuit, sans clé)

**Libellé :** carte interactive pour le suivi de livraison (écran 17) et le détail pharmacie (écran 09), cohérente avec le choix déjà fait côté web.

**Description :** le web (`apps/vitrine`) utilise déjà Leaflet + tuiles OpenStreetMap, sans clé API, décision explicitement actée par l'utilisateur (« vraie carte interactive OpenStreetMap + Leaflet, gratuit, sans clé API »). Aucun compte à créer, aucun coût, aucune limite de facturation à surveiller.

**Procédure d'acquisition :** aucune — les tuiles OSM publiques (`https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`) sont utilisables directement, à condition de respecter l'attribution obligatoire (« © OpenStreetMap contributors »), déjà appliquée côté web. Pour un usage à fort volume en production, prévoir de passer par un fournisseur de tuiles géré (ex. MapTiler, Stadia Maps — offres gratuites limitées puis payantes) plutôt que le serveur de tuiles public OSM, pour rester dans les conditions d'usage raisonnable.

**Procédure d'intégration :**
- Ajouter le paquet Flutter `flutter_map` (+ `latlong2` pour les coordonnées) à `pubspec.yaml`.
- Remplacer le fond dégradé illustratif actuel de l'écran 17 (`DeliveryTrackingScreen`, marqué explicitement « carte simplifiée, à titre illustratif » dans le code) par un vrai `FlutterMap` centré sur les coordonnées pharmacie/patient, avec marqueurs (pharmacie, livreur, destination).
- Les coordonnées existent déjà côté backend (`Pharmacy.latitude`/`longitude`) ; il manque la position du livreur en temps réel (voir §4, géolocalisation) et l'adresse géocodée du patient (le champ `delivery_address` est aujourd'hui du texte libre, pas des coordonnées — un géocodage, même approximatif par zone, serait nécessaire pour placer un marqueur précis).

### 3.2 Option alternative : Google Maps SDK natif (payant au-delà du crédit gratuit)

**Libellé :** carte native Google Maps (rendu, trafic, Street View, etc.).

**Description :** à envisager seulement si tu veux explicitement l'expérience Google Maps native plutôt que Leaflet/OSM. Implique un compte de facturation Google Cloud actif (carte bancaire obligatoire dès la création, même si un crédit gratuit mensuel existe).

**Procédure d'acquisition :**
1. Créer/utiliser un projet sur [Google Cloud Console](https://console.cloud.google.com).
2. Activer la facturation (obligatoire même pour rester sous le crédit gratuit).
3. Activer les API « Maps SDK for Android », « Maps SDK for iOS » (et éventuellement « Directions API », « Geocoding API » si on veut calculer un itinéraire/une distance précise côté serveur plutôt qu'un simple lien).
4. Générer une clé API, la **restreindre** immédiatement (par empreinte SHA-1 de l'app Android, par bundle id iOS) pour éviter tout abus si la clé fuite.

**Procédure d'intégration :**
- Paquet Flutter `google_maps_flutter`.
- Renseigner la clé dans `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`) et `ios/Runner/AppDelegate.swift`.
- **Ne jamais committer la clé en clair** dans le dépôt — utiliser `--dart-define` au build ou un fichier de config non versionné, à l'image de `AppConfig.demoMode` déjà utilisé dans le projet.

### 3.3 Bouton « Itinéraire » (sans clé, quelle que soit l'option ci-dessus)

**Libellé :** ouvrir l'app Maps du téléphone (Google Maps, Apple Plans, Waze...) pré-remplie avec l'itinéraire vers la pharmacie.

**Description :** exactement ce que fait déjà le web (« bouton Itinéraire vers Google Maps — schéma d'URL standard, pas de clé API »). Ne nécessite aucun compte, aucune clé — un simple lien.

**Procédure d'acquisition :** aucune.

**Procédure d'intégration :** paquet Flutter `url_launcher`, ouvrir `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` (fonctionne aussi sur iOS, redirige vers Google Maps ou le navigateur si l'app n'est pas installée). À ajouter sur l'écran 09 (Détail pharmacie), absent aujourd'hui du mockup Flutter réel.

---

## 4. Géolocalisation de l'appareil

**Libellé :** position GPS du patient, pour trier par proximité et afficher une distance réelle vers chaque pharmacie.

**Description :** explicitement listé comme **hors contrat actuel** (`api_contrat.md` §9) et déjà géré honnêtement côté Flutter aujourd'hui (message « indisponible en démonstration » plutôt qu'un faux tri). Ce n'est pas un service payant à souscrire — c'est une capacité de l'appareil, avec permission utilisateur à demander.

**Procédure d'acquisition :** aucune souscription — juste des déclarations de permission dans les projets natifs (voir intégration).

**Procédure d'intégration :**
- Paquet Flutter `geolocator`.
- Android : ajouter `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION` dans `android/app/src/main/AndroidManifest.xml`.
- iOS : ajouter `NSLocationWhenInUseUsageDescription` dans `ios/Runner/Info.plist` (texte affiché à l'utilisateur expliquant pourquoi l'app demande sa position).
- Demander la permission au moment pertinent (ex. à l'ouverture de l'écran Recherche/Accueil, pas au lancement de l'app), gérer le refus proprement (garder le comportement actuel « indisponible » si refusé).
- Calcul de distance : simple formule de Haversine côté Flutter à partir de `Pharmacy.latitude`/`longitude` (déjà renvoyées par l'API) — pas besoin d'API externe pour ce calcul.

---

## 5. E-mail transactionnel de production

**Libellé :** envoi réel des e-mails de sécurité (codes 2FA, confirmation de mot de passe, accusé de réception d'inscription, etc.).

**Description :** aujourd'hui, `EMAIL_BACKEND` pointe vers **MailHog en local** (`127.0.0.1:1025`, capture les e-mails sans les envoyer réellement — c'est ce qui a permis de confirmer le format à 6 chiffres du code 2FA, déjà noté dans `CLAUDE.md`). Sans un vrai relais SMTP en production, aucun e-mail (2FA compris) n'atteindra un vrai patient.

**Procédure d'acquisition :** deux options courantes :
- **SMTP simple** : une boîte e-mail professionnelle du domaine `gabpharma.ga` avec accès SMTP (souvent fourni par l'hébergeur de domaine/Google Workspace/Microsoft 365) — suffisant pour un volume modéré.
- **Service transactionnel dédié** (recommandé au-delà de quelques centaines d'e-mails/jour, meilleure délivrabilité, tableau de bord de suivi) : ex. Brevo (ex-Sendinblue), SendGrid, Mailgun, Amazon SES. Créer un compte, vérifier le domaine `gabpharma.ga` (enregistrements DNS SPF/DKIM/DMARC — important pour ne pas finir en spam), obtenir les identifiants SMTP ou une clé API.

**Procédure d'intégration :**
- Renseigner `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_USE_TLS` dans les variables d'environnement de production (déjà prévues dans `.env.example`, juste à remplir).
- Rien à changer côté Flutter — l'envoi d'e-mail est entièrement backend.
- Prévoir les enregistrements DNS SPF/DKIM avant le lancement pour éviter que les codes 2FA arrivent en spam (point de friction critique pour un flux d'authentification).

---

## 6. SMS (à trancher — écart avec l'implémentation Flutter actuelle)

**Libellé :** envoi de SMS, notamment pour le code de remise de livraison.

**Description :** ⚠️ **écart à signaler explicitement.** L'écran 17 (Suivi de livraison) affiche aujourd'hui « Code de remise envoyé par SMS (canal sécurisé) ». Or, dans le backend actuel, **aucune passerelle SMS n'existe** : la 2FA et tous les codes de sécurité (`OneTimeCode`) passent exclusivement par e-mail (`OneTimeCode.target_email`, `send_security_code`). Deux options :
- **Option A (recommandée si aucun budget SMS n'est prévu) :** corriger le texte Flutter pour dire « envoyé par e-mail » au lieu de « par SMS », cohérent avec la réalité backend, sans rien construire de nouveau.
- **Option B :** construire une vraie intégration SMS si le produit veut réellement ce canal (courant en Afrique centrale pour les codes de livraison, plus fiable qu'un e-mail que le patient ne consultera pas dans la rue).

**Procédure d'acquisition (si Option B retenue) :**
1. Choisir un fournisseur SMS couvrant le Gabon : agrégateurs pertinents en Afrique — Africa's Talking, Orange SMS API (si partenariat opérateur), ou une passerelle locale via Airtel/Moov Gabon. Twilio couvre peu ou mal le Gabon en envoi direct — à vérifier au cas par cas avant de s'engager.
2. Ouvrir un compte, obtenir une clé API et un identifiant d'expéditeur (« sender ID »/nom affiché).
3. Tester en sandbox avant un vrai numéro gabonais, valider le coût par SMS (facturé à l'unité, à budgétiser selon le volume de livraisons).

**Procédure d'intégration (si Option B retenue) :**
- Entièrement côté Django : ajouter un module `apps/notifications/sms.py` (ou équivalent), appelé au moment où le livreur confirme la collecte (`pickup`), en parallèle ou remplacement de l'e-mail actuel.
- Rien à changer côté Flutter — le texte de l'écran 17 devient enfin exact tel quel.

---

## 7. Paquets Flutter sans service externe (fonctionnalités déjà promises par l'UI actuelle)

Ces éléments ne nécessitent **aucun compte ni clé API** — seulement l'ajout d'un paquet `pubspec.yaml` et, pour certains, une permission native. Ils débloquent des fonctionnalités aujourd'hui affichées comme « indisponible en démonstration » dans l'app.

| Besoin | Paquet Flutter | Écran(s) concerné(s) | Permissions natives |
|---|---|---|---|
| Stockage sécurisé des jetons JWT (`access`/`refresh`) | `flutter_secure_storage` | Toute l'app (post-connexion) | Aucune — utilise Keystore Android / Keychain iOS |
| Sélection de pièce jointe (ticket support) | `file_picker` ou `image_picker` | 21 (Créer une demande), 22 (Conversation) | Accès stockage/galerie |
| Biométrie (Touch ID / Face ID) | `local_auth` | 24 (Sécurité et paramètres) | `USE_BIOMETRIC` (Android), `NSFaceIDUsageDescription` (iOS) |
| Appel téléphonique réel (pharmacie, support, livreur) | `url_launcher` (`tel:` scheme) | 09, 16, 17, 21 | Aucune (délègue à l'app Téléphone) |
| Ouverture WebView pour paiement eBilling | `webview_flutter` (voir §1) | 13 | Aucune |

**Procédure d'acquisition :** aucune — ce sont des dépendances open source publiées sur [pub.dev](https://pub.dev).

**Procédure d'intégration commune :** ajouter la ligne dans `pubspec.yaml` sous `dependencies:`, lancer `flutter pub get`, déclarer les permissions nécessaires dans `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist`, puis remplacer les `SnackBar` « indisponible en démonstration » actuelles par l'appel réel au paquet, écran par écran.

---

## 8. Optionnel — supervision et qualité (recommandé mais non bloquant)

### 8.1 Suivi d'erreurs / crash reporting

**Libellé :** remontée automatique des crashs et exceptions en production.

**Description :** l'audit backend (`documentation/audit.md`) note déjà l'absence de Sentry ou équivalent côté Django. Côté mobile, sans outil de ce type, un crash chez un patient reste invisible tant qu'il ne le signale pas lui-même via le Centre d'aide.

**Procédure d'acquisition :** créer un compte sur [Sentry](https://sentry.io) (offre gratuite limitée suffisante pour démarrer) ou activer **Firebase Crashlytics** si Firebase est déjà en place pour le push (§2) — évite de gérer un compte supplémentaire.

**Procédure d'intégration :**
- Firebase Crashlytics : paquet `firebase_crashlytics`, initialisation dans `main()` juste après Firebase Core, capture automatique des erreurs non gérées (`FlutterError.onError`).
- Sentry : paquet `sentry_flutter`, DSN de projet à renseigner (hors dépôt versionné), même logique d'initialisation.

### 8.2 Analytics produit (optionnel)

**Libellé :** mesure d'usage (écrans vus, taux de conversion checkout, etc.).

**Description :** non demandé explicitement dans la spec, purement optionnel pour piloter le produit après lancement.

**Procédure d'acquisition :** Firebase Analytics (gratuit, même projet Firebase que §2/§8.1) ou Mixpanel/Amplitude si un besoin plus poussé de funnel apparaît.

**Procédure d'intégration :** paquet `firebase_analytics`, appels `logEvent()` aux points clés (ajout panier, checkout, paiement réussi) — à ne construire qu'après validation du besoin, pas par défaut.

---

## 9. Récapitulatif — ce qu'il faut vraiment acquérir avant le lancement

| Service | Bloquant pour le lancement ? | Compte à créer | Coût |
|---|---|---|---|
| eBilling (Digitech Africa) | **Oui** — sans lui, aucun paiement Mobile Money/carte réel | Oui | Commission par transaction (à négocier avec le prestataire) |
| E-mail transactionnel de production | **Oui** — sans lui, la 2FA et l'inscription ne fonctionnent pas en vrai | Oui (SMTP pro ou service dédié) | Faible à modéré selon volume |
| OpenStreetMap/Leaflet (carte) | Non bloquant — l'écran 17 fonctionne déjà en mode illustratif honnête | Non | Gratuit |
| Géolocalisation device | Non bloquant — déjà géré honnêtement en absence | Non | Gratuit |
| Firebase Cloud Messaging | Non bloquant — les notifications fonctionnent déjà en flux agrégé à l'ouverture | Oui | Gratuit |
| Google Maps SDK natif | Non — alternative optionnelle à OSM/Leaflet | Oui si retenu | Payant au-delà du crédit gratuit |
| SMS | Non bloquant si on corrige le texte Flutter (Option A, §6) | Selon décision | Payant si Option B |
| Sentry / Crashlytics | Non bloquant, fortement recommandé | Oui | Gratuit en offre de base |
