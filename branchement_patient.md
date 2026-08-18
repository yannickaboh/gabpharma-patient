# Gab'Pharma Patient — suivi du branchement API réelle

**Créé le :** 13 août 2026
**But :** suivre, module par module, le passage du mode démonstration (données locales statiques) au vrai backend Django (`/api/v1/...`). Cocher au fur et à mesure, ne pas re-décider l'ordre sans raison — voir note en bas si l'ordre doit changer.

## Déjà branché et vérifié (13 août 2026, sur S8 physique + backend local `:8004`)

- [x] Connexion (`POST /mobile/auth/login/`)
- [x] Vérification 2FA (`POST /mobile/auth/verify-2fa/`)
- [x] Restauration de session (`GET /mobile/auth/me/`) — testé en relançant l'app après connexion, session persistée via `flutter_secure_storage`
- [ ] Renvoi du code 2FA (`POST /mobile/auth/resend-2fa/`) — câblé dans le code (`AuthSession.resendTwoFactor`) mais jamais testé sur device

**Bug corrigé au passage** : `api_client.dart` ne fixait jamais `Content-Length`, donc `dart:io` basculait en `Transfer-Encoding: chunked` — incompatible avec le serveur de dev Django (`manage.py runserver`, wsgiref), qui rejetait toute requête POST/PUT réelle (`Bad request syntax`). Fix commité (`99bcf34`) : encoder le corps en bytes UTF-8 et fixer `contentLength` explicitement avant `request.add(...)`.

**Gap connu, non corrigé** : le token d'accès JWT expire au bout de 20 min (`SIMPLE_JWT.ACCESS_TOKEN_LIFETIME`) et **aucun endpoint `/mobile/auth/refresh/` n'existe côté Django** pour le rafraîchir (vérifié le 18 août 2026, `grep` vide dans `apps/api/urls.py`). Décision utilisateur : ne pas construire le refresh token pour l'instant. **Fix appliqué côté app le 18 août 2026** pour limiter les dégâts : tout 401 sur une requête authentifiée (hors `/me/` pendant `restoreSession()`, déjà géré) déclenche désormais une déconnexion propre + retour au login (`ApiClient.onUnauthorized`, `AuthSession._handleUnauthorized`, `AppConfig.navigatorKey`) plutôt que d'afficher un écran d'erreur mort qui ne se résoudra jamais. Le vrai refresh token reste à faire un jour, côté backend d'abord.

## Ordre convenu pour la suite

