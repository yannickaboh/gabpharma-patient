# Application Flutter Patient Gab'Pharma — conception et implémentation

**Dernière mise à jour :** 6 juillet 2026
**Statut :** socle Flutter Android implémenté ; API mobile Django à construire
**Cible minimale :** 24 interfaces distinctes
**Cible confortable :** 28 à 32 interfaces en séparant davantage les étapes et les détails

## 0. État de l'implémentation Flutter

Le projet autonome est créé dans `C:\Users\24174\StudioProjects\gabpharma_patient`.

Le socle livré comprend le thème Material 3 Gab'Pharma, le splash, la connexion,
la vérification 2FA, la navigation principale à cinq destinations, les interfaces
du parcours Patient, un client HTTP configurable par `API_BASE_URL`, le squelette
Android et un test widget. Tant que l'API mobile n'existe pas, l'application
démarre explicitement en mode démonstration et ne prétend exécuter aucune règle
métier réelle.

Validation du 6 juillet 2026 : `dart analyze` sans erreur et test widget Flutter
au vert.

## 1. Objectif

L'application Patient doit transposer le parcours métier déjà fonctionnel sur le web sans recopier mécaniquement les 11 onglets du dashboard. Le parcours mobile prioritaire est :

```text
Rechercher un médicament OTC → choisir une pharmacie → constituer un panier
→ choisir retrait/livraison et paiement → suivre la commande → obtenir de l'aide
```

Le MVP mobile doit rester aligné sur les règles Django existantes :

- médicaments OTC publiés et actifs uniquement ;
- un panier ne contient que les produits d'une seule pharmacie ;
- prix et stock proviennent du stock réel de l'officine ;
- paiement à la livraison ou paiement électronique — encore simulé tant qu'aucune passerelle réelle n'est intégrée ;
- couverture assurance informative, uniquement si la pharmacie accepte le plan ;
- le code de remise d'une livraison n'est jamais affiché dans l'application : le patient reçoit l'information par le canal sécurisé prévu ;
- aucune promesse médicale, aucun diagnostic et aucune substitution automatique non validée.

## 2. Architecture de navigation

Navigation principale recommandée à cinq destinations :

1. **Accueil** ;
2. **Recherche** ;
3. **Panier** ;
4. **Commandes** ;
5. **Profil**.

Les Favoris, Notifications, Paiements, Assurance et Support sont accessibles depuis l'Accueil et le Profil. Le badge du Panier affiche le nombre d'articles ; les Notifications peuvent afficher un badge non lu lorsqu'un vrai mécanisme de lecture sera disponible.

## 3. Inventaire des 24 interfaces

### Authentification et accès

| N° | Interface | Description fonctionnelle |
|---:|---|---|
| 1 | Splash et restauration de session | Affiche brièvement la marque Gab'Pharma, vérifie la session locale, la version minimale de l'application et la connectivité. Redirige vers Connexion ou Accueil. Prévoir états hors ligne, maintenance et mise à jour obligatoire. |
| 2 | Connexion | Identifiant e-mail/téléphone/nom d'utilisateur, mot de passe, affichage/masquage, « Se souvenir de moi », lien Mot de passe oublié. Une authentification valide ouvre obligatoirement l'étape 2FA. |
| 3 | Vérification 2FA | Saisie du code à 6 chiffres, compteur avant renvoi, changement de compte, messages code invalide/expiré/limité. Ne jamais révéler si un compte inconnu existe. |
| 4 | Inscription Patient | Prénom, nom, e-mail, téléphone, mot de passe et consentements. Validation progressive, résumé des conditions et confirmation avant création. Le compte reste soumis au même parcours 2FA. |
| 5 | Récupération du mot de passe | Parcours multi-étapes dans une même interface : identification, code reçu, nouveau mot de passe, confirmation. Afficher clairement les règles de robustesse. |

### Recherche et achat

