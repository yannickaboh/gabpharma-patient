# Gab'Pharma — pistes de réorientation vers d'autres domaines

**Créé le :** 25 août 2026
**Contexte :** `rgpd.md` a identifié un risque réglementaire réel — mais **non confirmé, pas un blocage avéré** — sur le modèle marketplace-pharmacie au Gabon et au Congo-Brazzaville (position déontologique de l'Ordre des Pharmaciens contre la vente en ligne/livraison via intermédiaire commercial). Ce document répond à la question de repli : à ce niveau d'avancement technique, qu'est-ce qui est réellement réutilisable, dans quels autres domaines, avec quel potentiel business chiffré.

**⚠️ Même avertissement que `rgpd.md`** : les chiffres cités ci-dessous viennent de recherches web publiques (presse économique gabonaise, agences de presse spécialisées, statistiques officielles relayées), pas d'une étude de marché commandée. Ils donnent un ordre de grandeur et un sens (marché en croissance ou sous-pénétré) suffisant pour prioriser une piste, **pas** une base suffisante pour lever des fonds ou écrire un business plan définitif sans vérification indépendante.

---

## Ce qui a été construit — l'actif technique réel, au-delà de "pharmacie"

Le constat central de ce document : **l'essentiel de ce qui a été construit n'a rien de spécifique à la pharmacie.** Sur les 24 écrans et les ~15 modules branchés à l'API réelle, la partie strictement "médicament" (modèle `Medication`, champ `requires_prescription`, dosage/DCI/forme galénique) représente une fraction limitée du système. Le reste est un **moteur générique de marketplace local avec livraison**, réutilisable tel quel :

| Module déjà construit | Ce qu'il fait vraiment (générique) |
|---|---|
| Authentification (login, 2FA email+TOTP, inscription, mot de passe oublié, verrouillage biométrique) | Moteur d'identité/KYC complet, sans aucune dépendance métier |
| Recherche + catalogue + filtres (catégorie, zone, forme) + géolocalisation | Moteur de découverte multi-vendeurs par proximité, avec tri par distance réelle (Haversine côté serveur) |
| Panier (règle mono-vendeur), Checkout, Paiement (simulé, prêt pour une vraie passerelle) | Moteur de commande e-commerce/marketplace classique |
| Commandes (statuts, timeline, annuler/accepter/refuser une modification, reprise de paiement) | Moteur de gestion de commandes et de fulfillment |
| Assurance (affiliation assureur→formule, taux de couverture par catégorie, dérogations) | Moteur de tiers-payant / subvention — indépendant du fait que le produit couvert soit un médicament |
| Notifications (in-app agrégées + push FCM avec deep-link) | Moteur de notification générique |
| Support (tickets par catégorie, conversation, priorité/SLA) | Moteur de support client générique |
| Profil/Sécurité (changement mot de passe/e-mail, désactivation réversible, appareils enregistrés) | Générique |

**Estimation grossière** : moins de 20% du code (essentiellement le modèle `Medication` et son affichage) est spécifique à la pharmacie. Le reste — soit la grande majorité de l'effort déjà investi — se transpose directement.

## Critères retenus pour prioriser les pistes ci-dessous

1. **Pas d'ordre professionnel ou d'autorité sectorielle avec un pouvoir de blocage direct sur la vente elle-même**, contrairement à l'Ordre des Pharmaciens identifié dans `rgpd.md`.
2. **Marché sous-pénétré ou en forte croissance** au Gabon (et idéalement en zone CEMAC élargie), avec au moins un chiffre public vérifiable.
3. **Réutilisation directe estimée à plus de 60%** de l'architecture déjà construite.

---

## 1. 🥇 Marketplace de matériaux de construction & quincaillerie (BTP) — recommandation principale

**Opportunité chiffrée** : le secteur BTP gabonais a réalisé 123,4 milliards FCFA de chiffre d'affaires au seul 4e trimestre 2025, en hausse de **+61,8%** par rapport au trimestre précédent — la meilleure performance sectorielle annuelle du pays selon Sikafinance. Sur l'enveloppe 2025 de prêts-projets (190,5 milliards FCFA), **59% sont fléchés vers les routes et le BTP**, avec des bailleurs actifs et identifiés (Banque mondiale, BAD, Standard Chartered, Deutsche Bank).

**Douleur actuelle (hypothèse à valider sur le terrain, non vérifiée par cette recherche)** : l'approvisionnement de chantier dépend généralement de quincailleries/dépôts dispersés, sans comparateur de prix/disponibilité en temps réel ni logistique de livraison mutualisée — un problème structurellement proche de celui que l'app patient résolvait déjà pour les médicaments (comparer prix et disponibilité entre plusieurs points de vente proches).

**Réutilisation directe** :
- Pharmacie → dépôt/quincaillerie ; médicament → article (ciment, fer à béton, plomberie, électricité) avec un champ "unité" (sac, mètre, tonne) à la place de dosage/forme.
- Règle mono-pharmacie du panier → mono-dépôt par commande, cohérente avec une livraison de chantier groupée.
- Géolocalisation déjà branchée → dépôt le plus proche du chantier.
- Statut "de garde/24h" → dépôt ouvert le week-end, pertinent pour les chantiers.

**Modèle économique** : abonnement SaaS mensuel aux dépôts/quincailleries pour lister leur stock en temps réel, plus une commission modeste ou des frais de livraison sur les commandes facilitées — éviter une commission élevée assise uniquement sur la vente, pour rester dans une zone économiquement comparable à un simple prestataire logistique/technologique plutôt qu'à un "intermédiaire de vente".

**Régulation** : pas d'ordre professionnel équivalent à l'Ordre des Pharmaciens identifié pour la quincaillerie/matériaux de construction dans cette recherche — risque réglementaire structurel nettement inférieur à celui documenté dans `rgpd.md`.

**Effort de pivot** : faible à moyen. Renommer les entités (`Pharmacy`→`Depot`, `Medication`→`Product`), retirer les champs spécifiques (prescription, DCI), ajouter une notion d'unité de vente. La quasi-totalité du reste (auth, panier, checkout, paiement, commandes, notifications, support) est réutilisable sans changement de logique.

---

## 2. Assurtech — comparateur et courtage d'assurance digital

**Opportunité chiffrée** : le taux de pénétration de l'assurance au Gabon plafonne autour de **1% du PIB**, contre environ 2% au Sénégal et jusqu'à 2,5% pour les meilleurs élèves de la zone CIMA — le Gabon est en 5e position dans sa propre zone régionale malgré un PIB par habitant élevé. Le marché gabonais pèse environ **100 milliards FCFA de primes annuelles**, avec une densité d'assurance de 88 USD/habitant (donnée 2020, zone CIMA moyenne à 13,64 USD/habitant sur la même période — le Gabon est donc mieux doté que la moyenne régionale en valeur absolue, mais très en dessous de son potentiel relatif au PIB).

**Ce qui rend cette piste particulière** : ce n'est pas seulement un marché sous-pénétré — c'est un module **déjà construit et vérifié en production**. L'écran "Mon Assurance" de l'app patient (affiliation à un assureur, sélection en cascade assureur→formule, calcul du taux de couverture par catégorie avec dérogations, retrait d'affiliation) est déjà, fonctionnellement, un embryon d'assurtech, développé et testé indépendamment du reste de l'app.

**Réutilisation directe** : très élevée sur ce module précis (~70%, il faudrait ajouter la souscription en ligne et le suivi de sinistre/remboursement, qui n'existent pas aujourd'hui — l'app actuelle ne fait qu'afficher une affiliation déjà existante côté back-office).

**Modèle économique** : commission de courtage à la souscription (modèle classique et légal d'agent/courtier d'assurance), ou SaaS de distribution digitale vendu aux assureurs eux-mêmes qui cherchent à digitaliser leur canal de vente.

**Régulation** : le courtage d'assurance est un métier réglementé par la **CIMA** (Conférence Interafricaine des Marchés d'Assurances, régulateur régional commun à 14 pays dont le Gabon et le Congo) et nécessite un agrément national — mais c'est un cadre **connu, stable, et non structurellement hostile à la distribution digitale**, à la différence du signal trouvé pour la pharmacie dans `rgpd.md`. Ce point reste à vérifier spécifiquement (agrément de courtage, conditions d'un comparateur/agrégateur multi-assureurs) avant tout engagement.

