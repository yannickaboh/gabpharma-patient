# Gab'Pharma Patient — suivi d'implémentation Flutter

**Dernière mise à jour :** 9 juillet 2026
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
- [ ] 10 Favoris — **prochain écran**
- [ ] 11 Panier (déjà un socle basique dans `patient_shell.dart`, à confronter au mockup `11_panier`)
- [ ] 12 Checkout (socle basique dans `detail_screens.dart`, à revoir)
- [ ] 13 Paiement
- [ ] 14 Confirmation de commande

### Lot 3 — Commandes, livraison, finances (pas commencé)
- [ ] 15 Liste des commandes
- [ ] 16 Détail commande (socle basique existant)
- [ ] 17 Suivi de livraison
- [ ] 18 Paiements et remboursements

### Lot 4 — Assurance, assistance, compte (pas commencé)
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

## Tester sur le Samsung Galaxy S8 (ADB)

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

Reprendre à l'écran **10 — Favoris** (`stitch_gab_pharma_patient_app/10_favoris/`), en suivant la méthode ci-dessus, puis continuer le Lot 2 (Panier, Checkout, Paiement, Confirmation de commande) écran par écran avec validation utilisateur à chaque étape.
