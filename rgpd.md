# Gab'Pharma Patient — cadre légal (Gabon et Congo-Brazzaville) pour le lancement du projet

**Créé le :** 25 août 2026
**But :** répondre à deux questions liées — (1) la loi gabonaise impose-t-elle ou bloque-t-elle un droit à la suppression définitive de compte, quelles instances sont concernées, et ce projet (plateforme mobile de commande de médicaments) risque-t-il d'être bloqué, par qui et pourquoi (`propositions_backend.md` §5) ; (2) la situation est-elle plus favorable en République du Congo (Congo-Brazzaville), envisagée comme alternative pour un lancement plus libre (section 8).

**⚠️ Avertissement, à lire avant tout le reste** : ce document est une synthèse documentaire construite à partir de recherches web (recherches + lecture de pages publiques), **pas un avis juridique**. Plusieurs textes officiels sources (PDF du Journal Officiel gabonais, PDF de l'AFAPDP) n'ont pas pu être extraits en texte lisible par l'outil utilisé pour cette recherche — les informations ci-dessous proviennent donc en bonne partie de synthèses tierces (cabinets de conformité, associations francophones des autorités de protection des données, presse gabonaise) plutôt que d'une lecture directe article par article du texte de loi. Là où un numéro d'article est cité, la source qui l'affirme est indiquée ; là où l'information est une synthèse non vérifiée au mot près, c'est signalé explicitement. **Avant toute décision engageante (lancement en production, refus d'implémenter une fonctionnalité), il est recommandé de faire confirmer ces points par un avocat gabonais ou de contacter directement l'APDPVP et l'Ordre National des Pharmaciens du Gabon.**

---

## Réponse directe

**Deux instances distinctes peuvent avoir leur mot à dire sur ce projet, pour deux raisons très différentes :**

1. **L'APDPVP** (ex-CNPDCP, régulateur de la protection des données personnelles) — pour tout ce qui touche à la collecte, au traitement et à la conservation des données personnelles des patients (y compris les données de santé implicites : médicaments commandés, affiliation d'assurance, historique de commandes). C'est l'instance pertinente pour la question initiale (suppression de compte).
2. **L'Ordre National des Pharmaciens du Gabon** (et dans une moindre mesure l'**ANMAPS**, agence du médicament sous tutelle du Ministère de la Santé) — pour tout ce qui touche à la **vente et à la distribution de médicaments elle-même**. C'est un risque distinct, potentiellement plus structurant, qui concerne le modèle économique de l'app (marketplace multi-pharmacies avec livraison), pas seulement la fonctionnalité de suppression de compte. Voir section 4.

**Sur la suppression de compte précisément** : la loi gabonaise **n'impose pas** un droit à l'effacement inconditionnel façon RGPD (article 17). Le droit prévu (article 14 de la loi n°001/2011, selon plusieurs sources concordantes) est un **droit de rectification et de suppression conditionné** : la personne peut demander la suppression de ses données si elles sont *inexactes, incomplètes, équivoques, périmées, ou si leur collecte/utilisation/communication/conservation est interdite* — pas "sur simple demande, sans motif", comme le permet le RGPD. Couplé au principe de conservation limitée à la durée nécessaire (voir section 3), le cadre gabonais est **plutôt cohérent avec l'approche déjà envisagée par l'équipe** (anonymisation différée pour préserver l'intégrité comptable des commandes/paiements, plutôt qu'une suppression SQL immédiate) qu'avec un blocage strict de cette approche.

---

## 1. Le texte de référence

