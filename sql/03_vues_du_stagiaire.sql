-- =====================================================================================
-- SHOPSHOP - FICHIER 3 / LES TROIS VUES DE JONAS
--
--   /!\  CE FICHIER EST LE PROBLEME, PAS LA SOLUTION  /!\
--
-- Jonas Mbala etait le stagiaire BI de ShopShop. Il est parti en septembre, en
-- laissant ces trois vues derriere lui.
--
-- Regardez-les : elles sont bien ecrites. Prefixe v_, snake_case, en-tete de
-- documentation complet, indentation propre. Elles s'executent sans la moindre
-- erreur. On dirait du travail serieux - et ca l'est, presque.
--
-- Elles renvoient pourtant des chiffres faux.
--
-- C'est la premiere lecon du projet, et la plus importante :
--     DU SQL QUI S'EXECUTE N'EST PAS DU SQL QUI A RAISON.
-- Un dashboard construit sur une vue fausse est un dashboard faux, en plus joli.
--
-- CE QU'ON VOUS DEMANDE
--   1. Executez ce fichier tel quel. On ne corrige rien ici.
--   2. Etape 2 du projet : trouvez le defaut de chacune des trois vues.
--      Chaque vue a UN defaut principal. Une question vous met sur la piste.
--   3. Vous ne les reparerez pas. A l'etape 3, vous construirez votre propre
--      couche de vues propres, et celles-ci seront mises a la poubelle.
--      C'est ce qu'on fait en entreprise : on ne rafistole pas du code faux dont
--      personne ne comprend plus l'intention, on le remplace par du code dont on
--      repond.
-- =====================================================================================


-- =====================================================================================
-- VUE 1 / 3
-- =====================================================================================
-- Vue      : v_rentabilite_produits
-- Auteur   : Jonas Mbala (stagiaire BI)
-- Creee le : 2026-09-14
-- Objectif : calculer la rentabilite par produit et par categorie, incluant
--            quantites vendues, chiffre d'affaires et marge brute.
-- Sources  : lignes_commande, commandes, produits, categories
--
-- +-------------------------------------------------------------------------------+
-- | VOTRE PISTE (etape 2)                                                         |
-- | a) Cette vue renvoie 23 lignes. Le catalogue en compte 25. Ou sont passes     |
-- |    les deux autres produits ? Regardez le mot JOIN.                           |
-- | b) Executez : SELECT 150 * 2 - NULL;  Qu'est-ce que PostgreSQL repond ?       |
-- |    Maintenant regardez la colonne remise_appliquee. Elle est parfois NULL.    |
-- +-------------------------------------------------------------------------------+
-- =====================================================================================
CREATE OR REPLACE VIEW v_rentabilite_produits AS
SELECT
    c.nom_categorie,
    p.nom_produit,
    SUM(lc.quantite) AS total_quantite_vendue,
    SUM(lc.quantite * p.prix_vente - lc.remise_appliquee) AS chiffre_affaires,
    SUM(lc.quantite * (p.prix_vente - p.cout_achat) - lc.remise_appliquee) AS marge_brute
FROM lignes_commande lc
JOIN commandes cmd  ON lc.id_commande  = cmd.id_commande
JOIN produits p     ON lc.id_produit   = p.id_produit
JOIN categories c   ON p.id_categorie  = c.id_categorie
WHERE cmd.statut = 'livrée'
GROUP BY c.nom_categorie, p.nom_produit;


