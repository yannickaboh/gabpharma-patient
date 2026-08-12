# Besoins API — App Mobile Patient Gab'Pharma

**Date :** 14 juillet 2026
**Auteur :** étude comparative Claude Code, à partir de :
- `C:\Users\24174\Documents\projets\django projects\gabpharma\documentation\api_contrat.md` (contrat API mobile, à jour du 9 juillet 2026) ;
- lecture directe des modèles et vues Django (`apps/accounts`, `apps/catalog`, `apps/orders`, `apps/payments`, `apps/deliveries`, `apps/insurance`, `apps/notifications`, `apps/support`, `apps/pharmacies`, `apps/core`, `apps/api`) ;
- les 24 écrans Flutter déjà construits dans ce dépôt (`lib/src/*.dart`), en mode démonstration statique (voir `CLAUDE.md`).

**Règle de méthode : rien de ce qui existe côté mobile n'est remis en cause.** Ce document part des écrans Flutter tels qu'ils sont et identifie, pour chacun, ce que le backend fournit déjà tel quel, ce qu'il faut ajuster côté payload, et ce qui manque complètement (nouveaux endpoints, nouveaux modèles). Quand un écart de contenu existe entre le mockup Stitch d'origine et l'implémentation Flutter réelle (ex. écran 19 pré-rempli, écran 18 totaux recalculés), c'est **l'implémentation Flutter réelle** qui fait foi ici, pas le mockup.

---

## 1. Synthèse (vue d'ensemble)

| Domaine | État |
|---|---|
| Connexion + 2FA (email et TOTP) | ✅ Prêt, endpoints existants |
| Résumé d'accueil, catalogue, favoris | ✅ Prêt |
| Panier, checkout, commandes, paiement simulé | ✅ Prêt, **mais sans réduction assurance** |
| Livraison (suivi patient) | ⚠️ Partiel — téléphone du livreur et note de confidentialité absents du payload |
| Historique financier (paiements/remboursements) | ⚠️ Pas d'endpoint dédié — à recomposer depuis `orders` + `payment_transactions`, ou nouvel endpoint agrégé |
| Reprise d'un paiement en attente/échoué | ❌ Manquant — aucun endpoint, malgré le flag `actions.can_retry_payment` déjà présent dans la réponse commande |
| Notifications | ⚠️ Flux agrégé seulement — pas de catégorie Sécurité/Offres, pas de lu/non-lu persistant |
| Centre d'aide / tickets / conversation | ✅ Prêt, **mais taxonomie de catégories à réconcilier** |
| Mon assurance (affiliation) | ❌ Manquant côté API mobile — les modèles et la logique métier existent déjà côté web (`apps/insurance`, dashboard patient web) |
| Inscription Patient | ❌ Manquant totalement (aucune trace, ni web ni mobile) |
| Récupération de mot de passe | ❌ Manquant côté mobile — le flux web existe et est réutilisable (services communs) |
| Sécurité et paramètres (mdp, session, prefs notif) | ✅ Changement de mot de passe prêt. Session locale/biométrie/préférences de notification sont purement des états d'appareil, rien à construire côté API sauf si on veut persister les préférences de notification (voir §7) |

---

## 2. Écran par écran

### Lot 1 — Authentification

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 01 Splash / restauration de session | `GET /mobile/auth/me/` (vérifier le token stocké) | ✅ Prêt |
| 02 Connexion | `POST /mobile/auth/login/` | ✅ Prêt |
| 03 Vérification 2FA | `POST /mobile/auth/verify-2fa/`, `POST /mobile/auth/resend-2fa/` | ✅ Prêt |
| 04 Inscription Patient | *aucun endpoint* | ❌ **Manquant** — voir §5.1 |
| 05 Récupération / réinitialisation mot de passe | *aucun endpoint mobile* (le flux web équivalent existe) | ❌ **Manquant côté mobile** — voir §5.2 |