- **Loi n° 001/2011 du 25 septembre 2011** relative à la protection des données à caractère personnel — texte fondateur.
- **Loi n° 025/2023 du 12 juillet 2023** portant modification de la loi n° 001/2011 — réforme qui renomme l'autorité et renforce ses pouvoirs.
- L'autorité de contrôle, initialement la **CNPDCP** (Commission Nationale pour la Protection des Données à Caractère Personnel), est devenue en 2023 l'**APDPVP** (Autorité pour la Protection des Données à Caractère Personnel et de la Vie Privée), avec des représentations provinciales sur tout le territoire.
- Champ d'application : la loi couvre la collecte, le traitement et la conservation de données personnelles par des entités publiques et privées, par des moyens automatisés ou non, et s'applique aux traitements réalisés "sur le territoire gabonais ou en tout lieu où s'applique la loi gabonaise" — l'app cible des patients au Gabon, donc le champ d'application n'est pas contestable même si le backend est un jour hébergé à l'étranger.

## 2. Droits des personnes concernées

Selon une synthèse concordante de plusieurs sources tierces (association CaseGuard, plateforme de conformité Clym) :

- Droit à l'information (savoir qui collecte les données et pourquoi).
- Droit d'accès.
- Droit de rectification.
- **Droit de suppression conditionné** (article 14, section III "Du droit de rectification et de suppression", selon une synthèse citée par plusieurs sources) : la personne peut exiger que ses données soient *rectifiées, complétées, mises à jour, verrouillées ou supprimées* si elles sont inexactes, incomplètes, équivoques, périmées, ou si leur collecte/utilisation/communication/conservation est interdite. Le responsable de traitement doit répondre par écrit, gratuitement, dans un délai d'un mois.
- Droit d'opposition pour motif légitime.
- Droit à la portabilité (format lisible et ouvert).
- Droit de ne pas faire l'objet d'une décision entièrement automatisée ayant des conséquences défavorables.

**Point clé pour la décision produit** : ce n'est pas un droit "à l'oubli" inconditionnel. Rien n'empêche l'app d'offrir une suppression volontaire plus généreuse que le minimum légal (ce que la désactivation réversible actuelle prépare déjà), mais rien dans la loi n'oblige non plus à une suppression SQL brute immédiate qui casserait l'intégrité des commandes déjà passées — l'anonymisation est une réponse légitime au droit de suppression tel que formulé.

## 3. Principes imposés au responsable de traitement

Quatre principes reviennent de façon constante dans les synthèses consultées :

- **Transparence** : informer les personnes concernées.
- **Confidentialité** : limiter l'accès au personnel habilité.
- **Sécurité** : protéger contre la perte, l'altération, l'accès non autorisé.
- **Conservation limitée** : ne garder les données que le temps nécessaire à la finalité du traitement.