| N° | Interface | Description fonctionnelle |
|---:|---|---|
| 6 | Accueil Patient | Salutation, barre de recherche dominante, raccourcis Commandes/Favoris/Assurance/Support, pharmacies ou produits récemment consultés, commande active éventuelle et alertes importantes. Aucune donnée fictive lorsque l'API ne renvoie rien. |
| 7 | Recherche et résultats | Recherche par nom commercial ou DCI, filtres zone/catégorie/forme/pharmacie, tri disponibilité/prix/proximité future. Chaque résultat montre médicament, dosage, prix, stock et pharmacie ; seuls les produits réellement commercialisables sont affichés. |
| 8 | Détail médicament | Nom, DCI, dosage, forme, catégorie, statut OTC, pharmacies qui le proposent, prix/stock par pharmacie, ajout aux favoris et au panier. Si le panier contient une autre pharmacie, expliquer le conflit avant de proposer de le vider. |
| 9 | Détail pharmacie | Nom, adresse/zone, horaires, zones desservies, paiement à la livraison, assurances/plans acceptés, catalogue OTC disponible et statut partenaire vérifié. Pas de données contractuelles inventées. |
| 10 | Favoris | Médicaments favoris avec disponibilité recalculée au moment de l'affichage. Permet de retirer un favori, ouvrir le médicament ou rechercher une pharmacie qui le propose. État vide pédagogique. |
| 11 | Panier | Articles de l'unique pharmacie, quantité modifiable dans la limite du stock, suppression, sous-total et pharmacie concernée. Afficher immédiatement les changements de stock/prix et bloquer le checkout si le panier devient invalide. |
| 12 | Checkout | Adresse, zone, retrait ou livraison, moyen de paiement, affiliation d'assurance informative, récapitulatif et frais de livraison. Afficher l'estimation de couverture uniquement si la pharmacie accepte le plan ; préciser qu'elle ne constitue pas une validation de droits. |
| 13 | Paiement | Choix Espèces/Airtel Money/Moov Money/Visa selon les moyens actifs. Gérer `pending`, réussite, échec et reprise. Tant que la passerelle est simulée, afficher clairement l'environnement de démonstration aux testeurs. |
| 14 | Confirmation de commande | Référence, pharmacie, mode retrait/livraison, paiement, montant, prochaine étape et bouton « Suivre ma commande ». Ne jamais annoncer une acceptation pharmacie avant sa réponse réelle. |

### Commandes, livraison et finances

| N° | Interface | Description fonctionnelle |
|---:|---|---|
| 15 | Liste des commandes | Liste chronologique avec filtres En attente/En cours/Terminées/Annulées. Chaque carte montre référence, pharmacie, montant, date, statut commande et statut financier. |
| 16 | Détail commande | Articles et prix figés à la commande, historique des transitions, pharmacie, adresse, mode, paiement, proposition de quantité éventuelle et actions autorisées : accepter/refuser la proposition, annuler quand le statut le permet, reprendre un paiement. |
| 17 | Suivi de livraison | Statut de la course, pharmacie de collecte, adresse, livreur lorsqu'il est affecté, retard éventuel et chronologie. Afficher « Code envoyé par le canal sécurisé » après collecte, jamais le code lui-même. Bouton Support lié à la commande. |
| 18 | Paiements et remboursements | Historique financier, moyen utilisé, `unpaid/pending/paid/failed/refund_pending/refunded`, reprise d'un paiement en attente et explication du remboursement. Le remboursement effectif reste manuel/simulé tant que la passerelle réelle n'existe pas. |

### Assurance, assistance et compte

| N° | Interface | Description fonctionnelle |
|---:|---|---|
| 19 | Mon assurance | Déclarer ou modifier assureur, numéro d'adhérent et plan ; afficher taux par défaut, dérogations par catégorie et caractère informatif. Permettre le retrait de l'affiliation. Aucune vérification de droits prétendue. |
| 20 | Notifications | Flux des transitions de commandes, échéances de réponse et livraisons. Chaque notification ouvre le bon détail. Prévoir filtres et état vide ; le lu/non lu dépendra d'un futur modèle persistant. |
| 21 | Centre d'aide et tickets | FAQ courte, catégories, liste des tickets et création d'une demande avec sujet, message, commande liée et pièce jointe. Afficher statut, priorité et dernière activité. |
| 22 | Conversation Support | Fil chronologique des messages visibles du patient, pièces jointes protégées et champ de réponse. Les notes internes Staff ne doivent jamais être exposées. |
| 23 | Profil Patient | Avatar initiales, prénom, nom, téléphone, nom d'utilisateur, e-mail en lecture seule et raccourcis Assurance/Sécurité. Modification via formulaire validé côté serveur. |
| 24 | Sécurité et paramètres | Changement de mot de passe avec mot de passe actuel, gestion de session locale, préférences de notifications, confidentialité, conditions et déconnexion. La 2FA reste obligatoire et ne possède pas d'interrupteur de désactivation. |

## 4. États transversaux obligatoires

Chaque interface de données doit prévoir :

- chargement avec skeleton plutôt qu'un écran vide ;
- état vide avec explication et action utile ;
- perte de connexion avec nouvelle tentative ;
- erreur serveur sans détail technique ;
- session expirée avec retour contrôlé vers Connexion ;
- action en cours non soumissible deux fois ;
- succès avec confirmation discrète et navigation prévisible ;
- textes et montants en français, devise `FCFA`, dates `jj/mm/aaaa`.

## 5. Direction visuelle Gab'Pharma

Réutiliser l'identité définie dans `documentation/stitch/gab_pharma_visual_identity/DESIGN.md` :

