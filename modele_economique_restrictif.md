# Gab'Pharma — modèle économique redessiné sous contrainte réglementaire

**Créé le :** 26 août 2026
**But :** contrairement à `reorientations.md` (pivoter vers un autre secteur), ce document explore l'option de **rester dans la pharmacie** en redessinant le modèle économique pour éviter précisément les deux leviers identifiés comme risqués dans `rgpd.md` — la commission assise sur la vente de médicament, et le rôle d'opérateur de livraison de médicament. Il propose une vraie structure de revenus alternative, avec des repères chiffrés sourcés là où c'est possible.

**⚠️ Même avertissement que les deux documents précédents** : les chiffres ci-dessous combinent des données publiques sourcées (marché, tarifs comparables, démographie) et des **estimations illustratives explicitement signalées comme telles**, construites pour donner un ordre de grandeur défendable, pas un business plan validé par une étude terrain. Toute décision d'investissement doit s'appuyer sur une vérification locale (nombre réel d'officines partantes, prix accepté par le marché, etc.).

---

## 1. Diagnostic — ce qui, précisément, pose problème

`rgpd.md` §4 et §8.2 identifient deux leviers de risque distincts, pas "la vente de médicaments en ligne" en bloc :

1. **La commission assise sur le prix de vente du médicament** — c'est la formulation qui revient dans la clause déontologique gabonaise ("vente... par l'intermédiaire de sociétés de commission") : le risque n'est pas la plateforme en tant que telle, c'est le fait qu'elle **capte une part du prix de vente d'un médicament**, ce qui la fait ressembler juridiquement à un "agent démarcheur" rémunéré sur la transaction pharmaceutique elle-même.
2. **Le rôle d'opérateur de livraison de médicament** — c'est le point explicitement visé par l'Ordre National des Pharmaciens du Congo en 2020 ("vente en ligne, livraison à domicile"), sur l'argument que le médicament doit rester sous le contrôle direct du pharmacien jusqu'à sa remise, pas transiter par un tiers logistique commercial.

**Ce qui n'est PAS identifié comme un problème dans les recherches menées** : l'existence d'une app qui aide un patient à trouver une pharmacie, comparer des prix, ou gérer son dossier de santé/assurance. Le problème est concentré sur **qui touche de l'argent sur la vente du médicament, et qui le transporte** — pas sur la simple mise en relation ou l'information.

**Conséquence pour la conception du nouveau modèle** : il faut découpler la rémunération de la plateforme du prix de vente du médicament, et découpler le transport du médicament de l'identité juridique de la plateforme.

## 2. Principes de conception retenus

1. **Aucun revenu en pourcentage du prix d'un médicament.** Tout ce qui ressemble à "X% du panier" sur un article pharmaceutique est à bannir du modèle. Un forfait fixe (abonnement, frais de service plafonné, frais de logistique forfaitaire) est structurellement différent d'une commission proportionnelle et beaucoup plus défendable.
2. **La pharmacie reste vendeur de médicament et responsable de la remise — la plateforme ne l'est jamais.** Le paiement du médicament doit, autant que possible, aller directement du patient à la pharmacie (ou être clairement comptabilisé comme tel), la plateforme ne prélevant qu'un service séparé et identifiable.
3. **La livraison de médicament est sous-traitée ou confiée à un tiers coursier identifiable (potentiellement l'app Livreur déjà développée), facturée en forfait logistique, pas en pourcentage de la valeur du colis.**
4. **Pas de publicité payante sur des médicaments précis** — les revenus publicitaires, s'il y en a, se limitent à des catégories non réglementées (parapharmacie, hygiène, nutrition infantile, dispositifs médicaux sans ordonnance).
5. **Concentrer la monétisation sur ce qui n'est structurellement pas "vente de médicament par un tiers"** : logiciel vendu aux pharmacies, produits non-médicamenteux vendus en direct par la plateforme elle-même (donc pas par une pharmacie tierce), assurance, données agrégées.

## 3. Les flux de revenus proposés

### A. Abonnement SaaS aux pharmacies partenaires ("Gab'Pharma Pro")

**Ce que c'est** : la pharmacie paie un abonnement mensuel fixe pour apparaître dans le catalogue/la recherche géolocalisée de l'app patient, gérer son stock, recevoir et traiter les commandes, et accéder à des statistiques de base (produits les plus demandés dans sa zone, taux de conversion). C'est un logiciel de gestion vendu à la pharmacie — la plateforme ne touche jamais un centime indexé sur le prix d'un médicament vendu.

**Repère de prix comparable** : le marché du logiciel de gestion d'officine (LGO) existe déjà en Afrique francophone sans controverse identifiée — **AS PHARM (Phénix)** facture environ **12 500 FCFA/mois/session** tout compris ; au Maroc, les solutions comparables (Sobrus, Winpharm, Logipharm) se facturent 8 000 à 30 000 DH/an en abonnement. Gab'Pharma peut se positionner dans cette fourchette, voire au-dessus, puisqu'il n'apporte pas qu'un logiciel de caisse mais aussi une **génération de demande** (patients déjà sur l'app).

**Taille de marché** : le seul chiffre officiel trouvé sur le nombre de pharmaciens inscrits à l'Ordre National des Pharmaciens du Gabon date de 2021 — environ **254 pharmaciens inscrits** (dont 121 seulement à jour de cotisation). Ce n'est pas un compte d'officines à proprement parler (plusieurs pharmaciens peuvent exercer dans la même officine), mais c'est le meilleur ordre de grandeur trouvé — une estimation raisonnable du nombre d'officines physiques au Gabon se situe **entre 100 et 200** sur cette base, à confirmer.

**Estimation illustrative** :
| Scénario | Pharmacies abonnées | Prix mensuel | Revenu mensuel | Revenu annuel |
|---|---|---|---|---|
| Démarrage (an 1) | 30 (~20% du parc estimé) | 20 000 FCFA | 600 000 FCFA | 7,2 M FCFA |
| Croissance (an 2-3) | 80 | 20 000 FCFA | 1,6 M FCFA | 19,2 M FCFA |
| Maturité | 150 (quasi-couverture nationale) | 25 000 FCFA | 3,75 M FCFA | 45 M FCFA |

**Pourquoi c'est le flux le plus sûr** : c'est un modèle déjà opéré sans controverse identifiée par des acteurs comparables (AS PHARM, KiboERP, Meditect) sur le même marché géographique. Aucune clarification réglementaire préalable n'est nécessaire pour le lancer.

### B. Frais de logistique forfaitaires (pas une commission)

**Ce que c'est** : au lieu d'un pourcentage sur le panier, un **forfait de livraison fixe** par commande (déjà présent dans le code actuel via `delivery_fee_fcfa`, calculé côté serveur selon la zone — il suffit de s'assurer qu'il n'est jamais indexé sur le prix du médicament transporté). Le retrait en pharmacie reste gratuit, ce qui laisse toujours un chemin d'achat sans aucun flux financier passant par la plateforme.

**Sous-traitance recommandée** : confier le transport à un réseau de coursiers identifiables et responsables (l'app **gabpharma_livreur**, déjà en développement) plutôt que d'opérer soi-même une flotte au nom de la plateforme — cela renforce l'argument "nous sommes un outil de mise en relation et de dispatch, pas un opérateur de vente/livraison de médicament".

**Estimation illustrative** : 500 livraisons/mois en régime de croisière × 2 000 FCFA de forfait = 1 M FCFA/mois = **12 M FCFA/an**. Modeste seul, mais s'additionne aux autres flux et valorise l'infrastructure de tracking déjà construite (écran Suivi de livraison, timeline de statuts).

### C. Parapharmacie en vente directe (marque propre, hors circuit pharmacie tierce)

**Ce que c'est** : la plateforme vend elle-même, sous son propre enregistrement commercial (pas via les pharmacies partenaires), des produits **non médicamenteux** — cosmétiques, hygiène, nutrition infantile, dispositifs médicaux sans ordonnance, compléments alimentaires. Juridiquement, ce n'est plus une "vente de médicament par un tiers" du tout : c'est un e-commerce de produits de grande consommation comme un autre, hors du champ de la déontologie pharmaceutique.

**Taille de marché** : le marché cosmétique africain est évalué à 3,55 milliards USD en 2023, avec une projection à 4,95 milliards USD d'ici 2028 (TCAC 6,86%, source Mordor Intelligence). Le Cameroun, marché de référence en Afrique centrale francophone, pèse à lui seul environ 570 millions d'euros en 2023. Le marché gabonais, avec une population de 2,57 millions d'habitants dont 91,4% urbaine, est nécessairement beaucoup plus petit en valeur absolue, mais bénéficie d'un contexte favorable au e-commerce (71,9% de pénétration internet).

**Estimation illustrative** (pas de chiffre gabonais spécifique trouvé, calcul construit à partir d'hypothèses de panier) :
| Scénario | Commandes/mois | Panier moyen | Marge brute (25%) | Marge brute/an |
|---|---|---|---|---|
| Démarrage | 100 | 15 000 FCFA | 375 000 FCFA/mois | 4,5 M FCFA |
| Croissance | 400 | 15 000 FCFA | 1,5 M FCFA/mois | 18 M FCFA |

**Avantage stratégique additionnel** : ce canal peut réutiliser à l'identique le moteur de catalogue/panier/checkout déjà construit — il suffit d'ajouter un "vendeur" qui est la plateforme elle-même plutôt qu'une pharmacie tierce, un cas déjà proche du modèle multi-vendeurs existant.

### D. Assurtech — courtage/distribution d'assurance santé digitale

**Ce que c'est** : transformer le module "Mon Assurance" déjà construit (affiliation, taux de couverture, dérogations) en un vrai canal de souscription et de suivi de sinistre, avec une commission de courtage classique sur les primes — un métier réglementé mais stable, distinct de la vente de médicament (voir `reorientations.md` §2 pour le détail réglementaire CIMA).

**Rappel des chiffres déjà établis** : pénétration de l'assurance au Gabon ~1% du PIB (vs ~2%+ dans la région), marché total ~100 milliards FCFA de primes/an.

**Estimation illustrative** : 500 souscriptions/an à prime moyenne 150 000 FCFA/an, commission de courtage à 15% = **11,25 M FCFA/an**. Ce flux nécessite un agrément de courtage (démarche administrative, pas un blocage de principe) et un développement produit plus lourd que les flux A-C (souscription, gestion de sinistre).

### E. Données et analytics agrégées (flux différé, post-traction)

**Ce que c'est** : vendre aux laboratoires/distributeurs pharmaceutiques des tendances de demande **agrégées et anonymisées** par zone/catégorie (pas de données patient identifiables) — utile pour leur planification de stock et leur go-to-market. C'est un flux qui devient viable seulement une fois un volume de données significatif atteint (plusieurs dizaines de pharmacies actives, plusieurs mois d'historique).

**Point de conformité favorable** : ce flux est *plus* défendable que le modèle actuel du point de vue de l'APDPVP (`rgpd.md` §3-4), puisqu'il repose par construction sur des données agrégées/anonymisées, cohérent avec le principe de minimisation déjà documenté.

**Non chiffré ici** : pas de comparable trouvé pour ce marché précis au Gabon — à traiter comme une option à moyen terme, pas un pilier du modèle initial.

### F. Abonnement patient premium (optionnel, flux tardif)

Livraison illimitée à forfait mensuel, dossier familial partagé, rappels de traitement avancés. Flux d'ARPU secondaire, à envisager une fois une base d'utilisateurs actifs significative acquise via les flux A-D — non chiffré ici faute de donnée de rétention/usage réelle.

## 4. Qui délivre le médicament, légalement ?

**Recommandation centrale** : la plateforme ne doit **jamais** être elle-même l'opérateur de livraison de médicament en son nom propre. Trois options, par ordre de robustesse juridique décroissante :

1. **Retrait en pharmacie uniquement pour le médicament**, livraison à domicile réservée aux produits non-médicamenteux (flux C) — option la plus sûre, mais réduit l'attractivité du service.
2. **Livraison confiée à un réseau de coursiers indépendants identifiables** (l'app `gabpharma_livreur`), facturée en forfait fixe côté patient/pharmacie — le rôle de la plateforme se limite à la mise en relation et au suivi (dispatch, tracking), pas à l'exécution du transport en son nom.
3. **Livraison opérée par la pharmacie elle-même** (son propre livreur), la plateforme ne faisant que déclencher et suivre la course — cohérent avec l'argument de l'Ordre National des Pharmaciens congolais selon lequel le médicament doit rester sous contrôle direct du pharmacien jusqu'à sa remise.

Ces trois options sont compatibles entre elles et peuvent coexister (le patient choisit au checkout, exactement comme le mode de réception "Retrait"/"Livraison" existe déjà dans l'app).

## 5. Compte d'exploitation simplifié — synthèse

| Flux | An 1 (démarrage) | An 2-3 (croissance) | Statut réglementaire |
|---|---|---|---|
| A — SaaS pharmacies | 7,2 M FCFA | 19-45 M FCFA | Clean, comparables existants |
| B — Logistique forfaitaire | ~6 M FCFA (démarrage plus lent) | 12 M FCFA | Clean si forfait fixe, sous-traité |
| C — Parapharmacie directe | 4,5 M FCFA (marge brute) | 18 M FCFA (marge brute) | Clean, hors champ pharmaceutique |
| D — Assurtech | 0 (développement) | 11,25 M FCFA | Réglementé (CIMA) mais stable |
| E — Data agrégées | 0 | À déterminer | Clean, différé |
| **Total illustratif** | **~18 M FCFA** | **~60-85 M FCFA** | — |

**Lecture** : même sur des hypothèses volontairement prudentes, la combinaison des flux A+B+C seuls (les trois ne nécessitant aucune clarification réglementaire préalable) atteint un ordre de grandeur de 18-75 M FCFA/an selon le stade de croissance — un point de départ défendable pour un lancement en gardant la structure du produit actuel, sans attendre une clarification de l'Ordre des Pharmaciens sur le modèle à commission.

## 6. Séquencement de mise en œuvre recommandé

1. **0-3 mois — assainir le modèle actuel sans changement de code majeur** : documenter et facturer un abonnement SaaS explicite aux pharmacies déjà partenaires (flux A), s'assurer que tout frais de livraison existant (`delivery_fee_fcfa`) est bien un forfait et non un pourcentage, retirer toute trace de "commission sur vente" dans la communication commerciale du projet.
2. **3-6 mois — lancer le canal parapharmacie en direct** (flux C) : ne dépend d'aucune clarification réglementaire préalable, réutilise le moteur catalogue/panier/checkout existant à plus de 80%.
3. **6-12 mois — formaliser la livraison via le réseau `gabpharma_livreur`** (flux B), avec un forfait clairement affiché.
4. **12+ mois — développer le module assurance vers un vrai canal de souscription** (flux D), en parallèle d'une clarification de l'agrément de courtage nécessaire.
5. **Continu, en parallèle** — engager la démarche de clarification écrite avec l'Ordre National des Pharmaciens (recommandée dans `rgpd.md` §7) sur le statut exact du flux A (l'abonnement SaaS lui-même doit être confirmé comme non assimilable à une "société de commission" déguisée, notamment si son prix venait à varier selon le volume de ventes de la pharmacie plutôt que rester strictement forfaitaire).

## 7. Risques résiduels, même avec ce modèle redessiné

- **Un abonnement SaaS dont le prix est indexé, même indirectement, sur le volume de ventes de la pharmacie (paliers de commandes, etc.) pourrait être requalifié en commission déguisée.** Rester sur un prix strictement forfaitaire (ou au pire, par tranche de nombre de commandes servies, jamais par valeur de commande) est important pour la défendabilité du modèle.
- **Le canal parapharmacie en direct nécessite son propre enregistrement commercial et une chaîne d'approvisionnement/import distincte** — un chantier opérationnel non négligeable, pas seulement une bascule logicielle.
- **Ce redesign réduit le risque identifié dans `rgpd.md`, il ne l'élimine pas.** La démarche de clarification écrite avec l'Ordre National des Pharmaciens reste recommandée avant un lancement à grande échelle, en particulier pour le flux A une fois qu'il prend de l'ampleur.
