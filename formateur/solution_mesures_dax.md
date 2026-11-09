# 📕 Corrigé — les mesures DAX

> Document formateur. À ne pas distribuer avant la correction.
> Les étudiants ont le même contenu, mais sans les valeurs de contrôle complètes et
> sans les commentaires de correction.

---

## Le modèle attendu

```
      v_dim_calendrier                v_dim_client
             │ 1                           │ 1
             └──────────────┬──────────────┘
                            ▼  *
                    v_fait_commandes            648 lignes
                            │ 1
                            ▼  *
                     v_fait_ventes              1 289 lignes
                            ▲  *
                            │ 1
                     v_dim_produit
```

| # | De | Vers | Cardinalité | Filtre |
|---|---|---|---|---|
| 1 | `v_dim_calendrier[date_jour]` | `v_fait_commandes[date_commande]` | 1:* | simple |
| 2 | `v_dim_client[id_client]` | `v_fait_commandes[id_client]` | 1:* | simple |
| 3 | `v_fait_commandes[id_commande]` | `v_fait_ventes[id_commande]` | 1:* | simple |
| 4 | `v_dim_produit[id_produit]` | `v_fait_ventes[id_produit]` | 1:* | simple |

**Les 3 réglages à vérifier à la correction :**
1. `v_dim_calendrier` marquée comme table de dates (sinon `SAMEPERIODLASTYEAR`
   renvoie du vide) ;
