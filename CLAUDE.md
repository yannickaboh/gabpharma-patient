# Gab'Pharma Patient — suivi d'implémentation Flutter

**Dernière mise à jour :** 4 septembre 2026
**Mode actuel :** branchement à l'API Django réelle en cours (`AppConfig.demoMode=false` par défaut). Les 24 écrans de la spec sont terminés visuellement depuis le 14 juillet ; le branchement module par module a démarré le 13 août et les 15 modules de `branchement_patient.md` (dont notifications push FCM) sont désormais branchés et vérifiés sur S8 physique. **Voir `branchement_patient.md` pour le détail module par module et l'ordre convenu — c'est la source de vérité pour cette phase, pas cette section.** Résumé : tous les modules d'authentification et fonctionnels (Accueil, Recherche+catalogue, Détail médicament/pharmacie, Favoris, Panier, Checkout, Paiement simulé, Commandes, Assurance, Notifications, Support, Profil, Inscription, Mot de passe oublié, Notifications push FCM) sont branchés et vérifiés, ainsi que les trois items "lourds" de `propositions_backend.md` : géolocalisation patient réelle (tri par proximité, distance affichée), écran "Parcourir les pharmacies" et verrouillage biométrique local (Touch ID / Face ID). **Le Suivi de livraison temps réel (écran 17) est désormais branché et vérifié** (position GPS du livreur, voir `branchement_patient.md`, session du 4 septembre 2026). Reste : la suppression/anonymisation définitive de compte (bloquée sur une décision produit/légale, pas technique) et les écrans 25/26 hors spec.

## Méthode de travail (à respecter pour chaque nouvel écran)

Pour chaque écran du dossier `stitch_gab_pharma_patient_app/<NN_nom_ecran>/` :
1. Lire la section correspondante dans `stitch_gab_pharma_patient_app/maquette_mobile_patient.md` (rôle fonctionnel, états attendus).
2. Ouvrir `screen.png` (source de vérité visuelle) ET `code.html` (valeurs exactes : couleurs, radius, paddings, tailles).
3. Si l'image et le code divergent, privilégier l'image et signaler l'écart à l'utilisateur.
4. Implémenter en Flutter/Material 3, tester sur le Samsung Galaxy S8 via ADB, et **attendre la validation visuelle de l'utilisateur avant de passer à l'écran suivant**.
5. Toujours dire en une phrase ce qui a été implémenté et les écarts assumés par rapport au mockup (pas de New devinette).

## État d'avancement des 26 écrans

**Les 24 écrans cibles de la spec (`stitch_gab_pharma_patient_app/maquette_mobile_patient.md`) sont terminés et validés.** Il ne reste que les écrans 25/26 (hors spec originale, à clarifier — voir plus bas) avant de passer à la connexion API.

### Lot 1 — Authentification (terminé et validé)
- [x] 01 Splash / restauration de session
- [x] 02 Connexion
- [x] 03 Vérification 2FA
- [x] 04 Inscription Patient (+ écrans Conditions générales et Politique de confidentialité, avec le vrai contenu du site web)
- [x] 05 Récupération / réinitialisation du mot de passe (parcours 3 étapes)

### Lot 2 — Recherche et achat (en cours)
- [x] 06 Accueil Patient
- [x] 07 Recherche et résultats
- [x] 08 Détail médicament (Doliprane 1000mg, choix pharmacie, conflit mono-pharmacie)
- [x] 09 Détail pharmacie (Pharmacie de la Garde)
- [x] 10 Favoris
- [x] 11 Panier (fidèle au mockup `11_panier` : titre pharmacie, +/- réels, vider le panier, état vide)
- [x] 12 Checkout (adresse/commune, méthode de réception, mode de paiement, récap réel du panier)
- [x] 13 Paiement (grille de modes, formulaire dynamique, simulation succès/échec ~70/30 comme le mockup)
- [x] 14 Confirmation de commande (référence copiable, confettis, données transmises de bout en bout depuis Checkout/Paiement)

**Lot 2 terminé et validé.**

