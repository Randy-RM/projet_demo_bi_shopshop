-- =====================================================================================
-- SHOPSHOP - FICHIER 4 / LA BOITE A OUTILS DE L'AUDIT
--
-- N'executez PAS ce fichier en entier. C'est un carnet de requetes :
-- vous copiez-collez celle dont vous avez besoin, vous l'executez, vous lisez
-- le resultat, vous notez votre conclusion dans votre note de mission.
--
-- Il accompagne l'ETAPE 1 (explorer) et l'ETAPE 2 (auditer) du projet.
--
-- Les requetes marquees [FOURNIE] sont completes : executez-les et interpretez.
-- Les requetes marquees [A VOUS]  sont a ecrire : le modele est juste au-dessus.
-- =====================================================================================


-- #####################################################################################
-- ETAPE 1 - PRENDRE LA TEMPERATURE
-- Avant de calculer quoi que ce soit, on regarde ce qu'il y a dans la boite.
-- #####################################################################################

-- --- E1 [FOURNIE] Combien de lignes dans chaque table ? ------------------------------
-- A faire systematiquement en arrivant sur une base inconnue. Si Power BI vous
-- affiche plus tard un autre nombre de commandes, vous saurez tout de suite.
SELECT 'clients'         AS table_, COUNT(*) AS nb_lignes FROM clients
UNION ALL SELECT 'categories',      COUNT(*) FROM categories
UNION ALL SELECT 'produits',        COUNT(*) FROM produits
UNION ALL SELECT 'commandes',       COUNT(*) FROM commandes
UNION ALL SELECT 'lignes_commande', COUNT(*) FROM lignes_commande;
-- Attendu : 81 / 5 / 25 / 648 / 1289


-- --- E2 [FOURNIE] Quelle periode couvre la base ? ------------------------------------
SELECT MIN(date_commande) AS premiere_commande,
       MAX(date_commande) AS derniere_commande,
       COUNT(*)           AS nb_commandes
FROM commandes;
-- Attendu : 2025-01-01 -> 2026-10-31, 648 commandes.
--
-- RETENEZ LA DATE DU 31 OCTOBRE 2026. C'est "aujourd'hui" pour ce projet.
-- Toutes vos anciennetes se calculent par rapport a elle, jamais par rapport a la
-- vraie date du jour (regle R5). Sinon vos chiffres changent tout seuls chaque
-- matin, et plus personne ne peut verifier votre dashboard.


-- --- E3 [FOURNIE] Quelles valeurs trouve-t-on dans les colonnes de texte ? -----------
-- Le reflexe de base : avant de filtrer sur 'livrée', on verifie comment c'est ecrit.
SELECT statut, COUNT(*) AS nb FROM commandes GROUP BY statut ORDER BY nb DESC;
-- Attendu : livrée 554 / annulée 71 / en_cours 23

SELECT canal, COUNT(*) AS nb FROM commandes GROUP BY canal ORDER BY nb DESC;
-- Attendu : 3 canaux, aucune surprise (la colonne est protegee par un CHECK)


-- #####################################################################################
-- ETAPE 2 - L'AUDIT QUALITE
-- Cinq anomalies a trouver. Pour chacune : combien de lignes touchees, quel impact
-- sur le dashboard, et surtout QUELLE DECISION vous prenez.
-- #####################################################################################

-- =====================================================================================
-- ANOMALIE 1 - Les deux chiffres d'affaires de la reunion de direction
-- =====================================================================================

-- --- A1a [FOURNIE] Les deux totaux sont-ils d'accord ? ------------------------------
-- A gauche : le total tape a la caisse (commandes.montant).
-- A droite : le total recalcule depuis le detail des paniers.
SELECT
    ROUND((SELECT SUM(montant) FROM commandes WHERE statut = 'livrée'), 2)
        AS total_saisi_a_la_caisse,
    ROUND((SELECT SUM(lc.quantite * p.prix_vente - COALESCE(lc.remise_appliquee, 0))
           FROM lignes_commande lc
           JOIN produits p     ON p.id_produit   = lc.id_produit
           JOIN commandes cmd  ON cmd.id_commande = lc.id_commande
           WHERE cmd.statut = 'livrée'), 2)
        AS total_recalcule_depuis_les_lignes;
-- Attendu : 94 165,80  et  89 012,69
-- Soit 5 153,11 USD d'ecart. Il faut maintenant savoir D'OU il vient : un ecart
-- qu'on ne sait pas expliquer, on ne peut pas le defendre en reunion.


