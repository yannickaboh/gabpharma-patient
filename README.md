# Gab'Pharma Patient

Application Flutter Android destinée aux patients Gab'Pharma.

## Démarrage

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/mobile/v1
```

`10.0.2.2` pointe vers la machine hôte depuis l'émulateur Android. L'application
fonctionne actuellement en mode démonstration tant que l'API mobile Django n'est
pas exposée. Les règles métier restent volontairement côté serveur.

## Socle livré

- thème Gab'Pharma Material 3 ;
- splash, connexion et vérification 2FA ;
- navigation Accueil, Recherche, Panier, Commandes, Profil ;
- accès aux 24 interfaces prévues dans `documentation/mobile_patient.md` ;
- client HTTP natif configurable par `API_BASE_URL` ;
- états de démonstration explicitement signalés ;
- test widget de démarrage.
