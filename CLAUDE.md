# Gab'Pharma Patient — suivi d'implémentation Flutter

**Dernière mise à jour :** 14 juillet 2026
**Mode actuel :** démonstration statique, aucune connexion à l'API mobile (pas encore construite côté Django).

## Méthode de travail (à respecter pour chaque nouvel écran)

Pour chaque écran du dossier `stitch_gab_pharma_patient_app/<NN_nom_ecran>/` :
1. Lire la section correspondante dans `stitch_gab_pharma_patient_app/maquette_mobile_patient.md` (rôle fonctionnel, états attendus).
2. Ouvrir `screen.png` (source de vérité visuelle) ET `code.html` (valeurs exactes : couleurs, radius, paddings, tailles).
3. Si l'image et le code divergent, privilégier l'image et signaler l'écart à l'utilisateur.
4. Implémenter en Flutter/Material 3, tester sur le Samsung Galaxy S8 via ADB, et **attendre la validation visuelle de l'utilisateur avant de passer à l'écran suivant**.
5. Toujours dire en une phrase ce qui a été implémenté et les écarts assumés par rapport au mockup (pas de New devinette).

## État d'avancement des 26 écrans

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
- [x] 17 Suivi de livraison (carte réelle non branchée — remplacée par un fond illustratif explicite ; timeline réutilisée depuis l'écran 16 ; code de remise jamais affiché, seulement "envoyé par SMS")
- [x] 18 Paiements et remboursements (historique financier avec statuts paid/pending/failed/refund_pending/refunded, reprise de paiement en attente, totaux recalculés dynamiquement depuis la liste plutôt que copiés du mockup)

**Lot 3 terminé et validé.**

### Lot 4 — Assurance, assistance, compte (en cours)
- [ ] 19 Mon assurance
- [ ] 20 Notifications
- [ ] 21 Centre d'aide et tickets
- [ ] 22 Conversation Support
- [x] 23 Profil Patient (fait en avance, avec écran "Modifier mes informations")
- [ ] 24 Sécurité et paramètres

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
- **Carte réelle (écran 17)** : aucun SDK cartographique branché pour l'instant — remplacée par un fond illustratif dégradé + pins Material, avec mention explicite "carte simplifiée, à titre illustratif". **Décision utilisateur : le SDK Google Maps sera intégré plus tard, lors du branchement de l'API réelle.**
- **Code de remise livraison (écran 17)** : jamais affiché en clair, conformément à la spec — seule la mention "Code de remise envoyé par SMS (canal sécurisé)" apparaît une fois le colis récupéré par le livreur.
- **Cohérence des totaux financiers (écran 18)** : les totaux du bandeau (dépenses/remboursements) sont recalculés dynamiquement depuis la liste de transactions affichée plutôt que copiés du mockup, qui était lui-même incohérent (45 200 FCFA de total affiché alors que les transactions "payé" visibles ne totalisaient que 23 600 FCFA).
- **Commandes/paiements/livraison — données de démo liées par référence** : `_orderDetails` (détail commande), `_deliveryTrackingDefault` (livraison) et la liste `OrdersScreen` partagent les mêmes références `GP-260x-xxxx` et montants pour rester cohérents d'un écran à l'autre ; `_financialTransactions` (écran 18) est un historique séparé et volontairement plus large (inclut des transactions échouées/remboursées hors de la liste des 4 commandes de démo).

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

Lot 3 (Commandes, livraison, finances, écrans 15 à 18) terminé et validé. Reprendre au **Lot 4 — Assurance, assistance, compte**, en commençant par l'écran **19 — Mon assurance** (`stitch_gab_pharma_patient_app/19_mon_assurance/` ou nom de dossier équivalent — vérifier le nom exact dans `stitch_gab_pharma_patient_app/`), en suivant la méthode ci-dessus. Écrans 20, 21, 22 et 24 restent aussi à faire dans ce lot (23 déjà fait en avance).