-- --- A1b [FOURNIE] D'ou vient l'ecart, commande par commande ? ----------------------
-- Une CTE (le bloc WITH ... AS) = un resultat intermediaire nomme, qu'on peut
-- ensuite utiliser comme une table. Ici : le vrai total de chaque commande.
WITH total_des_lignes AS (
    SELECT lc.id_commande,
           SUM(lc.quantite * p.prix_vente - COALESCE(lc.remise_appliquee, 0)) AS vrai_total
    FROM lignes_commande lc
    JOIN produits p ON p.id_produit = lc.id_produit
    GROUP BY lc.id_commande
)
SELECT cmd.id_commande,
       cmd.statut,
       ROUND(t.vrai_total, 2)         AS total_des_lignes,
       cmd.montant                    AS total_de_la_caisse,
       ROUND(cmd.montant - t.vrai_total, 2) AS ecart
FROM commandes cmd
JOIN total_des_lignes t ON t.id_commande = cmd.id_commande
WHERE ABS(cmd.montant - t.vrai_total) > 0.005
ORDER BY ABS(cmd.montant - t.vrai_total) DESC;
-- Attendu : exactement 5 commandes fautives.
-- Regardez la premiere ligne du resultat. Une seule commande explique presque tout
-- l'ecart : quelqu'un a tape un zero de trop a la caisse.
--
-- VOTRE DECISION A ECRIRE : quelle colonne devient la source de verite du CA,
-- et pourquoi ? (c'est la regle R1 de l'enonce - mais il faut savoir la defendre)


-- =====================================================================================
-- ANOMALIE 2 - Les remises a NULL, ou comment perdre 2 000 USD sans s'en rendre compte
-- =====================================================================================

-- --- A2a [FOURNIE] Le mini-test qui explique tout -----------------------------------
SELECT 150 - 0    AS avec_zero,
       150 - NULL AS avec_null;
-- Attendu : 150  et  (vide)
--
-- NULL ne veut pas dire 0. NULL veut dire "on ne sait pas".
-- Et "150 moins on-ne-sait-pas" = "on ne sait pas". Toute l'operation est perdue.
-- Pire : SUM() ignore silencieusement les NULL. Aucune erreur, aucun avertissement.
-- Votre total est simplement trop petit, et rien ne vous le dit.


-- --- A2b [FOURNIE] Combien de lignes sont concernees, et combien ca coute ? ----------
SELECT COUNT(*) FILTER (WHERE lc.remise_appliquee IS NULL) AS lignes_remise_null,
       COUNT(*)                                            AS lignes_total,
       ROUND(SUM(lc.quantite * p.prix_vente - lc.remise_appliquee), 2)
           AS ca_si_on_ne_fait_rien,
       ROUND(SUM(lc.quantite * p.prix_vente - COALESCE(lc.remise_appliquee, 0)), 2)
           AS ca_si_on_traite_les_null
FROM lignes_commande lc
JOIN produits p    ON p.id_produit   = lc.id_produit
JOIN commandes cmd ON cmd.id_commande = lc.id_commande
WHERE cmd.statut = 'livrée';
-- Attendu : 32 lignes sur 1 117 (et 34 sur 1 289 si on compte tous les statuts),
--           87 028,19 contre 89 012,69.
-- 1 984,50 USD qui disparaissent a cause de 32 cases vides.
--
-- COALESCE(x, 0) se lit : "prends x, et si x est NULL, prends 0 a la place".
-- C'est le pansement le plus utile de tout le SQL. Apprenez-le par coeur.
--
-- VOTRE DECISION A ECRIRE : une remise non saisie, ca veut dire "pas de remise"
-- ou "remise inconnue" ? Qu'est-ce que vous en faites, et pourquoi ?


-- =====================================================================================
-- ANOMALIE 3 - Sept villes, dix-huit orthographes
-- =====================================================================================

-- --- A3a [FOURNIE] Les villes telles qu'elles sont saisies --------------------------
-- Les crochets servent a rendre les espaces visibles : '[Kinshasa ]' saute aux yeux,
-- 'Kinshasa ' non.
SELECT '[' || ville || ']' AS ville_brute, COUNT(*) AS nb_clients
FROM clients
GROUP BY ville
ORDER BY ville;
-- Attendu : 18 lignes. Comptez les villes REELLES : il y en a 7.
-- Kinshasa apparait 6 fois (majuscules, minuscules, espaces avant, espaces apres).