Ce dernier principe est directement pertinent : il justifie qu'un compte inactif/désactivé ne reste pas indéfiniment avec des données identifiantes en clair, mais n'impose pas de délai précis trouvé dans les sources consultées pour cette recherche — un délai de conservation raisonnable (ex. anonymisation après N mois d'inactivité post-désactivation) serait défendable, à confirmer avec l'APDPVP si le volume d'utilisateurs devient significatif.

## 4. Traitement des données sensibles (santé, biométrie)

Les sources consultées confirment que la loi gabonaise connaît une catégorie de **données sensibles** (opinions religieuses/philosophiques, opinions politiques, et catégories similaires — la formulation exacte trouvée ne mentionne pas nommément "santé" dans les extraits obtenus, mais la pratique documentée par des cabinets de conformité tiers indique que les données de santé et biométriques sont couvertes par ce régime renforcé). Une source tierce (Clym, plateforme de conformité) mentionne explicitement que la loi n° 025/2023 couvre les catégories **biométriques, de santé et financières**, avec une obligation d'**analyse d'impact** pour les traitements à haut risque (profilage, décision automatisée).

**Ce que l'app manipule aujourd'hui qui pourrait relever de ce régime** : le champ `requires_prescription` sur les médicaments, l'historique de commandes (révèle indirectement des informations de santé), et l'affiliation d'assurance santé (`Affiliation`/`Plan`). Rien dans les sources consultées ne permet de confirmer avec certitude si une **autorisation préalable** de l'APDPVP (régime renforcé, plus lourd qu'une simple déclaration) est requise avant de démarrer ce type de traitement, par opposition à une déclaration simple — les sources tierces évoquent une "notification préalable à la CNPDCP" pour les traitements en général, mais je n'ai pas pu confirmer le régime exact (déclaration vs autorisation) pour la catégorie santé spécifiquement à partir d'une source primaire lisible. **Point à vérifier directement auprès de l'APDPVP avant un lancement en production à grande échelle** — la démarche de déclaration/autorisation, si elle n'a pas déjà été faite pour ce projet, est probablement le point de conformité le plus urgent et le plus facile à corriger (démarche administrative, pas un changement de code).

## 5. Pouvoirs de sanction de l'APDPVP — "ce projet peut-il être bloqué ?"

Oui, concrètement, selon plusieurs sources concordantes (CaseGuard, Clym) l'autorité dispose d'une échelle de sanctions qui va jusqu'au blocage :

1. Avertissement public.
2. Mise en demeure formelle.
3. **Suspension de l'activité de traitement** — jusqu'à deux mois, pouvant devenir permanente en cas de non-conformité persistante (selon CaseGuard).
4. Amendes administratives : de 1 million à 100 millions de FCFA (~1 650 à 165 000 USD), avec des montants plus élevés en cas de récidive (une source évoque 100 à 300 millions FCFA pour la récidive).
5. Selon une source (Clym), des **peines pénales, y compris de l'emprisonnement**, sont prévues pour les responsables en cas de violation grave — non recoupé avec une deuxième source indépendante dans cette recherche, à vérifier.

**En clair** : l'APDPVP a un pouvoir réel de suspendre — donc de facto bloquer — le traitement de données d'une app non conforme, pas seulement d'infliger une amende. C'est l'instance qui peut bloquer ce projet *sur le terrain des données personnelles*.

## 6. Le risque distinct, et probablement plus structurant : la réglementation pharmaceutique

C'est le point le plus important trouvé dans cette recherche, **au-delà de la question initiale sur la suppression de compte** : la vente de médicaments elle-même est un domaine réglementé séparément, par des instances différentes de l'APDPVP, et ce risque touche potentiellement le **modèle économique central de l'app** (agréger plusieurs pharmacies, faciliter la commande et la livraison) — pas seulement une fonctionnalité de profil.

- **L'Ordre National des Pharmaciens du Gabon**, créé par la loi n° 012/2006 du 9 novembre 2006, encadre l'exercice de la profession. Le **Code de déontologie pharmaceutique gabonais** contient une règle citée par plusieurs sources : *"La vente au public de médicaments est interdite par l'intermédiaire de sociétés de commission ou autres agents démarcheurs ou vendeurs ambulants."* Je n'ai pas pu extraire le numéro d'article exact (le PDF source n'était pas exploitable par l'outil de recherche), mais la formulation revient de façon cohérente dans les sources consultées. **Cette clause vise typiquement les intermédiaires commerciaux qui vendent des médicaments pour le compte de pharmacies contre rémunération** — une lecture stricte pourrait viser une marketplace qui prendrait une commission sur les ventes des pharmacies partenaires, selon la manière exacte dont le modèle économique de Gab'Pharma est structuré (commission sur transaction vs. simple frais d'abonnement/SaaS payé par les pharmacies, par exemple, ne seraient pas nécessairement logés à la même enseigne).
- **L'exercice de toute activité liée au médicament est subordonné à une autorisation professionnelle préalable**, délivrée conformément aux textes en vigueur — cela concerne d'abord les pharmacies elles-mêmes (déjà logiquement dans le champ d'application, puisque ce sont des officines réelles), mais pourrait aussi concerner la plateforme d'intermédiation selon son statut juridique.
- **L'ANMAPS** (Agence Nationale du Médicament et des Autres Produits de Santé, créée par ordonnance n°0004 du 24 octobre 2023, ratifiée par la loi n°006/2023 du 26 janvier 2024, sous tutelle du Ministère de la Santé) régule la production, l'importation, la mise sur le marché, l'usage et la destruction des médicaments et produits de santé. Aucune source consultée ne mentionne de régime spécifique pour les applications mobiles ou la vente en ligne de médicaments au Gabon — ce vide juridique apparent n'est **pas rassurant en soi** : il peut vouloir dire "pas encore réglementé donc pas encore interdit", mais aussi "à la discrétion de l'autorité au cas par cas" tant qu'un texte ne clarifie pas la position.

**Ce que cela signifie concrètement** : avant même la question de la suppression de compte, il serait prudent de faire confirmer à l'Ordre National des Pharmaciens du Gabon que le modèle économique retenu pour Gab'Pharma (méthode de rémunération de la plateforme vis-à-vis des pharmacies partenaires, rôle exact de l'app dans la transaction) ne tombe pas sous le coup de l'interdiction déontologique citée ci-dessus. C'est un risque de blocage potentiellement plus sérieux que la conformité RGPD-like, parce qu'il peut remettre en cause le principe même de la marketplace plutôt qu'une fonctionnalité isolée.

## 7. Recommandations concrètes

1. **Suppression de compte** : le cadre légal ne bloque pas l'approche déjà actée par l'équipe (désactivation réversible déjà en production ; anonymisation différée plutôt que suppression SQL immédiate pour les comptes ayant un historique de commandes/paiements). Rien ne presse techniquement — mais si une vraie fonctionnalité de suppression/anonymisation est construite plus tard, s'appuyer sur le principe de conservation limitée (section 3) plutôt que sur un faux "droit à l'oubli à la RGPD" pour calibrer le délai.
2. **Déclaration/autorisation à l'APDPVP** : vérifier si une démarche a déjà été faite pour ce traitement (données patients + données de santé implicites). Si non, c'est probablement le point le plus urgent de ce document — démarche administrative, pas un chantier de développement.
3. **Modèle économique vis-à-vis de l'Ordre des Pharmaciens** : faire confirmer, idéalement par écrit, que la structure de rémunération de la plateforme (commission ? abonnement ? frais fixes ?) ne relève pas de l'interdiction de vente "par sociétés de commission" du code de déontologie pharmaceutique. C'est indépendant du sujet suppression de compte mais découvert pendant cette recherche et jugé suffisamment important pour être signalé.
4. **Ne pas traiter ce document comme final** : plusieurs PDF sources n'étaient pas exploitables par l'outil de recherche utilisé. Avant toute décision structurante, faire vérifier ces points par un professionnel du droit gabonais ou directement auprès de l'APDPVP (`https://www.apdpvp.ga`) et de l'Ordre National des Pharmaciens du Gabon.

## 8. Comparaison avec la République du Congo (Congo-Brazzaville)

**Réponse courte : non, le Congo-Brazzaville n'est probablement pas un terrain plus libre — sur le volet pharmaceutique, les signaux trouvés sont plutôt plus défavorables qu'au Gabon.** Sur le volet données personnelles, le cadre est très jeune et moins testé, ce qui est une inconnue plutôt qu'une garantie de liberté.

### 8.1 Protection des données personnelles

- **Loi n° 29-2019 du 10 octobre 2019** relative à la protection des données à caractère personnel — texte de base.
- **Loi n° 5-2025 du 29 mars 2025** portant création de la **Commission Nationale pour la Protection des Données à caractère personnel (CNPD)**, basée à Brazzaville — c'est-à-dire que **l'autorité de contrôle elle-même n'a été formellement instituée qu'en mars 2025**, plus de cinq ans après la loi. Autrement dit, le cadre existe sur le papier depuis 2019 mais son organe d'application est très récent — pas d'historique de délibérations ou de jurisprudence administrative comparable à celui de l'APDPVP gabonaise trouvé dans cette recherche.
- Pouvoirs de la CNPD, selon les sources consultées : garantir la protection des données, sensibiliser sur les droits/obligations, recevoir et traiter les plaintes, **autoriser et contrôler les traitements de données**, et sanctionner les violations. La formulation ("autoriser... les traitements") suggère un régime d'autorisation préalable, potentiellement plus lourd que le régime gabonais pour certains traitements — à vérifier au cas par cas, les sources consultées ne détaillent pas les montants d'amendes ni les catégories de données sensibles avec la même précision que pour le Gabon.
- **Lecture pour la décision** : un cadre plus jeune n'est ni plus souple ni plus strict par nature — c'est surtout plus **imprévisible**, avec un organe de contrôle qui vient tout juste de se mettre en place et qui pourrait chercher à asseoir sa légitimité par des actions exemplaires, ou au contraire manquer encore de moyens opérationnels pour agir rapidement. Aucun signal trouvé dans un sens ou dans l'autre pour l'instant.

### 8.2 Réglementation pharmaceutique — le signal le plus clair de cette recherche

C'est ici que la piste "Congo plus libre" se heurte à un signal concret et daté : **l'Ordre National des Pharmaciens du Congo s'est publiquement opposé à la vente en ligne de médicaments, à la livraison à domicile et à la publicité en ligne pour les médicaments**, les qualifiant de contraires au code de déontologie de la profession pharmaceutique — les pharmacies étant des "établissements de santé réglementés, pas des supermarchés", exposant la population à des dangers si ces pratiques se généralisent (source : Les Dépêches de Brazzaville, relayé par santetropicale.com, 2 novembre 2020). C'est une prise de position **plus explicite et plus directement ciblée sur le modèle Gab'Pharma** (vente en ligne + livraison à domicile) que ce qui a été trouvé pour le Gabon (où la clause déontologique trouvée visait plutôt les intermédiaires commerciaux/agents démarcheurs, une formulation plus ancienne et moins univoque).

**Nuance importante, à ne pas ignorer** : cette prise de position date de 2020, aucune action de fermeture ou de sanction concrète contre une app précise n'a été trouvée dans cette recherche pour la confirmer dans la durée, et dans la pratique, au moins une application de ce type semble avoir opéré au Congo sans blocage rapporté : **Lisungui Pharma**, une app mobile (géolocalisation de pharmacies, prix des médicaments, rappels de traitement, et — point clé — **commande à distance avec livraison**) qui affichait une présence dans 5 pays dont le Congo dès 2018, sans mention d'autorisation officielle de l'Ordre trouvée dans les sources consultées. Ce n'est pas une preuve que le modèle est toléré en pratique aujourd'hui (la source date de 2018, avant la prise de position de 2020 de l'Ordre, et aucune actualité récente 2023-2025 n'a été trouvée sur le statut de cette app ni sur une éventuelle sanction) — mais ça montre au minimum que la position de l'Ordre n'a pas empêché ce type de service d'exister à un moment donné.

### 8.3 Conclusion pratique

| | Gabon | Congo-Brazzaville |
|---|---|---|
| Protection des données | Cadre mature (loi 2011, réforme 2023), autorité active avec historique de délibérations publiques | Cadre récent, autorité (CNPD) créée en mars 2025 seulement — peu d'historique |
| Position du régulateur pharmaceutique sur le modèle marketplace/livraison | Clause déontologique trouvée mais formulation ancienne et plus ambiguë (vise les "sociétés de commission") | Position explicite et directement ciblée (vente en ligne + livraison = contraire à la déontologie), mais datée de 2020, sans confirmation d'une application stricte dans la durée |
| **Verdict de cette recherche** | Risque identifié, gérable via clarification écrite avec l'Ordre | Risque identifié et **plus explicitement formulé** contre le modèle — ne pas présumer que ce serait plus simple |

**Aucun des deux pays n'est identifiable, à partir de cette recherche, comme un terrain manifestement "plus libre" pour ce modèle économique précis.** Si l'objectif est de sécuriser juridiquement le lancement, la meilleure piste trouvée dans cette recherche n'est pas de chercher une juridiction plus permissive par défaut, mais de **clarifier le modèle économique par écrit avec l'ordre professionnel concerné avant le lancement**, dans le pays retenu — la clause qui revient dans les deux pays (vente par intermédiaire commercial / vente en ligne+livraison) semble viser spécifiquement les plateformes qui *prennent une commission sur la vente elle-même* ou qui *remplacent la relation directe pharmacien-patient* ; un modèle où la plateforme facture un abonnement/SaaS aux pharmacies (plutôt qu'une commission par vente) et où le pharmacien reste le seul à valider/exécuter la vente pourrait être une piste de conformité à explorer dans les deux juridictions, à confirmer avec un professionnel du droit local.

## Sources consultées

- [CNPDCP transformée en Autorité pour la protection des données à caractère personnel et de la vie privée — Gabonmediatime](https://gabonmediatime.com/gabon-cnpdcp-transformee-autorite-pour-protection-des-donnees-caractere-personnel-vie-privee/)
- [Loi relative à la protection des données à caractères personnelles au Gabon — CNPDCP](https://www.cnpdcp.ga/works/loi-relative-a-la-protection-des-donnees-a-caracteres-personnelles-au-gabon/)
- [NATLEX — Loi n° 001/2011 du 25 septembre 2011](https://natlex.ilo.org/dyn/natlex2/r/natlex/fe/details?p3_isn=106657)
- [AFAPDP — Loi n° 025/2023 du 12 juillet 2023 portant modification de la loi n° 001/2011](https://www.afapdp.org/archives/download-view/gabon-loi-025-2023-du-12-juillet-2023-portant-modification-de-la-loi-001-2011-du-25-septembre-relative-a-la-protection-des-donnees-a-caractere-personnel)
- [Data Protection Regulations in the Nation of Gabon — CaseGuard](https://caseguard.com/articles/promoting-data-privacy-and-protection-in-gabon/)
- [Law No. 025/2023 Gabon — Clym (plateforme de conformité)](https://www.clym.io/regulations/law-no-0252023-gabon)
- [dataprotection.africa — Factsheet Gabon (2019)](https://dataprotection.africa/wp-content/uploads/2019/10/Gabon-Factsheet.pdf)
- [Élections 2025 : les partis politiques sous surveillance de l'APDPVP — Gabonreview](https://www.gabonreview.com/elections-2025-les-partis-politiques-sous-surveillance-de-lapdpvp-pour-la-gestion-des-donnees-personnelles/)
- [Code de déontologie pharmaceutique du Gabon — CIOPF](https://www.ciopf.org/content/download/1250/file/Gabon%20-%20Code%20de%20d%C3%A9ontologie%20pharmaceutique.pdf)
- [Règlementation pharmaceutique au Gabon — LEEM Afrique](https://www.leemafrique.org/fr/reglementation-pharmaceutique-au-gabon.asp)
- [ANMAPS — Site officiel](http://www.anmaps.ga/)
- [Les pharmaciens interdisent la vente des médicaments en ligne (Congo) — Les Dépêches de Brazzaville via santetropicale.com, 2 nov. 2020](https://www.santetropicale.com/actus.asp?action=lire&id=28596)
- [Application mobile « Lisungui Pharma » : une pharmacie mobile à portée de main — Adiac-Congo](https://www.adiac-congo.com/content/application-mobile-lisungui-pharma-une-pharmacie-mobile-portee-de-main-82296)
- [République du Congo — Loi de protection des données — Africa Data Protection](https://www.africadataprotection.org/pays/republique-du-congo.html)
- [Loi n° 5-2025 du 29 mars 2025 portant création de la CNPD — Ministère des Postes, des Télécommunications et de l'Économie Numérique du Congo](https://postetelecom.gouv.cg/loi-n-5-2025-du-29-mars-2025-portant-creation-de-la-commission-nationale-pour-la-protection-des-donnees-a-caractere-personnel/)
- [Loi n° 29-2019 du 10 octobre 2019 — Journal Officiel de la République du Congo](https://www.sgg.cg/JO/2019/congo-jo-2019-45.pdf)
