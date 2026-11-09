# 📖 Le glossaire

Tous les mots du projet, expliqués comme on les expliquerait à quelqu'un qui démarre.
Chaque définition tient en trois lignes et donne l'exemple pris dans ShopShop.

- [Les mots du SQL](#les-mots-du-sql)
- [Les mots de la modélisation](#les-mots-de-la-modélisation)
- [Les mots de Power BI](#les-mots-de-power-bi)
- [Les mots du métier](#les-mots-du-métier)

---

## Les mots du SQL

### Anti-jointure
La technique pour trouver **ce qui n'a pas de correspondance** : un `LEFT JOIN` suivi
d'un `WHERE ... IS NULL`.
*Dans le projet :* elle répond à « quels produits n'ont jamais été vendus ? » (2) et
« quels clients n'ont jamais acheté ? » (14).

### `COALESCE(x, 0)`
« Prends `x` ; si `x` est `NULL`, prends `0` à la place. »
*Dans le projet :* sans lui, les 32 lignes à remise `NULL` disparaissent du total et
vous perdez 1 984,50 USD.

### CTE (le bloc `WITH … AS`)
Un résultat intermédiaire qu'on nomme pour pouvoir le réutiliser dans la suite de la
requête, comme une table temporaire qui n'existe que le temps de l'exécution. Ça évite
d'empiler des sous-requêtes illisibles.
*Dans le projet :* la requête A1b calcule d'abord le vrai total de chaque commande,
puis le compare au montant de la caisse.

### Clé primaire / clé étrangère
La **clé primaire** identifie une ligne de façon unique (`id_client`). La **clé
étrangère** est une colonne qui pointe vers la clé primaire d'une autre table
(`commandes.id_client` pointe vers `clients.id_client`). C'est ce qui permet de relier
les tables.

### `DISTINCT`
« Ne me montre chaque valeur qu'une seule fois. »
*Dans le projet :* `COUNT(DISTINCT ville)` répond « combien d'orthographes différentes
pour les villes ? » → 18 avant nettoyage, 7 après.

### `GROUP BY`
« Regroupe les lignes qui ont la même valeur, et calcule un total par groupe. »
*Dans le projet :* `GROUP BY nom_categorie` transforme 1 289 lignes de vente en
5 lignes de chiffre d'affaires.

### `JOIN` / `INNER JOIN`
Relie deux tables et **ne garde que** les lignes qui ont une correspondance des deux
côtés.
⚠️ Il fait disparaître silencieusement ce qui n'a pas de correspondance. C'est pratique
et c'est dangereux.

### `LEFT JOIN`
Relie deux tables et **garde toutes les lignes de celle de gauche**, même quand il n'y
a rien en face. Les colonnes manquantes sont remplies avec `NULL`.
*Dans le projet :* c'est lui qui fait réapparaître les 2 produits jamais vendus.

### `NULL`
Ce n'est **pas** zéro. Ce n'est **pas** une case vide. C'est « on ne sait pas ».
Deux conséquences à connaître par cœur :
- tout calcul avec un `NULL` donne `NULL` (`150 − NULL = NULL`) ;
- `SUM()` ignore silencieusement les `NULL` : votre total est trop petit et rien ne
  vous prévient.

### `TRIM` et `INITCAP`
`TRIM('  Kinshasa ')` → `'Kinshasa'` : enlève les espaces au début et à la fin.
`INITCAP('KINSHASA')` → `'Kinshasa'` : une majuscule par mot, le reste en minuscules.
Enchaînés, ils transforment 18 orthographes en 7 villes.

### Vue (`CREATE VIEW`)
Une requête enregistrée sous un nom. On l'interroge comme une table, mais elle ne
stocke rien : elle rejoue sa requête à chaque appel, donc elle est toujours à jour.
*Dans le projet :* vos 5 vues `v_…` sont ce que Power BI va lire.

---

## Les mots de la modélisation

### Additif
Une valeur est additive si l'additionner a un sens à tous les niveaux.
`ca_ligne` est additif : la somme des lignes d'une catégorie donne le CA de la
catégorie. ✅
Un **taux** n'est pas additif : la somme (ou la moyenne) de deux pourcentages ne veut
rien dire. ❌
**C'est cette distinction qui décide ce qu'on calcule en SQL et ce qu'on calcule en DAX.**

### Couche de présentation (ou couche sémantique)
Un jeu de vues écrites **uniquement pour être lues par l'outil de BI** : déjà propres,
au grain le plus fin, en forme d'étoile.
*Dans le projet :* vos 5 vues `v_dim_…` et `v_fait_…`. C'est votre livrable n° 2.

### Dimension
Une table qui décrit **le contexte** : qui, quoi, où, quand. Elle sert à filtrer et à
regrouper, pas à additionner.
*Dans le projet :* `v_dim_client`, `v_dim_produit`, `v_dim_calendrier`.

### Fait (table de faits)
Une table qui décrit **ce qui s'est passé** : une vente, une commande. Elle grossit
quand l'entreprise travaille, et c'est là qu'on additionne.
*Dans le projet :* `v_fait_commandes` (648 lignes) et `v_fait_ventes` (1 289 lignes).

> **Le test en une question :** est-ce que cette table grossit quand l'entreprise
> travaille ? Oui → un fait. Non → une dimension.

### Flocon (schéma en flocon)
Quand une dimension pointe vers une autre dimension : `categories → produits → ventes`.
Ça marche, mais ça ajoute une relation à gérer. On préfère **aplatir** la petite table
dans la grande pour obtenir une étoile.

### Grain
**Une ligne de cette table, c'est quoi ?**
`v_fait_commandes` : une commande. `v_fait_ventes` : un produit dans un panier.
Si vous ne savez pas répondre à cette question sur une table, vous ne pouvez rien
calculer de juste avec.

### Modèle en étoile
La forme standard d'un modèle de BI : les tables de faits au centre, les dimensions
autour, et les filtres qui descendent **des dimensions vers les faits**. C'est la forme
que Power BI est optimisé pour traiter, et celle qui s'explique en trente secondes à
un collègue.

### Source unique de vérité
L'endroit — un seul — où une définition est écrite, et que tout le monde interroge.
*Dans le projet :* c'est le point de départ de toute l'histoire. Deux chiffres de CA
ont circulé en réunion parce qu'il n'y en avait pas.

### Table de dates (dimension temps)
Une table qui contient **tous** les jours de la période, même ceux où il ne s'est rien
passé. Sans elle, un mois sans vente n'apparaît pas sur votre courbe, et les fonctions
de comparaison annuelle ne fonctionnent pas.
*Dans le projet :* `v_dim_calendrier`, 730 jours, fournie toute faite.

---

## Les mots de Power BI

### CALCULATE
La fonction DAX la plus importante : « fais ce calcul, **mais** en appliquant d'abord
ce filtre ».
*Dans le projet :* `CALCULATE(SUM(ca_ligne), statut = "livrée")` additionne le CA, mais
uniquement sur les commandes livrées.

### Cardinalité
Le type d'une relation. Celle qu'on veut partout ici : **un vers plusieurs (1:\*)** —
un client a plusieurs commandes, une commande a plusieurs lignes.
Si Power BI vous propose « plusieurs à plusieurs », c'est qu'il y a un doublon dans
votre dimension : il faut aller voir.

### Colonne calculée
Une colonne ajoutée au modèle, calculée **une fois** ligne par ligne, puis stockée.
Elle ne réagit pas aux filtres de l'écran. Dans le doute, préférez une **mesure**.

### DAX
Le langage de calcul de Power BI. Il ressemble aux formules d'Excel, mais il travaille
sur des tables entières au lieu de cellules.

### DirectQuery / Importer
Deux façons de connecter Power BI à une base. **Importer** copie les données dans le
fichier `.pbix` : c'est rapide et c'est ce qu'on utilise ici. **DirectQuery** interroge
la base à chaque clic : utile sur de très gros volumes, plus lent au quotidien.

### DIVIDE
La division de DAX. `DIVIDE(a, b)` renvoie un blanc si `b` vaut 0, au lieu d'afficher
une erreur. Utilisez-la systématiquement à la place de `/`.

### Mesure
Un calcul recalculé **à chaque fois que vous cliquez**, en fonction de ce qui est
filtré à l'écran. `[CA livré]` vaut 89 012,69 en global, et autre chose quand on filtre
sur Kinshasa.
*Règle de pouce :* dans le doute, une mesure.

### Power Query
L'éditeur dans lequel on transforme les données **avant** qu'elles entrent dans le
modèle (renommer, retyper, nettoyer).
*Dans ce projet, vous y passerez trois minutes* : le nettoyage a déjà été fait en SQL.
C'est le bénéfice de la couche de présentation.

### SAMEPERIODLASTYEAR
La fonction DAX qui décale la période affichée d'un an en arrière, pour comparer. Elle
exige une table de dates marquée comme telle, en années civiles complètes.

### Segment (slicer)
Le visuel qui sert à filtrer la page : une liste, une case à cocher, un curseur de
dates.

### Sens du filtre
La direction dans laquelle un filtre se propage entre deux tables. Dans un modèle en
étoile, c'est toujours **de la dimension vers le fait**, et dans un seul sens. Le
bidirectionnel existe, mais il crée des ambiguïtés : on l'évite tant qu'on n'est pas
sûr de soi.

### Trier par colonne
Le réglage qui dit à Power BI : « affiche `mois_annee`, mais classe-le d'après
`mois_tri` ». Sans lui, vos mois sont triés par ordre alphabétique et votre année
commence en août.

---

## Les mots du métier

### Canal (de vente)
Par où passe la vente. Ici : Boutique, En ligne, Mobile Money.

### Chiffre d'affaires (CA)
Ce que l'entreprise encaisse. Ici : `quantité × prix de vente − remise`, sur les
commandes livrées uniquement. **89 012,69 USD.**

### Coût d'achat
Ce que ShopShop a payé au fournisseur. La remise accordée au client ne le change pas
(règle R4) : le fournisseur, lui, est payé pareil.

### Marge brute
`chiffre d'affaires − coût d'achat`. **29 722,69 USD.** C'est ce qui reste avant les
salaires, le loyer et l'électricité.

### Panier moyen
`CA ÷ nombre de commandes`. Attention au dénominateur : 554 commandes livrées, ou
552 qui contiennent vraiment quelque chose ? Les deux se défendent — ce qui ne se
défend pas, c'est de ne pas choisir. (Ici : **161,25 USD** sur 552.)

### Récence
Le nombre de jours depuis le dernier achat d'un client. Calculée par rapport au
**31 octobre 2026** (la dernière date de la base), jamais par rapport à aujourd'hui.

### Règle de gestion
Une décision de l'entreprise sur la façon de calculer quelque chose. Ce n'est ni du
code ni une vérité mathématique : c'est un **accord**, qu'on écrit pour que tout le
monde calcule pareil.
*Dans le projet :* les 5 règles R1 à R5 du brief.

### RFM
Une façon classique de segmenter les clients sur trois critères : **R**écence (quand
ont-ils acheté pour la dernière fois ?), **F**réquence (combien de fois ?),
**M**ontant (combien ont-ils dépensé ?). En bonus dans ce projet.

### Taux d'annulation
`commandes annulées ÷ toutes les commandes`, tous statuts confondus au dénominateur.
**10,96 %** chez ShopShop.

### Taux de marge
`marge ÷ chiffre d'affaires`. **33,39 %** ici.
⚠️ Jamais une moyenne de pourcentages : on additionne les montants, **puis** on divise.

---

*Projet BI ShopShop · Formation Data Analyst*