### Lot 2 — Recherche et achat

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 06 Accueil Patient | `GET /mobile/patient/summary/` | ✅ Prêt |
| 07 Recherche et résultats | `GET /mobile/patient/catalog/`, `GET /mobile/patient/catalog/categories/`, `GET /mobile/patient/zones/` | ✅ Prêt. Écart mineur : Flutter ne propose que 3 zones (Libreville/Akanda/Owendo) contre 4 côté backend (+ Bikélé) — à corriger côté Flutter, pas un manque backend |
| 08 Détail médicament | `GET /mobile/patient/catalog/stocks/<id>/` | ✅ Prêt. Écart mineur : le modèle `Medication` n'a pas de champ « conditionnement » (« Boîte de 8 gélules », « Flacon 150ml ») — seul `dosage` existe (« 500 mg ») — voir §6 |
| 09 Détail pharmacie | Pas de endpoint dédié « détail pharmacie » — à construire à partir des données déjà dans `Pharmacy` (zone, adresse, téléphone, `weekly_hours`, `services`, `is_24_7`, `is_on_duty`, `accepted_plans`) | ⚠️ **Manquant** — voir §5.3. Distance (« 1.2 km ») nécessite la géolocalisation, explicitement **hors contrat actuel** — l'écran Flutter l'affiche déjà honnêtement comme non disponible, cohérent |
| 10 Favoris | `GET/POST /mobile/patient/favorites/`, `DELETE /mobile/patient/favorites/<id>/` | ✅ Prêt. Écart mineur : le payload ne renvoie pas si la meilleure offre est en stock faible (`is_low_stock`) — voir §6 |
| 11 Panier | `GET /mobile/patient/cart/`, `POST .../cart/items/`, `PATCH/DELETE .../cart/items/<id>/`, `POST .../cart/clear/` | ✅ Prêt, conflit mono-pharmacie déjà identique au comportement Flutter (`cart_pharmacy_conflict`) |
| 12 Checkout | `POST /mobile/patient/checkout/`, `GET /mobile/patient/payment-methods/` | ✅ Prêt **sauf réduction assurance** (absente du calcul et du payload) — voir §6 |
| 13 Paiement | `POST /mobile/patient/payments/<reference>/simulate/resolve/` | ✅ Prêt, simulation succès/échec correspond au comportement Flutter |
| 14 Confirmation de commande | Réponse de `POST /mobile/patient/checkout/` (order + payment) | ✅ Prêt |

### Lot 3 — Commandes, livraison, finances

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 15 Liste des commandes | `GET /mobile/patient/orders/` | ✅ Prêt. **Mais** les statuts réels (11 valeurs, voir §11) sont bien plus riches que les 4 filtres Flutter actuels (`En attente/En cours/Livré/Annulé`) — remappage nécessaire, voir §11 |
| 16 Détail commande | `GET /mobile/patient/orders/<id>/`, `POST .../cancel/`, `POST .../accept-changes/`, `POST .../reject-changes/` | ✅ Prêt et le comportement Flutter (Accepter/Refuser/Annuler) correspond déjà bien : « Refuser » = annulation, comme `reject-changes` côté Django |
| 17 Suivi de livraison | Pas d'endpoint dédié — dérivé de `order.delivery` dans `GET /mobile/patient/orders/<id>/` | ⚠️ **Partiel** — le payload `delivery` n'expose ni le téléphone du livreur, ni une note d'étape, et il n'existe **aucun modèle de notation/nombre de courses** (« 4.9 • 850+ courses » dans Flutter est une donnée inventée pour la démo) — voir §6 et §9 |
| 18 Paiements et remboursements | Aucun endpoint dédié : à reconstruire depuis `GET /mobile/patient/orders/` (chaque commande porte déjà `payment_status` + `payment_transactions`) | ⚠️ **Manquant en tant que vue agrégée** — voir §5.4 |

### Lot 4 — Assurance, assistance, compte