2. `mois_annee` trié par `mois_tri` (sinon l'axe est en ordre alphabétique) ;
3. les colonnes `id_…` masquées dans la vue Rapport.

> **Point d'architecture à faire verbaliser.** `v_fait_commandes` joue deux rôles :
> table de faits (on y compte les commandes) **et** pont entre les dimensions et les
> ventes. C'est assumé, c'est la conséquence directe des deux grains. L'étudiant qui
> sait l'expliquer a compris le projet.

---

## Les 13 mesures

Toutes rangées dans `v_fait_ventes`.

### Argent

```dax
CA livré =
CALCULATE ( SUM ( v_fait_ventes[ca_ligne] ), v_fait_commandes[statut] = "livrée" )
```
**→ 89 012,69**

```dax
Coût des ventes =
CALCULATE ( SUM ( v_fait_ventes[cout_ligne] ), v_fait_commandes[statut] = "livrée" )
```
**→ 59 290,00**

```dax
Marge brute =
CALCULATE ( SUM ( v_fait_ventes[marge_ligne] ), v_fait_commandes[statut] = "livrée" )
```
**→ 29 722,69**

```dax
Taux de marge = DIVIDE ( [Marge brute], [CA livré] )
```
**→ 33,39 %**

> La mesure la plus discriminante de la grille. Si l'étudiant a pré-calculé un taux
> dans `v_fait_ventes` puis l'a moyenné en DAX, la matrice de la page 2 affichera des
> valeurs absurdes par catégorie. C'est la faute « moyenne de pourcentages » : le bloc
> Power BI est divisé par deux.

### Volume

```dax
Nb commandes = COUNTROWS ( v_fait_commandes )
```
**→ 648**

```dax
Nb commandes livrées =
CALCULATE ( COUNTROWS ( v_fait_commandes ), v_fait_commandes[statut] = "livrée" )
```
**→ 554**

```dax
Taux d'annulation =
DIVIDE (
    CALCULATE ( COUNTROWS ( v_fait_commandes ), v_fait_commandes[statut] = "annulée" ),
    [Nb commandes]
)
```
**→ 10,96 %**

```dax
Quantité vendue =
CALCULATE ( SUM ( v_fait_ventes[quantite] ), v_fait_commandes[statut] = "livrée" )
```
**→ 1 964**

### Panier moyen

```dax
Panier moyen =
DIVIDE (
    [CA livré],
    CALCULATE (
        DISTINCTCOUNT ( v_fait_ventes[id_commande] ),
        v_fait_commandes[statut] = "livrée"
    )
)
```
**→ 161,25** (89 012,69 ÷ 552)

> `DISTINCTCOUNT` sur la table de faits de détail ne voit que les commandes **qui ont
> au moins une ligne**. La décision de l'anomalie 5 est donc appliquée
> structurellement, sans exclusion manuelle.
>
> **Variante à accepter :** `DIVIDE([CA livré], [Nb commandes livrées])` → **160,67**,
> à condition que l'étudiant ait écrit dans sa note qu'il retient les 554 commandes
> livrées, y compris les vides. Les deux se défendent ; ne pas choisir ne se défend
> pas.

### Comparaison annuelle

```dax
CA livré N-1 =
CALCULATE ( [CA livré], SAMEPERIODLASTYEAR ( v_dim_calendrier[date_jour] ) )
```

Contrôles mois par mois (quelques points) :

| Mois affiché | `CA livré` | `CA livré N-1` |
|---|---|---|
| janv. 2026 | 4 478,94 | 2 761,47 |
| août 2026 | 7 956,65 | 2 626,70 |
| oct. 2026 | 4 247,60 | 4 906,56 |
| janv. 2025 | 2 761,47 | *(vide — pas de 2024)* |

> ⚠️ **Le piège à signaler en correction.**
> Filtré sur l'année 2026 entière : `CA livré` = 45 248,63 et `CA livré N-1` =
> 43 764,06, soit +3,4 %. **C'est trompeur** : 2026 s'arrête au 31 octobre.
> La bonne lecture est à période égale, janvier–octobre :
> **36 796,97 → 45 248,63, soit +22,97 %.**
> L'étudiant qui repère ça tout seul mérite un bonus explicite.

### Clients

```dax
Date de référence = MAXX ( ALL ( v_fait_commandes ), v_fait_commandes[date_commande] )
```
**→ 31/10/2026**, quel que soit le filtre (c'est la règle R5).

```dax
Dernier achat =
CALCULATE ( MAX ( v_fait_commandes[date_commande] ), v_fait_commandes[statut] = "livrée" )
```

```dax
Jours depuis dernier achat = DATEDIFF ( [Dernier achat], [Date de référence], DAY )
```

Contrôles : Fabrice Mpiana **0 j** · Grâce Luboya **1 j** · Didier Kambale **19 j** ·
Rodrigue Lusamba **172 j** · Carine Beya **442 j** (le plus ancien).

> Refuser `TODAY()` ou `NOW()` : les chiffres deviennent non reproductibles et le
> corrigé ne tombe plus. C'est la règle R5, et elle est notée.

---

## Formatage attendu

| Mesures | Format | Décimales |
|---|---|---|
| CA livré · Coût des ventes · Marge brute · CA livré N-1 | Devise USD | 0 |
| Panier moyen | Devise USD | 2 |
| Taux de marge · Taux d'annulation | Pourcentage | 1 ou 2 |
| Nb commandes · Nb commandes livrées · Quantité vendue · Jours depuis dernier achat | Entier | 0 |

---

## 🪞 Ce que la couche SQL a fait gagner

À montrer en restitution. Même résultat, deux fois moins de surface d'erreur :

**Sans couche de présentation** (approche de la version d'origine) :

```dax
CA livré =
CALCULATE (
    SUMX (
        lignes_commande,
        lignes_commande[quantite] * RELATED ( produits[prix_vente] )
            - COALESCE ( lignes_commande[remise_appliquee], 0 )
    ),
    commandes[statut] = "livrée"
)
```

**Avec la couche** :

```dax
CA livré =
CALCULATE ( SUM ( v_fait_ventes[ca_ligne] ), v_fait_commandes[statut] = "livrée" )
```

La règle de gestion est écrite **une fois**, en SQL, lisible par un comptable. Elle
n'est pas répliquée dans chaque mesure, chaque fichier `.pbix`, chaque analyste.

C'est exactement la question d'entretien d'embauche : *« où mettez-vous votre logique
métier, et pourquoi ? »*

---

## Les mesures bonus

### Jauge d'objectif 2026

```dax
Objectif 2026 = 50000

CA 2026 =
CALCULATE ( [CA livré], v_dim_calendrier[annee] = 2026 )

Avancement objectif = DIVIDE ( [CA 2026], [Objectif 2026] )
```
**→ 45 248,63 / 50 000 = 90,5 %**

### Segmentation RFM

```dax
Segment RFM =
VAR Recence   = [Jours depuis dernier achat]
VAR Frequence = [Nb commandes livrées]
VAR Montant   = [CA livré]
RETURN
SWITCH (
    TRUE (),
    ISBLANK ( Montant ),                          "Sans achat",
    Recence <= 60  && Montant >= 2000,            "Champion",
    Recence <= 60  && Frequence >= 5,             "Fidèle",
    Recence <= 90,                                "Actif",
    Recence <= 180,                               "À risque",
    "Perdu"
)
```

Les seuils sont un **choix métier**, pas une vérité. Ce qui est noté, c'est que
l'étudiant les ait explicités et puisse les justifier — pas qu'il retrouve ceux-ci.

### Page « Qualité des données » (bonus avancé)

```dax
Commandes sans ligne =
CALCULATE (
    COUNTROWS ( v_fait_commandes ),
    NOT ( v_fait_commandes[id_commande] IN VALUES ( v_fait_ventes[id_commande] ) )
)
```
**→ 2**

```dax
Clients sans achat =
CALCULATE (
    COUNTROWS ( v_dim_client ),
    FILTER ( v_dim_client, ISBLANK ( [CA livré] ) )
)
```
**→ 14**

---

*Corrigé · Projet BI ShopShop · Formation Data Analyst*
