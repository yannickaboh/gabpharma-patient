# Gab'Pharma Patient — propositions d'évolutions backend (Django)

**Créé le :** 23 août 2026
**But :** lister, endpoint par endpoint, ce qu'il manque côté API Django (`C:\Users\24174\Documents\projets\django projects\gabpharma`) pour que l'app mobile Patient soit complète, stable et pleinement fonctionnelle — au-delà du simple branchement des 24 écrans déjà réalisé (voir `branchement_patient.md`). Chaque point a été vérifié en lisant le code backend réel (modèles, vues, `urls.py`), pas deviné depuis l'app : quand un champ ou une donnée existe déjà en base mais n'est simplement pas exposée à l'API mobile, c'est précisé, car le coût de correction est très différent d'une fonctionnalité à construire de zéro.

## Comment lire ce document

Chaque section indique :
- **État actuel** — ce qui existe déjà côté backend (modèle, champ, endpoint), avec fichier/ligne de référence.
- **Manque** — ce qui empêche l'app mobile de faire le travail correctement aujourd'hui.
- **Proposition** — le contrat d'API concret à ajouter ou corriger.
- **Effort estimé** — repère grossier (🟢 rapide, 🟡 moyen, 🔴 conséquent) pour aider à prioriser.

---

## 1. Gains rapides (à faible effort, fort impact)

### 1.1 🟢 Rafraîchissement du token JWT (gap déjà connu, le plus urgent)

**État actuel :** `SIMPLE_JWT` (`gabpharma/settings.py:177`) génère déjà un `refresh` token à chaque connexion/2FA/inscription (14 jours de validité, `ROTATE_REFRESH_TOKENS=True`). L'app le stocke même déjà dans `flutter_secure_storage` — il ne sert simplement à rien aujourd'hui.
**Manque :** aucune route `mobile/auth/refresh/` dans `apps/api/urls.py`. Résultat concret et déjà vécu en session de test : le token d'accès expire toutes les 20 minutes et l'utilisateur est reconnecté au login, alors qu'un refresh token valide 14 jours dort dans son téléphone.
**Proposition :** exposer le `TokenRefreshView` déjà fourni par `djangorestframework-simplejwt` :
```python
path("mobile/auth/refresh/", TokenRefreshView.as_view(), name="mobile_auth_refresh"),
```
Éventuellement l'envelopper pour revérifier `role`/`status` comme le fait `MobileMeView`, au cas où un compte serait suspendu entre-temps. Côté app, il suffira d'intercepter les 401 pour tenter un refresh silencieux avant de déconnecter (actuellement `ApiClient.onUnauthorized` déconnecte directement).
**Effort estimé :** quelques lignes, la brique existe déjà dans la dépendance installée.

### 1.2 🟢 Renvoi de code cassé pour l'inscription et le mot de passe oublié

**État actuel :** `MobileResend2FAView` (`apps/api/mobile_auth.py:240`) filtre explicitement `purpose=OneTimeCode.Purpose.LOGIN_2FA`. Or `/register/` et `/password-reset/` émettent des codes avec `purpose=REGISTRATION` et `purpose=PASSWORD_RESET` respectivement, tout en annonçant `"can_resend": true` dans leur réponse.
**Manque :** un renvoi générique qui fonctionne quel que soit le `purpose` du challenge.
**Proposition :** généraliser `MobileResend2FAView` (ou créer un endpoint `mobile/auth/resend-code/` commun) pour accepter n'importe quel `purpose` associé à un `challenge_id` valide, plutôt que de coder `LOGIN_2FA` en dur. Attention à conserver le comportement anti-énumération de `/password-reset/` (ne jamais confirmer si le compte existe).
**Effort estimé :** modification d'une condition + tests de non-régression sur le login existant.
**Contournement actuel côté app :** documenté dans `branchement_patient.md` (points 13 et 14) — pas de renvoi du tout pour l'inscription, renvoi en re-appelant `/password-reset/` (avec un compte à rebours client de 60s) pour le mot de passe oublié.

### 1.3 🟢 Numéro de téléphone de la pharmacie absent des commandes