| Écran | Endpoints nécessaires | État |
|---|---|---|
| 19 Mon assurance | Aucun endpoint mobile — modèles `Insurer`/`Plan`/`PlanCategoryRate`/`Affiliation` déjà utilisés côté web patient (`insurance_affiliation_update`/`_remove`) | ❌ **Manquant côté API mobile** — voir §5.5 |
| 20 Notifications | `GET /mobile/notifications/` | ⚠️ **Partiel** — flux agrégé (commandes uniquement), pas de catégorie Sécurité/Offres, pas de lu/non-lu — voir §7 et §9 |
| 21 Centre d'aide et tickets | `GET /mobile/support/categories/`, `GET/POST /mobile/support/tickets/` | ✅ Prêt, **mais** la taxonomie de catégories Flutter (Médicaments/Livraison/Paiements/Compte) ne correspond pas exactement aux choix backend (`general/account/order/delivery/payment/pharmacy/other`) — voir §11 |
| 22 Conversation Support | `GET /mobile/support/tickets/<id>/`, `POST .../reply/` | ✅ Prêt, les notes internes Staff (`is_internal`) sont déjà filtrées côté serveur — la règle « jamais exposées » est déjà respectée |
| 23 Profil Patient | `GET/PATCH /mobile/profile/` | ✅ Prêt |
| 24 Sécurité et paramètres | `POST /mobile/profile/password/` | ✅ Prêt pour le changement de mot de passe. « Session active » et biométrie sont des états d'appareil local, rien à construire. Préférences de notifications : purement locales pour l'instant côté Flutter (pas persistées) — voir §7 pour une option de persistance future |

---

## 3. Endpoints à créer (contrat proposé)

### 3.1 Inscription Patient (écran 04)

Aucune trace de patient self-service registration nulle part dans le code (ni web, ni API). Les seules créations de compte `role=patient` passent par les commandes de seed de démo ou par le Staff (`MANAGED_ACCOUNT_ROLES` dans `apps/dashboards/views.py`).

**Décision produit à confirmer avant implémentation (voir §9) :** un patient qui s'inscrit doit-il être actif immédiatement après vérification du code (comme suggéré par l'écran Flutter, qui enchaîne directement vers l'app), ou repasser par une validation Staff comme les comptes professionnels (`ProfessionalApplication`) ? **Recommandation : activation immédiate après OTP**, sans étape de validation Staff — un patient n'est pas un partenaire professionnel.

Proposition (dans le style de `mobile_auth.py`) :

```
POST /mobile/auth/register/
```

Body :
```json
{
  "first_name": "Ariane",
  "last_name": "Mba",
  "email": "patient@example.ga",
  "phone": "+241077000001",
  "password": "Tres-Solide!2026",
  "terms_accepted": true
}
```