-- =====================================================================================
-- VUE 2 / 3
-- =====================================================================================
-- Vue      : v_evolution_ventes_mensuelles
-- Auteur   : Jonas Mbala (stagiaire BI)
-- Creee le : 2026-09-14
-- Objectif : suivre l'evolution mensuelle des ventes avec le nombre de commandes,
--            le chiffre d'affaires genere et le taux d'annulation.
-- Sources  : commandes
--
-- +-------------------------------------------------------------------------------+
-- | VOTRE PISTE (etape 2)                                                         |
-- | a) D'ou vient le chiffre d'affaires de cette vue ? De quelle colonne ?        |
-- |    Est-ce que cette colonne est fiable ? (relisez la regle R1 de l'enonce)    |
-- | b) La date est decoupee en deux entiers : annee et mois. Essayez de relier    |
-- |    "2026" et "8" a un calendrier dans Power BI. Vous allez comprendre.        |
-- +-------------------------------------------------------------------------------+
-- =====================================================================================
CREATE OR REPLACE VIEW v_evolution_ventes_mensuelles AS
SELECT
    EXTRACT(YEAR  FROM date_commande) AS annee,
    EXTRACT(MONTH FROM date_commande) AS mois,
    COUNT(id_commande) AS total_commandes,
    SUM(CASE WHEN statut = 'livrée' THEN montant ELSE 0 END) AS ca_genere,
    COUNT(CASE WHEN statut = 'annulée' THEN 1 END) * 100.0 / COUNT(id_commande)
        AS taux_annulation_pourcentage
FROM commandes
GROUP BY EXTRACT(YEAR FROM date_commande), EXTRACT(MONTH FROM date_commande)
ORDER BY annee DESC, mois DESC;


-- =====================================================================================
-- VUE 3 / 3
-- =====================================================================================
-- Vue      : v_segmentation_clients
-- Auteur   : Jonas Mbala (stagiaire BI)
-- Creee le : 2026-09-14
-- Objectif : segmenter les clients selon la recence, la frequence d'achat et le
--            montant total depense sur les commandes livrees.
-- Sources  : clients, commandes
--
-- +-------------------------------------------------------------------------------+
-- | VOTRE PISTE (etape 2)                                                         |
-- | a) Comptez les lignes de cette vue, puis comptez les lignes de la table       |
-- |    clients. Les deux nombres sont differents. Ou sont passes les autres ?     |
-- |    Est-ce qu'un client qui n'achete jamais est une information inutile ?      |
-- | b) CURRENT_DATE, c'est la date d'aujourd'hui. Executez la vue aujourd'hui,    |
-- |    puis demain. Est-ce que le resultat est le meme ? Est-ce qu'un chiffre     |
-- |    qui bouge tout seul est auditable ?                                        |
-- +-------------------------------------------------------------------------------+
-- =====================================================================================
CREATE OR REPLACE VIEW v_segmentation_clients AS
SELECT
    cl.id_client,
    cl.nom,
    CURRENT_DATE - MAX(cmd.date_commande) AS jours_depuis_dernier_achat,
    COUNT(cmd.id_commande) AS nombre_commandes,
    SUM(cmd.montant) AS montant_total_depense
FROM clients cl
JOIN commandes cmd ON cl.id_client = cmd.id_client
WHERE cmd.statut = 'livrée'
GROUP BY cl.id_client, cl.nom;


-- =====================================================================================
-- POUR DEMARRER VOTRE AUDIT
-- Executez ces trois requetes et notez les trois nombres sur un papier.
-- Vous les comparerez a vos propres chiffres a l'etape 3.
-- =====================================================================================
SELECT 'v_rentabilite_produits'        AS vue_de_jonas,
       COUNT(*)                        AS nb_lignes,
       ROUND(SUM(chiffre_affaires), 2) AS ca_annonce
FROM v_rentabilite_produits
UNION ALL
SELECT 'v_evolution_ventes_mensuelles', COUNT(*), ROUND(SUM(ca_genere), 2)
FROM v_evolution_ventes_mensuelles
UNION ALL
SELECT 'v_segmentation_clients',        COUNT(*), ROUND(SUM(montant_total_depense), 2)
FROM v_segmentation_clients;

-- Vous allez obtenir DEUX chiffres d'affaires differents sur la meme base, le meme
-- jour : 87 028,19 d'un cote, 94 165,80 de l'autre.
-- C'est exactement ce qui s'est passe dans la reunion de direction du mois dernier.
-- Et le pire, c'est qu'AUCUN DES DEUX n'est le bon.
--
-- Le vrai chiffre, vous le calculerez vous-meme a l'etape 3. Il vaut 89 012,69 USD.
-- Notez-le : c'est votre boussole pour tout le reste du projet.
