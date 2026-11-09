# 🛠️ Générateur des maquettes

> Document formateur. Les étudiants n'ont besoin que des PNG, dans
> [`ressources/maquettes/`](../../ressources/maquettes/).

## Régénérer les deux images

```bash
python formateur/maquettes_src/generer.py
```

Prérequis : **Python 3** et **Pillow** (`pip install pillow`), plus les polices
**Segoe UI** (présentes par défaut sur Windows — ce sont celles de Power BI).

## Pourquoi un générateur plutôt que deux captures d'écran

Parce que les maquettes affichent des chiffres, et qu'un chiffre affiché dans un
support pédagogique doit être vrai.

Le script relit `sql/02_charger_les_donnees.sql`, recharge les 1 289 lignes dans une
base SQLite en mémoire et **recalcule tous les agrégats** en appliquant les règles R1
à R5 du brief. Aucune valeur n'est saisie à la main. Une assertion arrête le script si
le CA recalculé n'est pas exactement **89 012,69 USD** : il est impossible de publier
une maquette qui contredit le corrigé.

Si un jour le jeu de données change, relancez le script : les maquettes suivent.

## Les fichiers

| Fichier | Rôle |
|---|---|
| `generer.py` | point d'entrée : extraction des chiffres + rendu des 2 pages |
| `kit.py` | moteur de rendu : charte, cartes, textes, barres, courbe, anneau |
| `page1.py` | mise en page de la page 1 (vue d'ensemble) |
| `page2.py` | mise en page de la page 2 (produits & clients) |
| `donnees.py` | **généré** par `generer.py` — ne pas éditer à la main |

## La charte appliquée

| Rôle | Couleur |
|---|---|
| Primaire / CA | `#CC0000` |
| Secondaire / clients | `#3FADA1` |
| Alerte intermédiaire | `#E8A33D` |
| Accent marge | `#CC2047` |
| Fond de page | `#F8F9FA` · cartes `#FFFFFF` · bordures `#DADDE1` |
| Texte | titres `#2B2B2B` · corps `#434343` · secondaire `#9A9A9A` |

Format 1600 × 900 px, rendu en 2× puis réduit en Lanczos (texte net).
Les mêmes couleurs sont dans [`ressources/theme_shopshop.json`](../../ressources/theme_shopshop.json),
le thème que les étudiants chargent dans Power BI.

## Mise en forme conditionnelle des taux de marge

Les seuils utilisés dans la matrice et les chips, identiques sur les deux pages :

| Taux de marge | Couleur |
|---|---|
| < 25 % | rouge `#CC0000` |
| 25 % – 40 % | ambre `#E8A33D` |
| > 40 % | teal `#3FADA1` |

---

*Projet BI ShopShop · Formation Data Analyst*