Règles :
- e-mail et téléphone uniques (comme le modèle `User` l'impose déjà) ;
- validation du mot de passe via les validateurs Django standard (mêmes règles que `ChangePasswordForm`/`ResetPasswordForm`) ;
- `terms_accepted` obligatoire → renseigne `User.terms_accepted_at` ;
- création `User(role=PATIENT, status=PENDING)` ;
- envoi d'un code de vérification (réutilise `issue_code`, nouveau `OneTimeCode.Purpose.REGISTRATION` — voir §8) ;
- pas de token émis à cette étape (même logique que le login).

Réponse : même forme que `POST /mobile/auth/login/` (`detail` + `challenge` + `user`).

```
POST /mobile/auth/register/verify/
```

Body :
```json
{"challenge_id": "uuid", "code": "123456"}
```

Effets : consomme le code, passe `User.status` à `ACTIVE`, émet les tokens JWT (même forme que `verify-2fa`).

### 3.2 Récupération de mot de passe (écran 05)

Le flux web (`forgot_password` / `verify_password_reset` / `reset_password` dans `apps/accounts/views.py`) fait exactement ce que l'écran Flutter attend en 3 étapes, mais il est **basé sur la session Django** (`request.session[...]`), donc inutilisable tel quel par un client mobile stateless. La logique métier sous-jacente (`issue_code`/`verify_code`, purpose `PASSWORD_RESET`) est réutilisable ; il faut seulement une variante API qui fasse transiter l'état via un `challenge_id` signé au lieu de la session, sur le modèle de `MobileLoginView`/`MobileVerify2FAView`.

Proposition :

```
POST /mobile/auth/password-reset/
```
Body : `{"identifier": "patient@example.ga"}`
Réponse : `{"detail": "Si un compte correspond, un code a été envoyé.", "challenge": {...}}` — **toujours** ce message générique, y compris si l'identifiant n'existe pas (ne pas révéler l'existence d'un compte), comme le fait déjà la vue web.

```
POST /mobile/auth/password-reset/verify/
```
Body : `{"challenge_id": "uuid", "code": "123456"}`
Réponse : `{"reset_token": "jwt-signé-courte-durée-10min"}` — jeton intermédiaire dédié (signé, non un JWT d'auth), à durée de vie courte (10 min, comme `password_reset_authorized_until` côté web).

```
POST /mobile/auth/password-reset/confirm/
```
Body : `{"reset_token": "...", "new_password1": "...", "new_password2": "..."}`
Effets : identiques à `reset_password` côté web (invalide les codes en cours, journalise `AuthenticationEvent.PASSWORD_CHANGED`, envoie l'e-mail `send_password_changed`, `AuditLog`).

Note mobile : demande à l'app de vider ses JWT stockés après succès et de relancer une connexion propre (même remarque que pour le changement de mot de passe déjà documentée dans `api_contrat.md` §4).

### 3.3 Détail pharmacie (écran 09)

Il n'existe aucun serializer/vue dédié « détail pharmacie » aujourd'hui (seul `_pharmacy_payload` compact est utilisé, imbriqué dans stock/commande). L'écran Flutter affiche : nom, adresse, tags (Ouvert 24h/24, garde), services, horaires, téléphone, catalogue de la pharmacie.

Proposition :

```
GET /mobile/patient/pharmacies/<id>/
```
Réponse (nouveau payload, à bâtir à partir des champs déjà présents sur `Pharmacy`) :
```json
{
  "id": 3,
  "name": "Pharmacie du Centre",
  "zone": "libreville",
  "zone_label": "Libreville",
  "address": "Centre-ville",
  "phone": "+241011000000",
  "is_on_duty": false,
  "is_24_7": false,
  "is_open_now": true,
  "accepts_cash_on_delivery": true,
  "services": [{"code": "delivery", "label": "Livraison à domicile", "icon": "local_shipping"}],
  "weekly_hours": {"monday": {"open": "08:00", "close": "19:00", "closed": false}},
  "accepted_plan_ids": [4, 7],
  "photos": ["https://.../pharmacies/3/photos/xxx.jpg"]
}
```

```
GET /mobile/patient/pharmacies/<id>/catalog/
```
Même forme que `GET /mobile/patient/catalog/` mais filtrée sur `pharmacy_id=<id>` (utile pour l'écran 09 qui liste les produits de la pharmacie).

Note honnêteté : `latitude`/`longitude` existent déjà sur `Pharmacy` mais le calcul de distance réel nécessite la position du patient (géolocalisation), explicitement listée « hors contrat actuel ». Ne pas les exposer comme une distance calculée tant que la géolocalisation n'est pas branchée.

### 3.4 Historique financier agrégé (écran 18)

Deux options :

**Option A (recommandée, minimal) :** aucun nouvel endpoint. Flutter reconstruit l'écran 18 à partir de `GET /mobile/patient/orders/` (déjà paginé, contient `payment_status`, `total_fcfa`, `payment_transactions`). Chaque commande devient une ligne « Commande » avec son statut de paiement ; les remboursements se lisent depuis `payment_status in (refund_pending, refunded, partially_refunded)` + `refunded_amount_fcfa`.
Limite : pas de ligne « Remboursement #RF-xxxx » isolée comme dans le mockup Flutter — un remboursement est un état de la commande, pas une entité séparée. **La maquette Flutter actuelle (une ligne = une transaction, remboursement compris) devra être adaptée pour afficher une ligne par commande plutôt qu'une ligne par mouvement financier.**

**Option B :** nouvel endpoint agrégé dédié si on veut garder le modèle « une ligne par transaction financière » de la maquette Flutter :
```
GET /mobile/patient/finance/transactions/
```
Réponse paginée, une entrée par `PaymentTransaction` + par mouvement de remboursement, avec le format déjà utilisé (`status`, `amount_fcfa`, `pharmacy`, `order_reference`, `created_at`).

Recommandation : **Option A** pour l'instant (pas de nouveau modèle, pas de nouvel endpoint), à condition d'adapter légèrement l'écran Flutter à la prochaine itération de branchement réel.

### 3.5 Reprise d'un paiement (écrans 16 et 18)

Le payload `order.actions.can_retry_payment` existe déjà côté backend mais **aucune route ne permet réellement de reprendre un paiement** sur une commande déjà créée (seul `checkout` initie un paiement, au moment de la création de la commande).

Proposition :
```
POST /mobile/patient/orders/<id>/retry-payment/
```
Body : `{"payment_method_id": 2}` (optionnel — si absent, réutilise le moyen de paiement déjà associé à la commande)
Règles :
- uniquement si `order.payment_status in (pending, failed)` ;
- crée une nouvelle `PaymentTransaction` (réutilise `start_simulated_payment`/`start_ebilling_payment`, déjà présents dans `apps/payments/services.py`), sans recréer la commande.
Réponse : même forme que le bloc `payment` de `POST /mobile/patient/checkout/`.

### 3.6 Mon assurance (écran 19)

Les modèles existent déjà et sont pleinement fonctionnels côté web (`apps/insurance/models.py`, `apps/dashboards/views.py::insurance_affiliation_update/_remove`). Il ne manque que la surface API mobile.

```
GET /mobile/patient/insurance/insurers/
```
Réponse :
```json
{
  "insurers": [
    {
      "id": 1,
      "name": "CNAMGS",
      "plans": [
        {
          "id": 4,
          "name": "Formule Confort",
          "default_coverage_rate": 80,
          "category_rates": [
            {"category_id": 2, "category_name": "Parapharmacie", "coverage_rate": 50}
          ]
        }
      ]
    }
  ]
}
```

```
GET /mobile/patient/insurance/affiliation/
```
Réponse si affilié :
```json
{
  "affiliation": {
    "id": 8,
    "plan": {"id": 4, "name": "Formule Confort", "insurer": {"id": 1, "name": "CNAMGS"}, "default_coverage_rate": 80},
    "member_number": "CNAM-2026-0417",
    "declared_at": "2026-06-01T09:00:00Z"
  }
}
```
Réponse si non affilié : `{"affiliation": null}`.

```
POST /mobile/patient/insurance/affiliation/
```
Body : `{"plan_id": 4, "member_number": "CNAM-2026-0417"}`
Effet : `Affiliation.objects.update_or_create(patient=..., defaults={...})` — logique déjà écrite côté web (`insurance_affiliation_update`), à réexposer en API.

```
DELETE /mobile/patient/insurance/affiliation/
```
Effet : identique à `insurance_affiliation_remove` côté web.

**Écart de modèle important à signaler côté Flutter :** l'écran 19 actuel propose un champ libre « Nom de l'offre / Plan » saisi par le patient. Le backend, lui, exige de choisir un `Plan` **existant** (`AffiliationForm.plan` est un `ModelChoiceField`, pas un champ texte) — un plan est une entité gérée par l'assureur (avec son propre taux par défaut et ses dérogations), pas une donnée libre déclarée par le patient. **Il faudra remplacer le champ texte libre par une sélection d'assureur → plan réel**, alimentée par `GET /mobile/patient/insurance/insurers/`.

---

## 4. Évolutions de payloads existants (pas de nouveau modèle)

| Endpoint | Évolution | Pourquoi |
|---|---|---|
| `GET /mobile/patient/orders/<id>/` → `delivery` | ajouter `courier_phone` (déjà sur `User.phone`, juste absent du payload) | Écran 17 propose d'appeler le livreur |
| `GET /mobile/patient/orders/<id>/` → `delivery` | ajouter `eta` = `delivery_deadline` déjà existant, reformaté | Écran 17 affiche « Arrivée estimée 14:45 (12 min) » |
| `POST /mobile/patient/checkout/`, `GET .../orders/<id>/` | ajouter `insurance_discount_fcfa` et recalculer `total_fcfa` en conséquence | Écran 12/13/16 affichent déjà une « réduction assurance » dans l'implémentation Flutter (voir `CLAUDE.md`), mais rien ne la calcule côté backend aujourd'hui |
| `GET /mobile/patient/favorites/` | ajouter `is_low_stock` (comparaison avec `Stock.effective_low_stock_threshold` sur la meilleure offre) | Écran 10 distingue en stock / stock faible / rupture |
| `GET /mobile/patient/catalog/...` → `medication` | ajouter `packaging` (voir §6 modèle) | Affichage type « Boîte de 8 gélules » sur plusieurs écrans (08, 10, 11, 16, 22) |
| `GET /mobile/notifications/` | ajouter un champ `category` (`order`/`security`/`promo`) par entrée | Écran 20 filtre par catégorie, la catégorie « Sécurité » peut déjà être dérivée de `AuthenticationEvent` sans nouveau modèle (voir §7) |
| `GET/POST /mobile/support/tickets/` | ajouter le choix de catégorie `medication` (ou documenter le remappage Flutter vers `pharmacy`/`general`) | Réconciliation taxonomie, voir §11 |

---

## 5. Modèles Django à ajouter

Ces modèles n'existent nulle part dans le backend actuel.

### 5.1 `notifications.Notification` (recommandé, optionnel)

La spec Flutter (`maquette_mobile_patient.md`, écran 20) dit explicitement : *« le lu/non-lu dépendra d'un futur modèle persistant »* — ce document anticipait déjà ce besoin. `apps/notifications/models.py` est aujourd'hui un fichier vide.

```python
class Notification(models.Model):
    class Category(models.TextChoices):
        ORDER = "order", "Commande"
        SECURITY = "security", "Sécurité"
        PROMO = "promo", "Offre"
        SUPPORT = "support", "Support"

    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    category = models.CharField(max_length=16, choices=Category.choices)
    icon = models.CharField(max_length=40, blank=True)
    title = models.CharField(max_length=180)
    description = models.CharField(max_length=255, blank=True)
    target_type = models.CharField(max_length=20, blank=True)
    target_id = models.PositiveIntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=("recipient", "is_read", "created_at"))]
```
Effort : moyen (nécessite d'émettre une `Notification` à chaque transition pertinente : statut de commande, statut de livraison, nouvelle connexion `AuthenticationEvent`, etc. — remplace progressivement le flux agrégé calculé à la volée).

**Alternative sans nouveau modèle (minimale)** : garder le flux agrégé actuel, ajouter uniquement un champ `category` calculé (voir §6), et laisser le lu/non-lu **local à l'app** (comme c'est déjà le cas dans l'implémentation Flutter actuelle — état en mémoire, non persistant). C'est l'option la plus rapide et déjà compatible avec ce qui est construit.

### 5.2 `notifications.Promotion` (optionnel, seulement si on veut garder les notifications promo)

Rien dans le backend ne modélise une promotion/campagne (« Profitez de -15%... Code GABPHARMA15 » est une donnée statique du mockup Stitch, jamais reprise dans le Flutter réel d'ailleurs — l'app actuelle ne montre pas de notification promo hors du flux agrégé de commandes). **Recommandation : ne pas construire ce modèle tant qu'il n'y a pas de vraie fonctionnalité marketing/promotions côté produit.** À documenter comme hors-scope explicite, comme le fait déjà `api_contrat.md` pour d'autres sujets.

### 5.3 `deliveries.CourierRating` (optionnel, seulement si on veut garder la note du livreur)

L'écran 17 affiche « Jean M. ★ 4.9 • 850+ courses » — donnée entièrement inventée pour la démo, aucun modèle de notation livreur n'existe. Deux options :
- **Recommandé pour l'instant : retirer la note/nombre de courses de l'écran 17** lors du branchement réel (rien à construire) ;
- Ou construire un modèle de notation si le produit veut vraiment cette fonctionnalité (patient note le livreur après livraison) — hors scope de ce document, à cadrer séparément si retenu.

---

## 6. Modèles Django à mettre à jour

| Modèle | Champ à ajouter | Justification |
|---|---|---|
| `orders.Order` | `insurance_discount_fcfa = models.PositiveIntegerField(default=0)` | Nécessaire pour que `total_fcfa` reflète la réduction assurance déjà affichée côté Flutter (Checkout/Paiement) ; suit le même pattern que `subtotal_fcfa`/`delivery_fee_fcfa` (valeur figée au moment du checkout, pas recalculée après coup) |
| `orders.Order` | mettre à jour la propriété `total_fcfa` pour soustraire `insurance_discount_fcfa` | Cohérence avec le champ ci-dessus |
| `catalog.Medication` | `packaging = models.CharField(max_length=120, blank=True)` (ex. « Boîte de 16 comprimés », « Flacon 150ml ») | `dosage` seul (« 500 mg ») ne suffit pas à reproduire les libellés déjà utilisés dans plusieurs écrans Flutter (08, 10, 11, 16, 17, 22) |
| `accounts.OneTimeCode.Purpose` | ajouter le choix `REGISTRATION = "registration", "Inscription patient"` | Nécessaire pour §3.1 (réutilise `issue_code`/`verify_code` sans dupliquer la logique) |
| `support.SupportTicket.Category` | envisager d'ajouter `MEDICATION = "medication", "Médicament"` **ou** documenter le remappage Flutter vers une catégorie existante | Voir §11 — décision produit, pas obligatoire techniquement |

Aucune migration destructive : tous les ajouts ci-dessus sont des champs supplémentaires (avec valeur par défaut) ou des choix d'énumération supplémentaires, sans impact sur les données existantes.

---

## 7. Notifications : ce qui peut être fait sans nouveau modèle

`_patient_notifications()` (dans `apps/api/mobile_shared.py`) peut être étendu pour couvrir la catégorie **Sécurité** sans aucun nouveau modèle, en interrogeant `AuthenticationEvent` (déjà peuplé à chaque connexion/2FA) :

```python
security_events = AuthenticationEvent.objects.filter(
    user=user, event=AuthenticationEvent.Event.CODE_VERIFIED, purpose=OneTimeCode.Purpose.LOGIN_2FA,
).order_by("-created_at")[:5]
```
→ alimente directement les notifications « Nouvelle connexion » de l'écran 20, exactement comme le mockup Stitch le prévoyait.

La catégorie **Offres** reste sans source de données tant qu'aucun modèle promotion n'existe (voir §5.2) — recommandation : la retirer du filtre Flutter ou la laisser vide honnêtement (« Aucune offre pour le moment »), plutôt que d'inventer un contenu.

---

## 8. Décisions produit à trancher avant implémentation

1. **Inscription patient : activation immédiate après OTP, ou validation Staff ?** (Recommandation : immédiate — voir §3.1.)
2. **Historique financier (écran 18) : reconstruit depuis `orders` (Option A, recommandé) ou nouvel endpoint agrégé dédié (Option B) ?** — impacte directement la structure de l'écran Flutter (une ligne par commande vs une ligne par mouvement financier).
3. **Note/nombre de courses du livreur (écran 17) : on la retire, ou on construit un vrai modèle de notation ?**
4. **Notifications persistantes avec lu/non-lu réel : maintenant (nouveau modèle `Notification`, §5.1) ou plus tard (garder l'état local actuel, déjà fonctionnel en démo) ?**
5. **Notifications « Offres » : on les retire du filtre Flutter tant qu'il n'y a pas de modèle promotion, ou on construit `Promotion` maintenant ?**
6. **Taxonomie des catégories de tickets support : on ajoute `medication` côté backend, ou on remappe le bouton « Médicaments » de l'écran 21 vers une catégorie existante (`pharmacy` ou `general`) ?**
7. **Zone Bikélé absente du sélecteur de commune Checkout (écran 12) : à ajouter, simple oubli côté Flutter, aucune dépendance backend.**

---

## 9. Ordre de branchement recommandé côté Flutter Patient

Aligné sur `api_contrat.md` §10, mais réordonné pour suivre les lots déjà construits côté Flutter :

1. **Auth + 2FA** (déjà prêt côté backend) — stockage sécurisé des tokens (`flutter_secure_storage` ou équivalent, à ajouter aux dépendances).
2. **Inscription + mot de passe oublié** (§3.1, §3.2) — à construire côté backend en premier, car ce sont les deux seuls trous du Lot 1.
3. **Accueil, catalogue, favoris, détail médicament** — prêt, brancher directement.
4. **Détail pharmacie** (§3.3) — à construire côté backend (petit effort, données déjà présentes sur `Pharmacy`).
5. **Panier, checkout, paiement simulé** — prêt, **sauf réduction assurance** (§6) à ajouter avant de brancher Checkout/Paiement fidèlement.
6. **Commandes (liste/détail/actions)** — prêt, prévoir le remappage des statuts (§11) côté Flutter en parallèle.
7. **Livraison** — prêt à 80 %, compléter le payload (§6) avant de brancher l'écran 17.
8. **Paiements et remboursements** — trancher l'option A/B (§3.4/§9) avant de brancher l'écran 18.
9. **Mon assurance** (§3.6) — à construire côté backend (exposition d'un modèle déjà existant, effort modéré) avant de brancher l'écran 19, et adapter le formulaire Flutter (sélection de plan réel, pas de texte libre).
10. **Notifications** — brancher le flux agrégé existant tel quel pour la catégorie Commandes, étendre à Sécurité (§7) avant de brancher les filtres Flutter à l'identique ; laisser Offres de côté (décision §9.5).
11. **Centre d'aide, tickets, conversation support** — prêt, réconcilier la taxonomie de catégories (§11) avant de brancher le formulaire de création de ticket.
12. **Profil, sécurité et paramètres** — prêt pour profil/mot de passe ; session locale et biométrie restent des états d'appareil, rien à brancher.

---

## 10. Annexe — réconciliation des énumérations Flutter ↔ Django

### Statuts de commande

Flutter (`_OrderStatus`, écran 15, 4 valeurs) : `pending` (En attente), `inProgress` (En cours), `delivered` (Livré), `cancelled` (Annulé).

Django (`Order.Status`, 11 valeurs) : `pending`, `changes_proposed`, `accepted`, `preparing`, `ready_for_pickup`, `awaiting_courier`, `in_delivery`, `completed`, `rejected`, `cancelled`, `expired`.

Remappage proposé pour le filtre à 4 boutons de l'écran 15 (à garder tel quel dans l'UI, mapper en interne) :
- **En attente** → `pending`, `changes_proposed`
- **En cours** → `accepted`, `preparing`, `ready_for_pickup`, `awaiting_courier`, `in_delivery`
- **Livré** → `completed`
- **Annulé** → `rejected`, `cancelled`, `expired`

L'écran 16 (détail commande), lui, doit refléter le statut réel précis (les 11 valeurs), pas seulement les 4 catégories — son `_OrderStage` actuel (`proposal/preparing/delivering/delivered/cancelled`) est déjà plus proche du modèle réel et demandera un remappage plus fin mais direct.

### Catégories de support

Flutter (écran 21, 4 boutons) : Médicaments, Livraison, Paiements, Compte.

Django (`SupportTicket.Category`, 7 valeurs) : `general`, `account`, `order`, `delivery`, `payment`, `pharmacy`, `other`.

Remappage proposé si on ne modifie pas le backend (voir décision §9.6) :
- **Médicaments** → `pharmacy` (le plus proche sémantiquement)
- **Livraison** → `delivery`
- **Paiements** → `payment`
- **Compte** → `account`

### Priorités de ticket

Flutter (écran 21) : Basse, Normale, Haute — Django (`SupportTicket.Priority`) ajoute `urgent`. Simple ajout d'un 4ᵉ niveau côté Flutter le jour du branchement, aucun travail backend.

### Statuts de paiement

Déjà 1:1 entre le Flutter (`_PaymentStatus`, écran 18) et Django (`Order.PaymentStatus`) : `unpaid`/`pending`/`paid`/`failed`/`refund_pending`/`partially_refunded`/`refunded` — bon alignement, à l'exception du fait que Flutter modélise un remboursement comme une ligne indépendante (voir §3.4).