- police **Inter** ;
- fond vert très pâle `#EDFDF4` ;
- primaire `#006A35`, secondaire `#206B3D` ;
- cartes blanches ou `#E7F7EE`, texte principal `#111E19` ;
- erreur `#BA1A1A`, avertissement ambre réservé aux échéances ;
- grille d'espacement 8 px, cartes 16 px de rayon, boutons 12 à 16 px ;
- cibles tactiles d'au moins 44 px, contraste lisible, libellés visibles ;
- Material Symbols arrondis, illustrations médicales sobres, pas de croix rouge décorative ni d'imagerie anxiogène.

## 6. Dépendances backend avant Flutter

La création des écrans ne suffit pas. Il faudra une API mobile authentifiée couvrant au minimum : authentification/2FA, catalogue et stocks, favoris, panier, checkout, commandes, paiement, livraison, affiliation, support, notifications et profil. Les règles doivent rester dans les services Django existants ; Flutter ne doit jamais recalculer seul le stock, la couverture, les transitions ou les permissions.

## 7. Prompt proposé pour Google Stitch

```text
Conçois une application mobile Patient haute fidélité nommée « Gab'Pharma », destinée au Gabon, en français, format Android portrait 390 × 844 px. Génère 24 écrans distincts et nommés, cohérents entre eux, comme un véritable produit de santé et de pharmacie, pas comme un dashboard web réduit.

OBJECTIF PRODUIT
Le patient recherche uniquement des médicaments OTC réellement disponibles, choisit une pharmacie, constitue un panier limité à une seule pharmacie, choisit retrait ou livraison, paie, suit sa commande et contacte le support. L'assurance affichée est une estimation informative. Aucun diagnostic, aucune promesse médicale et aucune donnée fictive présentée comme réelle.

IDENTITÉ VISUELLE
- Material Design 3, moderne, rassurant, sobre et accessible.
- Police Inter.
- Background #EDFDF4, primary #006A35, secondary #206B3D.
- Cartes blanches ou #E7F7EE, texte #111E19, texte secondaire #3F4940.
- Erreur #BA1A1A, ambre uniquement pour attente/échéance.
- Grille 8 px, cartes radius 16 px, boutons radius 12 px, ombres très légères.
- Touch targets 44 px minimum, contraste élevé, Material Symbols arrondis.
- Utiliser des données gabonaises réalistes : Libreville, Akanda, Owendo, FCFA, noms francophones. Ne pas utiliser lorem ipsum.

NAVIGATION
Bottom navigation à 5 destinations : Accueil, Recherche, Panier, Commandes, Profil. Badge discret sur Panier. Favoris, Assurance, Notifications, Paiements et Support accessibles depuis Accueil/Profil.

ÉCRANS À PRODUIRE
01 Splash/restauration session avec états hors ligne et maintenance.
02 Connexion e-mail/téléphone/nom d'utilisateur + mot de passe.
03 Vérification 2FA à 6 chiffres avec renvoi temporisé.
04 Inscription Patient et consentements.
05 Récupération/réinitialisation du mot de passe en étapes.
06 Accueil avec recherche dominante, commande active et raccourcis.
07 Recherche avec filtres zone/catégorie/forme et résultats stock/prix/pharmacie.
08 Détail médicament OTC avec DCI, dosage, pharmacies, favori et ajout panier.
09 Détail pharmacie avec adresse, horaires, zones, paiements et plans acceptés.
10 Favoris avec disponibilité recalculée.
11 Panier mono-pharmacie avec quantités, stock et sous-total.
12 Checkout : adresse, zone, retrait/livraison, assurance, moyen de paiement, résumé.
13 Paiement avec Espèces, Airtel Money, Moov Money, Visa et états pending/success/error.
14 Confirmation de commande avec prochaine étape sans fausse promesse d'acceptation.
15 Liste des commandes avec filtres de statut.
16 Détail commande avec articles, historique et actions autorisées.
17 Suivi livraison avec timeline, livreur, retard et support ; ne jamais afficher le code OTP.
18 Paiements/remboursements avec statuts financiers compréhensibles.
19 Mon assurance avec assureur, plan, numéro d'adhérent et estimation informative.



c'est possible de commencer a mettre en place les interfaces [ screens ] on a un dossier stitch qui contient les interfaces dumoins la maquette de l'ensemble des screens - tu peux aussi lire le fichier maquette_mobile_patient.md afin de comprendre - j'aimerais beaucoup pour test les faire sur mon telephone mobile samsung s8, donc si possible on pourra utiliser adb et ses commandes qu'il faudra me donner - aucune connexion a une api quelconque pour un debut tu peux commencer avec le premier lot [ splash, login, forgot, reset, 2fa, ... ]  NB: que les screens soient fidelement identiques aux maquettes respectives car dans chaque maquette on l'image et du code que tu peux lire pour te faire une idee a chaque fois 