**Effort de pivot** : moyen — le module existe déjà à un stade avancé, mais souscription et gestion de sinistre sont un développement neuf, plus complexe que le reste du catalogue.

---

## 3. Marketplace agroalimentaire / circuits courts producteurs-consommateurs

**Opportunité chiffrée** : le Gabon importe entre 60% et 80% de son alimentation selon les sources (les chiffres varient selon la méthodologie et la période), pour une facture évaluée à environ **550 milliards FCFA par an**. Le gouvernement affiche un objectif de **50% d'autosuffisance alimentaire d'ici 2027**, alors que le secteur agricole ne pèse que 5,2% du PIB en 2024 — un écart qui traduit une volonté politique (et potentiellement des financements publics/bailleurs) pas encore transformée en résultats.

**Douleur actuelle (hypothèse)** : le Gabon est le pays le plus urbanisé d'Afrique (91,4% de la population vit en ville, 2,57 millions d'habitants) — une bonne partie du problème d'approvisionnement local n'est probablement pas seulement un problème de production, mais de **distribution** entre producteurs ruraux/périurbains et consommateurs urbains, exactement le type de problème qu'un marketplace géolocalisé avec logistique de livraison adresse.

**Réutilisation** : Pharmacie → producteur/coopérative agricole ou point de collecte ; médicament → produit frais ou panier. Le module Assurance pourrait, à plus long terme, devenir un mécanisme d'avance sur récolte ou de garantie — piste plus lointaine, non chiffrée ici.