-- --- A3b [FOURNIE] Les deux fonctions qui reglent 90 % du probleme ------------------
SELECT '[' || '  KINSHASA  ' || ']'                   AS depart,
       '[' || TRIM('  KINSHASA  ') || ']'             AS apres_trim,
       '[' || INITCAP(TRIM('  KINSHASA  ')) || ']'    AS apres_trim_et_initcap;
-- TRIM    = enleve les espaces au debut et a la fin
-- INITCAP = met une majuscule a chaque debut de mot, le reste en minuscules
-- Attendu : [  KINSHASA  ] / [KINSHASA] / [Kinshasa]

SELECT COUNT(DISTINCT ville)                AS orthographes_brutes,
       COUNT(DISTINCT INITCAP(TRIM(ville))) AS villes_reelles
FROM clients;
-- Attendu : 18 et 7
--
-- VOTRE DECISION A ECRIRE : ou nettoyez-vous cette colonne ? Dans la base, pour
-- que tout le monde en profite, ou dans votre fichier Power BI, pour vous seul ?


-- =====================================================================================
-- ANOMALIE 4 - Ce que le INNER JOIN fait disparaitre sans prevenir
-- =====================================================================================

-- --- A4a [FOURNIE] Le modele : les produits jamais vendus ---------------------------
-- La technique s'appelle "anti-jointure" et se lit en trois temps :
--   LEFT JOIN  -> garde TOUS les produits, meme ceux qui n'ont aucune vente
--   WHERE ... IS NULL -> ne garde QUE ceux qui n'ont rien trouve en face
SELECT p.id_produit, p.nom_produit, p.prix_vente
FROM produits p
LEFT JOIN lignes_commande lc ON lc.id_produit = p.id_produit
WHERE lc.id_ligne IS NULL;
-- Attendu : 2 produits.
-- Avec un INNER JOIN (le JOIN tout court), ces deux-la n'apparaissent nulle part.
-- Ils ne sont pas "a zero" dans le rapport : ils sont ABSENTS. Et un produit absent,
-- personne ne pose de question dessus. C'est la pire sorte d'erreur : invisible.


-- --- A4b [A VOUS] Les clients qui n'ont jamais eu de commande livree -----------------
-- Meme technique que A4a, en partant de la table clients.
-- Attention : "jamais de commande livree" n'est pas la meme chose que "jamais de
-- commande". Un client qui a commande une fois puis annule n'a aucun CA.
-- Attendu : 14 clients sur 81.
--
-- Ecrivez votre requete ici :




-- =====================================================================================
-- ANOMALIE 5 - Les commandes vides
-- =====================================================================================

-- --- A5 [A VOUS] Des commandes sans aucune ligne de detail --------------------------
-- Toujours la meme technique qu'en A4a, cette fois entre commandes et
-- lignes_commande. Affichez l'id, le statut et le montant.
-- Attendu : 2 commandes, livrees toutes les deux, avec un montant de caisse non nul
-- mais aucun produit en face.
--
-- Ecrivez votre requete ici :




-- Puis posez-vous la question du panier moyen :
--   panier moyen = CA total / nombre de commandes
-- Mais quel nombre de commandes ? 554 commandes livrees, ou 552 qui contiennent
-- vraiment quelque chose ? Les deux reponses se defendent. Choisissez-en une,
-- ECRIVEZ-LA dans votre note, et tenez-vous-y partout.
-- C'est ca, une regle de gestion : pas la bonne reponse, la meme reponse pour tous.


-- #####################################################################################
-- VOS CHIFFRES DE CONTROLE
-- Executez cette requete a la fin de l'etape 2 et recopiez le resultat quelque part.
-- Tout le reste du projet doit retomber sur ces nombres-la.
-- #####################################################################################
SELECT
    ROUND(SUM(lc.quantite * p.prix_vente - COALESCE(lc.remise_appliquee, 0)), 2)
        AS ca_livre,
    ROUND(SUM(lc.quantite * p.cout_achat), 2)
        AS cout_des_ventes,
    ROUND(SUM(lc.quantite * p.prix_vente - COALESCE(lc.remise_appliquee, 0))
          - SUM(lc.quantite * p.cout_achat), 2)
        AS marge_brute,
    COUNT(DISTINCT lc.id_commande)
        AS commandes_avec_lignes,
    SUM(lc.quantite)
        AS articles_vendus
FROM lignes_commande lc
JOIN produits p    ON p.id_produit   = lc.id_produit
JOIN commandes cmd ON cmd.id_commande = lc.id_commande
WHERE cmd.statut = 'livrée';
-- Attendu : 89 012,69 | 59 290,00 | 29 722,69 | 552 | 1 964