**État actuel :** `_pharmacy_detail_payload` (`apps/api/mobile_patient.py:231`) expose déjà `phone`. Mais `_pharmacy_payload` (ligne 201), la version courte utilisée dans le panier, le stock et **les commandes** (`_order_payload`, ligne 400), ne renvoie pas `phone`.
**Manque :** c'est pour ça que le bouton "Appeler la pharmacie" a dû être retiré de l'écran Détail commande (module 8 de `branchement_patient.md`) alors que la donnée existe en base et est même déjà retournée pour l'appel du livreur (`courier_phone` existe sur la livraison, ligne 378).
**Proposition :** ajouter `"phone": pharmacy.phone` à `_pharmacy_payload`. Aucune migration nécessaire, c'est un champ déjà en base (`apps/pharmacies/models.py:32`).
**Effort estimé :** une ligne.

### 1.4 🟢 Filtre "Forme" absent de la recherche alors que la donnée existe

**État actuel :** `Medication.form` (`apps/catalog/models.py:38`) avec un `Form.choices` complet existe déjà en base (comprimé, sirop, injectable, etc.). `MobilePatientCatalogView` (`apps/api/mobile_patient.py:536`) ne filtre que sur `q`, `category` et `zone`.
**Manque :** pas de paramètre `form` sur `GET /mobile/patient/catalog/`, ni d'endpoint pour lister les formes disponibles (sur le modèle de `GET /mobile/patient/catalog/categories/`).
**Proposition :**
- `GET /mobile/patient/catalog/forms/` → liste des `Medication.Form.choices`.
- `GET /mobile/patient/catalog/?form=<code>` → filtre `stocks.filter(medication__form=form)`.
**Effort estimé :** calqué exactement sur le filtre `category` déjà existant.

---

## 2. Paiements et remboursements (écran "Paiements et remboursements" du Profil)