1. [x] **Accueil** — `GET /mobile/patient/summary/` (profil, panier, commande active, commandes récentes, notifications, favoris, offres). Vérifié sur S8 le 17 août 2026 : prénom réel, badge panier masqué si vide, bannière "commande en cours" masquée si aucune commande active (pas de fausse donnée), pharmacies/produits/catégories dérivés de `featured_stocks` (dédupliqués), statut pharmacie réel (Ouvert 24h/24 / Ouvert / Fermé selon `is_24_7`/`is_on_duty`). Bug corrigé au passage : overflow de 49px sur les cartes produits (`GridView childAspectRatio` 0.72 trop serré → 0.58). Bouton "Ajouter" (home) et détail médicament/pharmacie restent sur les données démo — hors scope de ce module (voir étapes 2-3).
2. [x] **Recherche + catalogue** — `GET /mobile/patient/catalog/categories/`, `GET /mobile/patient/zones/`, `GET /mobile/patient/catalog/` (recherche texte avec debounce 400ms, filtre zone, filtre catégorie via bottom sheet, pagination "Charger plus"). Vérifié sur S8 le 18 août 2026 : zones réelles (Libreville/Owendo/Akanda/Bikélé), résultats réels avec comptage exact, recherche texte fonctionnelle server-side, combinaison recherche+zone testée. Filtre "Forme" reste honnêtement indisponible (l'API ne le supporte pas). Boutons "Ajouter"/"Alerte" et détail médicament restent sur données démo — hors scope (voir étapes 3 et 5).
3. [x] **Détail médicament / pharmacie** — `GET /mobile/patient/catalog/stocks/<id>/`, `GET /mobile/patient/pharmacies/<id>/`, `GET /mobile/patient/pharmacies/<id>/catalog/`. Vérifié sur S8 le 18 août 2026. Détail médicament : id du stock transmis via `Navigator` depuis Accueil/Recherche/détail pharmacie (`ModalRoute.settings.arguments`), "Pharmacies Disponibles" reconstitué en interrogeant `/catalog/?q=<nom du médicament>` (pas d'endpoint dédié "médicament tous pharmacies", approximation assumée et honnête). Détail pharmacie : champs vides (adresse/téléphone/horaires/services) affichés avec un texte honnête plutôt qu'une valeur inventée — confirmé avec la Pharmacie du Centre qui a tous ces champs vides en démo. Distance factice ("850m", "1.2 km") supprimée partout (pas de géolocalisation). Panier/Favoris toujours honnêtement "pas encore connecté" — hors scope (étapes 4-5).
4. [ ] **Favoris** — `GET/POST /mobile/patient/favorites/`, `DELETE /mobile/patient/favorites/<id>/`
5. [ ] **Panier** — `GET /mobile/patient/cart/`, `POST/PATCH/DELETE /mobile/patient/cart/items/...`, `POST /mobile/patient/cart/clear/`
6. [ ] **Checkout** — `GET /mobile/patient/zones/`, `GET /mobile/patient/payment-methods/`, `POST /mobile/patient/checkout/`
7. [ ] **Paiement simulé** — `POST /mobile/patient/payments/<reference>/simulate/resolve/`
8. [ ] **Commandes** — `GET /mobile/patient/orders/`, `GET /mobile/patient/orders/<id>/`, `POST .../cancel/`, `.../accept-changes/`, `.../reject-changes/`, `.../retry-payment/`
9. [ ] **Assurance** — `GET /mobile/patient/insurance/insurers/`, `GET/POST/PATCH/DELETE /mobile/patient/insurance/affiliation/`
10. [ ] **Notifications** — `GET /mobile/notifications/`
11. [ ] **Support** — `GET /mobile/support/categories/`, `GET/POST /mobile/support/tickets/`, `GET /mobile/support/tickets/<id>/`, `POST .../reply/`
12. [ ] **Profil** — `GET/PATCH /mobile/profile/`, `POST /mobile/profile/password/`
13. [ ] **Inscription** — `POST /mobile/auth/register/`, `POST /mobile/auth/register/verify/` (actuellement `RegisterScreen._submit` simule juste un délai, aucun appel réel)
14. [ ] **Mot de passe oublié** — `POST /mobile/auth/password-reset/`, `/verify/`, `/confirm/` (actuellement `PasswordResetScreen` entièrement simulé, OTP démo codé en dur)
15. [ ] **Notifications push (token FCM)** — bloqué : `push_notification_service.dart` récupère déjà un token FCM localement (`// TODO` explicite dans le code), mais **aucun endpoint backend n'existe encore** pour l'enregistrer. Nécessite un développement côté Django d'abord.

## Méthode de vérification pour chaque module

1. Brancher le code Flutter sur l'endpoint réel (remplacer les données locales par un appel `ApiClient`).
2. Rebuild l'APK debug : `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8004/api/v1/ --dart-define=DEMO_MODE=false`
3. `adb reverse tcp:8004 tcp:8004` (le tunnel ne survit pas à une reconnexion USB — à refaire si le S8 se déconnecte)
4. Installer et tester sur le S8 physique.
5. Vérifier le log du serveur Django (pas juste que l'écran s'affiche) pour confirmer un `200` et pas une erreur silencieuse côté client.
6. Cocher la case ci-dessus une fois vérifié.

## Livreur (hors scope de ce fichier)

Aucun branchement commencé côté Livreur — voir `gabpharma_livreur/CLAUDE.md`. Le backend est déjà prêt côté Livreur aussi (`/mobile/courier/summary/`, `/availability/`, `/deliveries/...`, `/ledger/`) mais rien n'est câblé côté Flutter. À traiter séparément une fois ce fichier soldé, ou en parallèle si décidé plus tard.