### Lot 3 — Commandes, livraison, finances (terminé et validé)
- [x] 15 Liste des commandes (filtres Tout/En attente/En cours/Livré/Annulé réellement fonctionnels sur données de démo)
- [x] 16 Détail commande (bannière de statut, articles, sous-total/livraison/total, timeline de suivi, actions Accepter/Refuser/Annuler réellement interactives en local selon le statut)
- [x] 17 Suivi de livraison (carte réelle branchée depuis le 4 septembre 2026 — voir plus bas ; timeline réutilisée depuis l'écran 16 ; code de remise jamais affiché, seulement "envoyé par SMS")
- [x] 18 Paiements et remboursements (historique financier avec statuts paid/pending/failed/refund_pending/refunded, reprise de paiement en attente, totaux recalculés dynamiquement depuis la liste plutôt que copiés du mockup)

**Lot 3 terminé et validé.**

### Lot 4 — Assurance, assistance, compte (terminé et validé)
- [x] 19 Mon assurance (profil déclaratif pré-rempli, taux/dérogations par assureur informatifs, retrait d'affiliation réel)
- [x] 20 Notifications (filtres Tout/Commandes/Sécurité/Offres fonctionnels, chaque notification ouvre le bon écran, lu/non lu local éphémère)
- [x] 21 Centre d'aide et tickets (recherche + catégories filtrant les FAQ, priorité des tickets, création de ticket réelle avec commande liée)
- [x] 22 Conversation Support (une conversation cohérente par ticket, champ de réponse réellement câblé, réouverture d'un ticket résolu)
- [x] 23 Profil Patient (fait en avance, avec écran "Modifier mes informations")
- [x] 24 Sécurité et paramètres (changement de mot de passe avec règles de validation, session locale, préférences de notifications, 2FA non désactivable, déconnexion réelle)

**Lot 4 terminé et validé — les 24 écrans de la spec sont désormais tous construits.**

Écrans 25/26 (Mes vaccins, Certificat numérique) : présents dans le dossier Stitch mais **non listés dans le prompt/spec originale** (au-delà des 24 cibles) — à clarifier avec l'utilisateur avant implémentation.

## Décisions / conventions déjà actées (ne pas re-demander)

- **Palette et thème** : `lib/src/core/theme.dart`. Couleurs `GabColors.*`, cartes 16px, boutons/inputs 14px radius, bordures d'input visibles (`outlineVariant` au repos, `primary` au focus, `danger` en erreur).
- **Barre du haut partagée** : `PatientTopBar` (dans `widgets.dart`) — "Gab'Pharma" + cloche notifications + avatar — utilisée en tête fixe (non scrollable) sur les 5 onglets (`PatientShell`). Les écrans poussés (détail médicament, pharmacie, 2FA, reset password, etc.) utilisent leur propre en-tête back+titre, pas la barre partagée.
- **Bottom nav** : hauteur 68px, échelle de police système verrouillée à 1.0 sur cette barre spécifiquement (évite le débordement des libellés type "Commandes" si l'utilisateur a une police système agrandie).
- **Images distantes du mockup (photos IA Stitch)** : jamais téléchargées. Toujours remplacées par des dégradés de couleur + icônes Material cohérents avec la palette du projet (voir `_PharmacyProductCard`, hero pharmacie, hero inscription).
- **Honnêteté plutôt que fausse fonctionnalité** : si une action n'est pas réellement câblée (ex. tri par proximité sans géolocalisation, filtres Catégorie/Forme sans taxonomie, appel téléphonique sans plugin télécom, partage), afficher un message clair ("indisponible en démonstration" / "disponible une fois l'API connectée") plutôt que de simuler un faux résultat. Précédent : les boutons de connexion sociale Google/Facebook du mockup Connexion ont été **supprimés** (hors spec fonctionnelle, pas de backend OAuth) plutôt que rendus factices.
- **Règle mono-pharmacie** : le panier de démo (`CartScreen`) contient un article "Pharmacie du Centre" ; ajouter un article d'une autre pharmacie (ex. depuis le détail médicament) déclenche une boîte de dialogue de conflit avec option "Vider le panier et continuer" — fidèle à la règle métier et au comportement du mockup Stitch lui-même.
- **Code démo 2FA/OTP** : 6 chiffres partout (`123456`), y compris sur l'écran de réinitialisation de mot de passe où le mockup montrait 4 chiffres — corrigé car le vrai backend Django envoie des codes à 6 chiffres (confirmé via un e-mail réel capturé dans MailHog par l'utilisateur).
- **Icône de l'app** : croix pharmacie blanche sur fond vert `#006A35`, générée via `flutter_launcher_icons` (config dans `pubspec.yaml`, sources dans `assets/icon/`).
- **Mode démo** : bandeau jaune `DemoBanner` piloté par `AppConfig.demoMode` (`lib/src/core/app_config.dart`). Disparaît automatiquement quand on passera `--dart-define=DEMO_MODE=false` lors du branchement de la vraie API — rien à retoucher manuellement dans les écrans.
- **Cohérence des données de démo entre écrans** : quand un mockup Stitch contient des articles/prix différents d'un écran à l'autre (ex. panier vs checkout vs paiement dans l'export d'origine), on privilégie la cohérence interne de l'app plutôt que de copier des données mockup incohérentes. Le panier de démo (Doliprane 1000mg + Biseptine Spray, Pharmacie Akanda) est la source de vérité ; Checkout et Paiement recalculent et transmettent les vrais montants (sous-total, livraison, réduction assurance) via les constructeurs des écrans plutôt que des valeurs codées en dur séparément.
- **Simulation de paiement (écran 13)** : issue aléatoire succès/échec (~70/30), fidèle au comportement du prototype Stitch lui-même (qui simule volontairement les deux états). Pas de vraie passerelle de paiement branchée.
- **Liens légaux** : "conditions générales de vente/d'utilisation" et "confidentialité" sont cliquables partout où le mockup les mentionne (Panier, Inscription) et renvoient vers `TermsScreen`/`PrivacyPolicyScreen` (contenu réel du site web, écrans déjà construits dans le lot Authentification) plutôt que des placeholders.
- **Timeline de suivi réutilisée** : `_TimelineStep`/`_StepState`/`_TimelineTile` (`detail_screens.dart`) sont partagés entre l'écran 16 (Détail commande) et l'écran 17 (Suivi de livraison) plutôt que dupliqués.
- **Carte réelle (écran 17, Suivi de livraison)** : branchée depuis le 4 septembre 2026 sur `order.delivery.courierLatitude`/`courierLongitude` (`GET /mobile/patient/orders/<id>/`, même pattern `GoogleMap`/`liteModeEnabled` que l'écran 9) — un vrai marker s'affiche sur la position du livreur si elle est fraîche (< 5 min côté backend), sinon fond illustratif dégradé conservé avec un message honnête. Voir `branchement_patient.md`, session du 4 septembre 2026, pour le détail et la vérification S8.
- **SDK Google Maps (écran 9, Détail pharmacie)** : intégré le 23 août 2026 (`google_maps_flutter`, clé API dans `android/local.properties` → `mapsApiKey`, gitignored, injectée via `manifestPlaceholders` dans `android/app/build.gradle.kts`). Le petit aperçu de carte affiche un vrai marker sur les coordonnées réelles de la pharmacie (`latitude`/`longitude`, exposées par l'API depuis le même jour) en mode statique (`liteModeEnabled`, pas de gestes — évite les conflits avec le scroll de l'écran). Le bouton "Navigation" ouvre désormais une vraie app de navigation externe (lien `google.com/maps/dir`) au lieu du message "indisponible en démonstration". Repli honnête conservé si la pharmacie n'a pas de coordonnées en base (fond illustratif inchangé).
- **Code de remise livraison (écran 17)** : jamais affiché en clair, conformément à la spec — seule la mention "Code de remise envoyé par SMS (canal sécurisé)" apparaît une fois le colis récupéré par le livreur.
- **Cohérence des totaux financiers (écran 18)** : les totaux du bandeau (dépenses/remboursements) sont recalculés dynamiquement depuis la liste de transactions affichée plutôt que copiés du mockup, qui était lui-même incohérent (45 200 FCFA de total affiché alors que les transactions "payé" visibles ne totalisaient que 23 600 FCFA).
- **Commandes/paiements/livraison — données de démo liées par référence** : `_orderDetails` (détail commande), `_deliveryTrackingDefault` (livraison) et la liste `OrdersScreen` partagent les mêmes références `GP-260x-xxxx` et montants pour rester cohérents d'un écran à l'autre ; `_financialTransactions` (écran 18) est un historique séparé et volontairement plus large (inclut des transactions échouées/remboursées hors de la liste des 4 commandes de démo).
- **Assurance (écran 19)** : une seule affiliation active à la fois (« Ajouter une autre assurance » indisponible en démonstration, pas de vrai multi-assureur) ; taux de couverture et dérogations par catégorie affichés à titre informatif uniquement, avec mention explicite qu'aucun droit n'est vérifié auprès de l'assureur.
- **Notifications (écran 20) et tickets (écran 21) réutilisent les références de commandes déjà connues** (`GP-2607-4190`, `GP-2606-3980`, etc.) pour que les liens croisés (notification → suivi de livraison, ticket → détail commande) restent cohérents.
- **Tickets ↔ Conversation (écrans 21-22)** : chaque ticket de démo (`TK-45920`, `TK-45812`) a sa propre conversation cohérente avec son sujet, au lieu d'une seule conversation générique copiée du mockup. Créer un ticket ouvre directement sa conversation. Envoyer un message sur un ticket résolu le rouvre réellement (pas de fausse réponse auto-générée).
- **Champ de saisie dans un conteneur personnalisé** : quand un `TextField` est placé dans un `Container` avec sa propre bordure/radius (ex. barre de saisie du chat), il faut explicitement mettre `enabledBorder`/`focusedBorder`/`errorBorder`/`disabledBorder` à `InputBorder.none` en plus de `border` — sinon le thème global (`inputDecorationTheme` dans `theme.dart`) dessine sa propre bordure par-dessus et donne un effet de double cadre. Rencontré sur l'écran 22, penser à ce piège pour tout futur champ dans un conteneur custom.
- **Sécurité (écran 24)** : réutilise l'identité déjà établie du profil (« Grâce Nziengui », Libreville) plutôt que le nom du mockup. La 2FA n'a et n'aura jamais d'interrupteur de désactivation (règle métier explicite). `SimpleFeatureScreen`, le placeholder générique utilisé pour les écrans non construits, a été supprimé une fois tous les écrans remplacés par de vraies implémentations.
- **`TextField(enabled: false)` avec un `suffixIcon` cliquable — piège** : Flutter enveloppe un champ désactivé dans un `IgnorePointer` qui couvre tout le champ, y compris ses `prefixIcon`/`suffixIcon` — un bouton dans le `suffixIcon` d'un champ "lecture seule" est donc visible mais totalement inerte. Rencontré sur le champ e-mail de `ProfileEditScreen` (bouton "Modifier" invisible/inerte). Pour un champ "lecture seule + action", ne pas utiliser `TextField(enabled: false)` : reproduire le style d'input avec un `Container` (bordure `outlineVariant`, radius 14px) contenant directement le texte et le bouton, hors de tout `TextField`.
- **`AlertDialog` avec un champ de saisie — piège** : sans `scrollable: true`, le contenu ne se réduit pas à l'ouverture du clavier et peut déborder (`RenderFlex overflowed`). Rencontré sur la boîte de confirmation de désactivation de compte (`SecurityScreen`, débordement de 97px). Mettre `scrollable: true` sur tout `AlertDialog` dont le contenu inclut un `TextField`.
- **Cartes avec badge de statut + texte de longueur variable** : ne jamais mettre deux blocs de texte de longueur imprévisible (ex. nom de pharmacie et libellé de statut) sur la même `Row` sans que l'un des deux soit dans un `Expanded`/contraint — un badge avec un libellé long (ex. "REMBOURSEMENT EN COURS") pousse et tronque l'autre texte. Rencontré sur `_TransactionCard` (Paiements et remboursements) une fois branché sur de vraies données. Solution retenue dans ce projet : chaque ligne de la carte ne porte qu'un seul bloc de texte variable (le badge de statut est en pleine largeur sur sa propre ligne, jamais à côté du nom de pharmacie ou du montant).
- **`core/` (services bas niveau) ne doit jamais importer un écran** : `push_notification_service.dart` (core/) a besoin de naviguer vers un écran au tap d'une notification push, mais ne doit pas importer `detail_screens.dart` (créerait une dépendance `core/` → écrans, à l'inverse de toutes les autres briques de `core/`). Résolu via un callback statique `PushNotificationService.onNotificationTap`, réglé depuis `main.dart` (qui, lui, peut importer les écrans) plutôt que depuis `core/`.
- **Changement d'e-mail (Profil)** : sous-écran dédié `EmailChangeScreen` (mot de passe actuel + nouvel e-mail, puis code à 6 chiffres), sur le modèle de `RegisterVerifyScreen`. Pas d'endpoint de renvoi dédié côté backend : renvoyer = rappeler `POST /mobile/profile/email-change/`, protégé côté app par le même cooldown client fixe de 60s que les autres écrans de vérification (évite le piège du cooldown serveur documenté au module Mot de passe oublié).
- **Désactivation de compte (Sécurité)** : réversible, confirmation par mot de passe, réactivation par simple reconnexion + 2FA (aucun endpoint de réactivation séparé côté backend) — message honnête à ce sujet plutôt qu'un vrai flux de "réactivation".
- **Notifications push FCM** : token envoyé au backend (`POST /mobile/devices/`) après connexion réussie, vérification d'inscription et restauration de session, et à chaque `onTokenRefresh` si déjà connecté ; désenregistré (`POST /mobile/devices/unregister/`) à la déconnexion et à la désactivation de compte. Tap sur une notification navigue vers `OrderDetailScreen`/`ConversationScreen` selon le champ `type` du payload (`order`/`support_ticket`, envoyés par `apps.notifications.push.send_push_to_user` côté Django) ; le type `delivery` n'a volontairement aucune navigation ciblée (pas d'écran patient réellement branché sur un id de livraison, voir suivi de livraison ci-dessus).
- **Géolocalisation patient (`lib/src/core/location_service.dart`)** : jamais de prompt de permission "surprise" sur un écran passif — le détail médicament et le détail pharmacie n'utilisent que `PatientLocationService.cachedPosition` (getter synchrone, ne déclenche rien) ; seule une action explicite ("Proximité" sur Recherche et sur l'écran Pharmacies) appelle `currentPosition()` et déclenche le vrai prompt runtime Android, avec mise en cache mémoire (TTL 5 min) pour éviter de re-prompter à chaque écran. Repli honnête systématique si permission refusée/service coupé : pas de distance affichée, tri par nom, jamais d'exception remontée à l'UI.
- **Écran "Parcourir les pharmacies" (`PharmacyBrowseScreen`, route `/pharmacies`)** : décision de placement actée avec l'utilisateur avant implémentation — pas de nouvel onglet dans le bottom nav (resterait à 5 onglets, fidèle à la spec des 24 écrans), accessible via le bouton "Voir tout" de la section "Pharmacies à proximité" de l'Accueil (qui pointait par erreur vers l'onglet Recherche/médicaments depuis le lot 2, corrigé au passage).
- **Verrouillage biométrique (Touch ID / Face ID, `SecurityScreen`)** : verrou purement local (`local_auth` + `flutter_secure_storage`), aucun changement backend, aucun registre "appareil de confiance" côté serveur (version minimale actée avec l'utilisateur — voir `propositions_backend.md` §6 pour la version "avec backend" non retenue). `MainActivity.kt` doit être `FlutterFragmentActivity` (pas `FlutterActivity`) pour que `local_auth` fonctionne sur Android. Le toggle exige une authentification biométrique de confirmation avant de persister l'activation (pas de simple flip de switch). `SplashScreen` verrouille uniquement au lancement à froid / à la restauration de session — pas de re-verrouillage au retour d'arrière-plan (portée volontairement minimale : protéger l'accès au token déjà stocké, pas un vrai second facteur applicatif). Repli honnête si le capteur devient indisponible entre-temps (empreintes effacées, etc.) : accès direct plutôt que blocage.

## Tester sur le Samsung Galaxy S8 (ADB)
flutter devices
flutter run -d 988d55344b31384730

```powershell
adb devices                                    # vérifier que le S8 est détecté
cd C:\Users\24174\StudioProjects\gabpharma_patient
flutter build apk --debug
adb -s <device-id> install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s <device-id> shell am force-stop ga.gabpharma.gabpharma_patient
adb -s <device-id> shell am start -n ga.gabpharma.gabpharma_patient/.MainActivity
```

Ou plus simple pour itérer avec hot reload :
```powershell
flutter run -d <device-id>
```

`<device-id>` vu en session : `988d55344b31384730` (peut changer si rebranché sur un autre port USB — relancer `adb devices` pour confirmer).

## Prochaine étape

**Les 24 écrans cibles de la spec sont terminés et validés (Lots 1 à 4 complets).** Deux sujets restent ouverts :

1. **Écrans 25/26 (Mes vaccins, Certificat numérique)** : hors spec originale des 24 écrans — demander à l'utilisateur s'il faut les implémenter ou les laisser de côté.
2. **Connexion à l'API mobile réelle** (Django) : en cours depuis le 13 août 2026, suivie module par module dans `branchement_patient.md`. **Les 15 modules du fichier de suivi sont désormais tous branchés et vérifiés**, y compris les notifications push FCM (token envoyé au backend après connexion/inscription/restauration de session, désenregistré à la déconnexion, tap sur une notification testé de bout en bout le 24 août 2026 — voir `branchement_patient.md` point 15). Le refresh JWT (token d'accès 20 min) et le renvoi de code générique (inscription/mot de passe oublié) sont également résolus depuis le 23 août 2026 — voir `branchement_patient.md` points 1 et 13-14 pour l'historique. **Les trois items "lourds" de `propositions_backend.md` sont désormais branchés et vérifiés** (géolocalisation patient réelle, écran "Parcourir les pharmacies", biométrie locale Touch ID/Face ID — voir `branchement_patient.md`, section "Session du 25 août 2026", pour le détail). **Reste ouvert** : la suppression/anonymisation définitive de compte (bloquée sur une décision produit/légale de rétention des données, pas technique — la désactivation réversible, elle, est branchée et vérifiée) et les écrans 25/26 ci-dessus.

### Repères pratiques pour reprendre une session de branchement

- Backend local : `cd "C:\Users\24174\Documents\projets\django projects\gabpharma"`, `python manage.py runserver 8004` (venv `C:\Users\24174\Envs\DSI\Scripts\python.exe`).
- MailHog (OTP e-mail) : vérifier s'il tourne déjà nativement (`MailHog_windows_386.exe`, ports 1025/8025) avant de relancer quoi que ce soit — inutile de passer par `docker compose up` si c'est déjà le cas.
- S8 physique : `adb reverse tcp:8004 tcp:8004` à refaire à chaque reconnexion USB (le tunnel ne survit pas à une déconnexion), puis build avec `--dart-define=API_BASE_URL=http://127.0.0.1:8004/api/v1/ --dart-define=DEMO_MODE=false`. **Observé le 25 août 2026** : le tunnel peut aussi se couper sur un simple cycle verrouillage/déverrouillage de l'écran (pas seulement une déconnexion USB franche) — si l'app affiche "Impossible de joindre l'API" après avoir testé un flux qui verrouille l'écran (ex. biométrie), vérifier `adb reverse --list` avant de chercher plus loin.
- Compte de démo pratique (mêmes identifiants que ceux pré-remplis par défaut sur l'écran de connexion, donc zéro saisie manuelle nécessaire) : `patient.demo@gmail.com` / `Demo1987.`, créé via `manage.py shell` le 13 août. **Mot de passe changé le 23 août 2026** lors du test réel du changement de mot de passe (module Profil) — `demonstration` ne fonctionne plus. **E-mail changé le 24 août 2026** lors du test réel du changement d'e-mail (`patient.demo@gabpharma.ga` → `patient.demo@gmail.com`) — le pré-remplissage de l'écran de connexion (`auth_screens.dart`) a été mis à jour les deux fois en conséquence.
- Le code OTP par e-mail expire en 5 minutes — préférer que l'utilisateur tape lui-même « Se connecter »/« Vérifier » sur le téléphone plutôt que de le simuler via ADB (source de lenteurs et d'échecs répétés en session, voir historique de conversation du 13-17 août).