**État actuel :** l'écran existe déjà côté app (`PaymentsHistoryScreen`, accessible depuis le Profil) mais **n'a jamais été dans la liste de branchement** (`branchement_patient.md` ne le mentionne à aucun des 15 points) — il tourne encore sur des données de démo locales (`_financialTransactions`). Côté backend, `PaymentTransaction` (`apps/payments/models.py:26`) existe déjà avec `reference`, `provider`, `status` (pending/succeeded/failed), `created_at`, `resolved_at`, lié à `Order`. `Order.PaymentStatus` (`apps/orders/models.py:94`) va plus loin et connaît déjà `refund_pending`, `partially_refunded`, `refunded`.
**Manque :** aucun endpoint qui liste, pour le patient connecté, son historique de transactions/remboursements toutes commandes confondues. Aujourd'hui l'app ne peut reconstituer cet historique qu'en rappelant `GET /mobile/patient/orders/` commande par commande, ce qui est indirect et ne couvrira jamais un remboursement (aucun modèle de remboursement dédié n'existe, seuls les statuts `Order.payment_status` en portent la trace).
**Proposition :**
- `GET /mobile/patient/payments/` → historique paginé des `PaymentTransaction` du patient (jointure via `order.patient`), avec la commande liée en résumé (référence, pharmacie, montant), le statut, le moyen de paiement, les dates.
- Si un vrai flux de remboursement doit exister (pas seulement un statut affiché), il faudra un modèle `Refund` (montant, motif, date de traitement, transaction d'origine) — actuellement rien ne modélise *comment* un remboursement est déclenché ou exécuté, seul le statut final est stocké sur la commande.
**Effort estimé :** 🟡 endpoint de liste seul (statuts déjà là) ; 🔴 si un vrai flux de remboursement (déclenchement, traçabilité, back-office) doit être construit derrière.

---

## 3. Catalogue des pharmacies (recherche, filtres, fiche détail, appel)

**État actuel :** l'app ne peut découvrir une pharmacie qu'indirectement — via un médicament (`/catalog/`) ou une commande passée. Il n'existe **aucun endpoint `GET /mobile/patient/pharmacies/`** pour parcourir/rechercher les pharmacies elles-mêmes (par nom, zone, service, garde). `_pharmacy_detail_payload` (`apps/api/mobile_patient.py:231`) est déjà riche : `address`, `phone`, `is_on_duty`, `is_24_7`, `is_open_now`, `services`, `weekly_hours`, `accepted_plan_ids`, `photos` — la fiche détail n'a donc presque rien à ajouter niveau backend, seulement à être listable.
**Manque :**
1. Un endpoint de liste/recherche de pharmacies (indépendant d'un médicament précis).
2. Le tri/filtre par proximité (voir section 4, géolocalisation).
3. Un filtre "pharmacie de garde maintenant" (`is_on_duty`/`is_24_7` existent déjà comme champs, juste pas exposés comme filtre de liste).

**Proposition :**
```
GET /mobile/patient/pharmacies/?q=<nom>&zone=<code>&on_duty=true&lat=<f>&lng=<f>
```
Renvoie une liste paginée de `_pharmacy_detail_payload` (ou une version allégée pour la liste + détail complet au clic), triée par distance si `lat`/`lng` fournis, sinon par nom. Réutilise entièrement les champs et modèles déjà en place.
**Effort estimé :** 🟡 — assemblage de briques existantes (`Pharmacy`, `_pharmacy_detail_payload`, pagination déjà utilisée ailleurs), pas de nouveau modèle.

**Remarque distincte, ce n'est pas un gap backend :** `branchement_patient.md` (module 3) note que certains champs (adresse, téléphone, horaires) apparaissent vides sur la Pharmacie du Centre en démo. Ce n'est **pas** un champ manquant côté code — `phone`/`address`/`weekly_hours` existent et sont bien retournés par l'API — c'est un trou de **données de test** à combler en base (`manage.py shell` ou back-office), pas un développement.

---

## 4. Géolocalisation

**État actuel :** `Pharmacy.latitude` / `Pharmacy.longitude` existent déjà en base (`apps/pharmacies/models.py:38-39`, `DecimalField` nullable) mais ne sont **jamais retournés** par l'API mobile (absents de `_pharmacy_payload` et `_pharmacy_detail_payload`). Aucun endpoint n'accepte de position patient en paramètre. Côté livraison, `Delivery` (`apps/deliveries/models.py`) n'a **aucun champ de position courante du livreur** — la carte de suivi (écran 17) n'a donc pas qu'un problème de SDK cartographique côté app (déjà noté dans `CLAUDE.md` comme décision différée), il n'y a pas non plus de donnée de position en temps réel à afficher côté serveur.
**Manque :**
1. Exposer `latitude`/`longitude` dans les payloads pharmacie.
2. Accepter la position du patient (`lat`/`lng`) sur `/catalog/` et le futur `/pharmacies/` pour trier par distance et afficher une distance lisible ("850 m", "1,2 km") — actuellement supprimé de l'app car factice, mais légitimement utile si réel.
3. Un mécanisme de position du livreur en temps réel pour le suivi de livraison (ping périodique du côté app Livreur + endpoint de lecture côté Patient), sujet nettement plus gros que les deux premiers points.
**Proposition :**
- Étape 1 (🟢) : ajouter `latitude`/`longitude` aux payloads pharmacie existants.
- Étape 2 (🟡) : accepter `lat`/`lng` en query params sur `/catalog/` et `/pharmacies/`, calculer la distance (formule de Haversine, pas besoin de PostGIS pour un premier jet) et trier/annoter les résultats.
- Étape 3 (🔴, à ne faire que si le suivi temps réel est une vraie priorité produit) : nouveau modèle `DeliveryPosition` (livraison, lat, lng, horodatage) alimenté par l'app Livreur, exposé en lecture au Patient via l'endpoint de suivi existant ou un polling/WebSocket dédié.
**Effort estimé :** voir étapes ci-dessus — ne pas tout livrer d'un bloc, l'étape 1+2 apporte déjà l'essentiel (tri par proximité, distance affichée) sans le chantier temps réel.

---

## 5. Suppression / désactivation de compte

**État actuel :** `User.Status` (`apps/accounts/models.py:50`) ne connaît que `pending`, `active`, `suspended`, `rejected`. Aucun statut de type "désactivé par le patient lui-même" ni de suppression, et aucune route dans `apps/api/urls.py` ne le permet. Seul un administrateur peut aujourd'hui changer un statut (back-office).
**Manque :** un moyen pour le patient de désactiver ou supprimer son propre compte depuis l'app. **Ce n'est pas qu'un confort** : Apple (App Store Review Guideline 5.1.1(v)) et Google Play exigent qu'une app permettant la création de compte offre un moyen de le supprimer *depuis l'app elle-même* — un gap bloquant pour une publication en store, pas juste une fonctionnalité "nice to have".
**Proposition :**
- `POST /mobile/profile/deactivate/` — désactivation réversible (statut dédié, ex. `User.Status.DEACTIVATED`), invalide les sessions/tokens (réutiliser `invalidate_user_sessions`, déjà utilisé par le changement de mot de passe), permet un retour en arrière par simple reconnexion + réactivation.
- `POST /mobile/profile/delete/` — suppression définitive : au vu des contraintes probables (`PROTECT` sur les FK de commandes/paiements pour l'intégrité comptable), prévoir une **anonymisation** (email/téléphone/nom remplacés par des valeurs génériques, `is_active=False`) plutôt qu'un `DELETE` SQL réel qui casserait l'historique des commandes déjà passées. Envoyer un e-mail de confirmation avant exécution (code de sécurité, même mécanisme que `OneTimeCode` déjà en place) pour éviter une suppression accidentelle ou malveillante (téléphone volé, session ouverte).
**Effort estimé :** 🟡 pour la désactivation réversible ; 🟡-🔴 pour la suppression/anonymisation selon les contraintes FK réelles à auditer (commandes, paiements, tickets support, favoris, avis).

---

## 6. Biométrie (Face ID / Touch ID)

**État actuel :** aucune notion de biométrie ou de "device de confiance" côté backend — l'authentification actuelle est uniquement email/téléphone + mot de passe + 2FA email/TOTP.
**Ce point est majoritairement côté app**, pas côté backend : le déverrouillage biométrique le plus courant (et le plus simple à livrer) consiste à protéger localement l'accès à un token déjà stocké (`flutter_secure_storage` + plugin `local_auth`) — Face ID/Touch ID ne fait alors que déverrouiller ce qui est déjà sur l'appareil, sans toucher à l'API.
**Ce qui nécessiterait vraiment du backend**, si on veut un vrai second facteur biométrique lié au compte (et pas juste un cadenas local) :
- Un registre "appareils de confiance" par utilisateur (nom d'appareil, identifiant, date d'enregistrement, dernière utilisation) — objet qui **peut être mutualisé avec le registre de devices FCM de la section 7**, un seul modèle `Device` peut porter les deux besoins (push token + statut de confiance biométrique).
- Un endpoint pour enregistrer/révoquer un appareil comme "de confiance" après une authentification complète (mot de passe + 2FA), après quoi les connexions biométriques suivantes depuis cet appareil sautent l'étape 2FA email.
**Proposition minimale (🟢, sans backend) :** verrou biométrique local pur, aucune modification API — recommandé pour une première version.
**Proposition avancée (🟡-🔴, avec backend) :** modèle `Device` (voir section 7) + endpoint `POST /mobile/auth/trust-device/` après une connexion 2FA réussie, puis un flag `device_id` optionnel sur `/mobile/auth/login/` qui, si l'appareil est déjà de confiance, saute l'émission d'un challenge 2FA.

---

## 7. Notifications push FCM — registre d'appareils

**État actuel :** confirmé absent de bout en bout — aucun modèle de device/token dans tout le projet Django (vérifié par recherche sur `fcm`, `firebase`, `push_token`, `player_id`, `registration_id` dans `apps/`). Côté app, `push_notification_service.dart` récupère déjà un token FCM localement (commentaire `// TODO` explicite dans le code) mais n'a nulle part où l'envoyer.
**Manque :** tout — modèle, endpoints d'enregistrement, et logique d'envoi serveur → device.
**Proposition :**
- Modèle `Device` :
  ```python
  class Device(models.Model):
      class Platform(models.TextChoices):
          ANDROID = "android", "Android"
          IOS = "ios", "iOS"

      user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="devices")
      platform = models.CharField(max_length=10, choices=Platform.choices)
      push_token = models.CharField(max_length=255, unique=True)  # token FCM ("player id")
      app = models.CharField(max_length=10, choices=(("patient", "Patient"), ("courier", "Livreur")))
      device_label = models.CharField(max_length=120, blank=True)  # ex. "Galaxy S8 de Kylian"
      last_seen_at = models.DateTimeField(auto_now=True)
      created_at = models.DateTimeField(auto_now_add=True)
      is_active = models.BooleanField(default=True)
  ```
  Un même utilisateur peut avoir plusieurs `Device` (téléphone + tablette, réinstallation) — c'est exactement le suivi "un appareil par installation" demandé : chaque ligne = un appareil physique/installation identifiable, avec sa dernière activité, permettant de savoir sur quels appareils un patient est connecté et d'y cibler un envoi.
- Endpoints :
  - `POST /mobile/devices/` (authentifié) → enregistre/rafraîchit le `push_token` de l'appareil courant (upsert par `push_token`, met à jour `user`/`last_seen_at` si le token existe déjà — cas d'un token FCM qui change de compte après déconnexion/reconnexion sur le même appareil).
  - `DELETE /mobile/devices/<id>/` ou `POST /mobile/devices/unregister/` → à appeler à la déconnexion pour ne plus recevoir de push sur cet appareil.
  - `GET /mobile/profile/devices/` → liste des appareils connus du patient (utile pour un futur écran "Appareils connectés" dans Sécurité, et pour la révocation manuelle d'un appareil perdu/volé).
- Envoi : un service serveur (`send_push_to_user(user, title, body, data)`) qui récupère les `Device.objects.filter(user=user, is_active=True)` et appelle l'API Firebase Cloud Messaging (HTTP v1) pour chaque token, désactivant (`is_active=False`) les tokens que FCM signale comme invalides/désinstallés (réponse `UNREGISTERED`) — évite l'accumulation de tokens morts.
- Déclencheurs naturels côté métier, à brancher progressivement : changement de statut de commande (`OrderStatusHistory` existe déjà et alimente déjà `/mobile/notifications/`, réutilisable comme déclencheur), résolution de ticket support, rappel de paiement en attente.
**Effort estimé :** 🔴 — nouveau modèle + intégration FCM (clé de service, gestion des credentials) + endpoints, mais bien délimité et réutilisable aussi pour l'app Livreur (mentionné mais hors périmètre patient) et pour le registre "appareils de confiance" biométrique (section 6).

---

## Récapitulatif par priorité

| # | Sujet | Effort | Bloquant pour... |
|---|-------|--------|-------------------|
| 1.1 | Refresh token JWT | 🟢 | Confort de session (déconnexions toutes les 20 min en test) |
| 1.2 | Renvoi de code (inscription/reset) | 🟢 | Comptes bloqués si code perdu/expiré |
| 1.3 | Téléphone pharmacie sur commande | 🟢 | Bouton "Appeler" du détail commande |
| 1.4 | Filtre "Forme" | 🟢 | Fidélité au mockup Recherche |
| 2 | Historique paiements/remboursements | 🟡/🔴 | Écran déjà construit, toujours en démo |
| 3 | Catalogue des pharmacies | 🟡 | Fonctionnalité absente de la spec initiale mais demandée |
| 4 | Géolocalisation | 🟢→🔴 par étapes | Tri par proximité, distance réelle, suivi livreur temps réel |
| 5 | Suppression/désactivation de compte | 🟡/🔴 | **Conformité stores (Apple/Google), pas juste confort** |
| 6 | Biométrie | 🟢 (sans backend) / 🟡-🔴 (avec) | Peut démarrer sans aucun changement backend |
| 7 | Push FCM + registre d'appareils | 🔴 | Toute notification serveur → app, actuellement impossible |

**Recommandation d'ordre d'attaque :** section 1 en premier (quasi gratuit, résout des irritants déjà rencontrés en test), puis 5 (conformité store, à ne pas découvrir la veille d'une soumission), puis 7 (débloque toute la partie notifications temps réel), 4 et 3 ensemble (géolocalisation + catalogue pharmacies partagent les mêmes champs/modèles), 2 en fonction de la priorité produit réelle du back-office remboursements, 6 en dernier ou en parallèle côté app pur (ne dépend de rien ci-dessus pour sa version minimale).