**Modèle économique** : commission sur transaction (modèle marketplace standard) ou abonnement type "panier hebdomadaire".

**Régulation** : aucun ordre professionnel bloquant identifié dans cette recherche. Alignement possible avec les programmes publics de souveraineté alimentaire, donc accès potentiel à du financement de bailleurs déjà actifs au Gabon (Banque mondiale, BAD, cités par ailleurs comme financeurs d'infrastructures).

**Effort de pivot** : moyen à élevé — la gestion de la fraîcheur/périssabilité et une logistique plus contrainte (chaîne du froid, délais courts) sont des complexités nouvelles, absentes du modèle pharmacie/BTP.

---

## 4. Livraison de repas (food delivery) — piste la moins différenciée

**Opportunité** : marché déjà validé dans la région — Glovo est présent dans les pays voisins (application listée sur l'App Store pour le Congo), Yassir est actif en Afrique francophone, et **un acteur local existe déjà à Libreville** (ExpressGo, livraison de repas en moins de 30 minutes).

**Le problème principal de cette piste n'est pas réglementaire, il est concurrentiel** : contrairement aux trois pistes précédentes, un joueur local est déjà identifié et opérationnel sur ce marché précis, ce qui réduit fortement l'avantage du premier entrant.

**Réutilisation** : très élevée (>80%, Pharmacie → restaurant est une transposition presque triviale), mais différenciation produit faible sans angle spécifique (ex. cibler un segment ou une zone géographique non couverte par ExpressGo).

**Régulation** : aucune restriction déontologique équivalente à celle du secteur pharmaceutique.

**Effort de pivot** : faible techniquement, mais risque business élevé (concurrence directe, pas de vide de marché).

---

## 5. Option B2B : vendre le moteur en marque blanche plutôt qu'opérer un marketplace

Une piste transversale, orthogonale aux quatre précédentes : au lieu d'opérer soi-même un marketplace (et donc de porter le risque réglementaire du secteur choisi), **vendre l'infrastructure logicielle** (gestion de commandes, livraison, notifications, support client, paiement) en marque blanche à des commerçants déjà en activité — pharmacies comprises, qui resteraient alors seules responsables juridiquement de leurs propres ventes, la plateforme n'étant plus qu'un outil technique, à la façon dont Shopify ne vend rien lui-même.

**Avantage** : contourne une bonne partie du risque documenté dans `rgpd.md`, puisque le vendeur de record reste le commerçant client, pas la plateforme.
**Inconvénient** : marché plus diffus, pas de chiffre de marché unique trouvé pour cette recherche, modèle économique par abonnement B2B généralement moins scalable rapidement qu'un marketplace à commission — mais présente un profil de risque nettement plus bas, à considérer notamment si l'objectif est de rester sur le secteur pharmaceutique/santé sans porter seul le risque réglementaire.

---

## Tableau comparatif

| Piste | Réutilisation code | Risque réglementaire | Opportunité chiffrée | Concurrence connue |
|---|---|---|---|---|
| **BTP / matériaux de construction** | ~85% | Faible | 190,5 Md FCFA de prêts-projets 2025 (59% BTP/routes), secteur +61,8% au T4 2025 | Faible/non identifiée dans cette recherche |
| **Assurtech** | ~70% (module déjà en prod) | Faible à modéré (courtage réglementé par la CIMA, mais cadre stable) | Pénétration 1% du PIB vs ~2%+ dans la région, marché ~100 Md FCFA/an | Faible/non identifiée dans cette recherche |
| **Agroalimentaire / circuits courts** | ~75% | Faible | ~550 Md FCFA d'importations alimentaires/an, objectif gouvernemental 50% d'ici 2027 | Faible/non identifiée dans cette recherche |
| **Food delivery** | ~85% | Faible | Marché déjà prouvé dans la région | Élevée (ExpressGo à Libreville, Glovo/Yassir régionaux) |
| **SaaS marque blanche logistique** | ~90% (infrastructure) | Très faible | Pas de chiffre de marché unique trouvé | Variable, non quantifiée |

## Recommandation

**Premier choix : BTP/matériaux de construction.** C'est la piste qui combine le meilleur ratio opportunité chiffrée / risque réglementaire quasi nul / concurrence non identifiée / réutilisation technique la plus directe, sur un secteur en croissance documentée et porté par des financements publics déjà engagés en 2025.

**Deuxième choix, combinable en parallèle plutôt qu'en remplacement : l'assurtech**, parce qu'elle réutilise un module déjà construit et vérifié à un stade avancé, et répond à un vide de marché particulièrement net et bien documenté (pénétration à 1% du PIB). Un scénario réaliste serait même de lancer le marketplace BTP comme produit principal tout en gardant le module Assurance comme fonctionnalité satellite réutilisée pour un futur produit assurtech séparé — l'un ne ferme pas la porte à l'autre.

**À éviter en premier choix : food delivery**, malgré sa faible complexité technique de pivot, à cause d'une concurrence locale déjà installée qui réduit l'avantage du premier entrant.
