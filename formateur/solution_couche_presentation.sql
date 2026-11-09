-- =====================================================================================
-- SHOPSHOP - CORRIGE FORMATEUR / LA COUCHE DE PRESENTATION (etape 3)
--
--   /!\  DOCUMENT FORMATEUR - A NE PAS DISTRIBUER AVANT LA CORRECTION  /!\
--
-- A executer apres 01, 02 et 05.
-- v_dim_calendrier est deja fournie aux etudiants dans sql/05_calendrier.sql.
--
-- -------------------------------------------------------------------------------------
-- CE QU'ON ATTEND DE L'ETUDIANT
--   v_dim_produit     : fournie en exemple dans le guide pas-a-pas (il la recopie)
--   v_dim_client      : A ECRIRE  (nettoyage de la ville)
--   v_fait_commandes  : A ECRIRE  (grain entete, sans la colonne montant)
--   v_fait_ventes     : A ECRIRE  (grain ligne, COALESCE + 3 colonnes calculees)
--
-- Toute variante qui retombe sur les memes chiffres de controle est acceptee.
-- On note le resultat et la justification, pas la syntaxe exacte.
-- -------------------------------------------------------------------------------------
-- POURQUOI CETTE ARCHITECTURE ET PAS UNE AUTRE
--
-- Le projet original laissait l'etudiant arbitrer entre deux approches (tout en DAX
-- cote Power BI, ou une couche SQL en amont). C'est une excellente question
-- d'architecte - et une tres mauvaise question de debutant : elle double le travail
-- et le laisse sans moyen de savoir laquelle il a ratee.
--
-- Ici on impose la couche SQL, qui est AUSSI la bonne reponse en entreprise :
--
--   1. Une seule definition du CA, ecrite une fois, lisible par tout le monde.
--      C'est litteralement le probleme de la reunion de direction du scenario.
--   2. Le nettoyage profite a tous les consommateurs de la base (le dashboard,
--      l'export Excel de la compta, le prochain outil), pas au seul fichier .pbix
--      pose sur le poste de l'etudiant.
--   3. Les mesures DAX deviennent des one-liners (SUM au lieu de SUMX + RELATED) :
--      le debutant ecrit 13 mesures justes au lieu de 13 mesures approximatives.
--   4. Ce qu'on n'expose pas ne peut pas etre mal utilise : commandes.montant,
--      la colonne qui ment, ne sort d'AUCUNE vue. Le piege est desamorce a la
--      source, pas rappele dans une consigne que personne ne relira.
--
-- La maxime du metier (Matthew Roche, equipe Power BI de Microsoft) :
--   "Transformez les donnees le plus en AMONT possible,
--    et le plus en AVAL que necessaire."
--   En amont (ici, en SQL) : nettoyage, typage, et les calculs ADDITIFS ligne a ligne.
--   En aval  (en DAX)      : les agregations, et SURTOUT tous les ratios.
--
-- LA REGLE QUI NE SE NEGOCIE JAMAIS : on ne pre-calcule pas un pourcentage en SQL.
--   taux de marge d'une categorie = SUM(marge) / SUM(ca)
--   et surtout PAS                = moyenne des taux de marge de ses produits
-- Un pourcentage ne se re-additionne pas. ca_ligne, cout_ligne et marge_ligne, si.
-- =====================================================================================

DROP VIEW IF EXISTS v_fait_ventes    CASCADE;
DROP VIEW IF EXISTS v_fait_commandes CASCADE;
DROP VIEW IF EXISTS v_dim_produit    CASCADE;
DROP VIEW IF EXISTS v_dim_client     CASCADE;


-- =====================================================
-- Vue      : v_dim_produit
-- Auteur   : [Votre Nom]
-- Creee le : [Date du jour]
-- Objectif : dimension produit - 1 ligne par produit, avec sa categorie.
-- Sources  : produits, categories
--
-- NOTE PEDAGOGIQUE : c'est la vue donnee en exemple dans le guide etudiant.
-- La categorie est APLATIE dans la dimension produit au lieu de rester une table
-- separee. On passe d'un flocon (categories -> produits -> faits) a une etoile
-- stricte. Resultat : une relation de moins a expliquer dans Power BI, un chemin
-- de filtre de moins a deboguer, et le moteur de Power BI est justement optimise
-- pour cette forme-la.
-- =====================================================
CREATE VIEW v_dim_produit AS
SELECT
    p.id_produit,
    p.nom_produit,
    c.nom_categorie,
    p.prix_vente,
    p.cout_achat,
    (p.prix_vente - p.cout_achat) AS marge_unitaire
FROM produits p
JOIN categories c ON c.id_categorie = p.id_categorie;
-- Controle : 25 lignes.


-- =====================================================
-- Vue      : v_dim_client
-- Auteur   : [Votre Nom]
-- Creee le : [Date du jour]
-- Objectif : dimension client - 1 ligne par client, ville normalisee.
-- Sources  : clients
--
-- C'EST ICI que l'anomalie 3 est reglee, une fois pour toutes :
--   TRIM    enleve les espaces parasites
--   INITCAP remet une majuscule par mot
-- 18 orthographes -> 7 villes. Et comme c'est fait dans la base, le dashboard,
-- l'export Excel de la compta et le prochain outil liront tous la MEME ville.
-- C'etait exactement le probleme de la reunion de direction.
--
-- ERREUR FREQUENTE A NE PAS SANCTIONNER TROP DUREMENT : l'etudiant qui nettoie
-- dans Power Query au lieu de la vue obtient les memes chiffres. Ce n'est pas
-- faux, c'est juste moins reutilisable. Le signaler, ne pas l'ecraser.
-- =====================================================
CREATE VIEW v_dim_client AS
SELECT
    cl.id_client,
    TRIM(cl.nom)            AS nom,
    INITCAP(TRIM(cl.ville)) AS ville,
    cl.province,
    cl.date_inscription
FROM clients cl;
-- Controle : 81 lignes, et SELECT COUNT(DISTINCT ville) = 7.
--
-- Le doublon client (#3 "Grâce Luboya" et #81 "GRÂCE LUBOYA ") reste present :
-- ce sont bien deux fiches distinctes dans le systeme source. Fusionner deux
-- clients est une decision metier, pas une decision de data analyst. On le
-- signale dans la note de mission, on ne le decide pas tout seul.
-- (Hors programme en version simplifiee : bonus si l'etudiant le reperte.)


-- =====================================================
-- Vue      : v_fait_commandes
-- Auteur   : [Votre Nom]
-- Creee le : [Date du jour]
-- Objectif : table de faits au grain de la COMMANDE (l'en-tete).
-- Sources  : commandes
--
-- POURQUOI DEUX TABLES DE FAITS ET PAS UNE SEULE ?
-- Parce qu'il y a deux niveaux de detail, et qu'on ne melange jamais deux grains
-- dans une meme table de faits :
--   . compter les commandes et calculer un taux d'annulation se fait au grain de
--     l'EN-TETE (648 commandes) ;
--   . calculer le CA et la marge se fait au grain de la LIGNE (1 289 lignes).
-- Si on ne gardait que v_fait_ventes, les 2 commandes vides (119 et 402, anomalie 5)
-- disparaitraient : on compterait 646 commandes au lieu de 648, et le taux
-- d'annulation serait faux. Ce n'est pas un detail d'esthete, c'est une regle.
--
-- NOTER L'ABSENCE DE LA COLONNE montant.
-- Elle est fausse (anomalie 1), donc elle ne sort d'AUCUNE vue. C'est beaucoup plus
-- solide que de la supprimer dans Power Query, ou chaque nouveau rapport devrait
-- penser a refaire le geste. Ce qu'on n'expose pas ne peut pas etre mal utilise.
-- =====================================================
CREATE VIEW v_fait_commandes AS
SELECT
    c.id_commande,
    c.id_client,
    c.date_commande,
    c.statut,
    c.canal
FROM commandes c;
-- Controle : 648 lignes, et la colonne montant ne doit PAS y figurer.


-- =====================================================
-- Vue      : v_fait_ventes
-- Auteur   : [Votre Nom]
-- Creee le : [Date du jour]
-- Objectif : table de faits au grain de la LIGNE DE COMMANDE, avec les montants
--            deja calcules.
-- Sources  : lignes_commande, produits
--
-- C'est LA vue du projet. Les regles R3 et R4 de l'enonce sont implementees ici,
-- une seule fois, pour tout le monde :
--   . remise NULL ramenee a 0            (anomalie 2, regle R3)
--   . ca_ligne    = quantite * prix_vente - remise
--   . cout_ligne  = quantite * cout_achat        (la remise ne touche pas le cout)
--   . marge_ligne = ca_ligne - cout_ligne
--
-- Ces trois colonnes sont ADDITIVES : un SUM() les re-agrege correctement a
-- n'importe quel niveau (par produit, par mois, par ville, par canal). C'est
-- precisement ce qui autorise a les calculer en amont.
--
-- /!\ AUCUN FILTRE SUR LE STATUT ICI. /!\
-- La vue expose TOUTES les lignes, y compris celles des commandes annulees.
-- Le perimetre "livrée" est une question de MESURE, pas de structure : le figer
-- dans la vue interdirait pour toujours d'analyser les annulations.
-- C'est l'erreur symetrique de celle de Jonas, et elle est plus grave : une donnee
-- filtree trop tot est une donnee perdue.
-- =====================================================
CREATE VIEW v_fait_ventes AS
SELECT
    lc.id_ligne,
    lc.id_commande,
    lc.id_produit,
    lc.quantite,
    COALESCE(lc.remise_appliquee, 0)                             AS remise,
    ROUND(lc.quantite * p.prix_vente
          - COALESCE(lc.remise_appliquee, 0), 2)                 AS ca_ligne,
    ROUND(lc.quantite * p.cout_achat, 2)                         AS cout_ligne,
    ROUND(lc.quantite * p.prix_vente
          - COALESCE(lc.remise_appliquee, 0)
          - lc.quantite * p.cout_achat, 2)                       AS marge_ligne
FROM lignes_commande lc
JOIN produits p ON p.id_produit = lc.id_produit;
-- Controle : 1 289 lignes.


-- =====================================================================================
-- LE MODELE POWER BI QUI EN DECOULE (etape 4)
--
--      v_dim_calendrier              v_dim_client
--             | 1                          | 1
--             +-------------+--------------+
--                           v *
--                    v_fait_commandes          (grain : la commande, 648)
--                           | 1
--                           v *
--                     v_fait_ventes            (grain : la ligne, 1 289)
--                           ^ *
--                           | 1
--                     v_dim_produit
--
-- 4 relations, aucun flocon, aucune colonne piegee.
-- Toutes en "un vers plusieurs", filtre simple, du 1 vers le *.
-- =====================================================================================


-- =====================================================================================
-- CONTROLES - a faire executer a l'etudiant avant qu'il ouvre Power BI
-- =====================================================================================

-- C1. Les grains : aucune ligne perdue, aucune ligne dupliquee.
SELECT 'v_dim_client' AS vue, COUNT(*) AS lignes, 81 AS attendu FROM v_dim_client
UNION ALL SELECT 'v_dim_produit',    COUNT(*),   25 FROM v_dim_produit
UNION ALL SELECT 'v_dim_calendrier', COUNT(*),  730 FROM v_dim_calendrier
UNION ALL SELECT 'v_fait_commandes', COUNT(*),  648 FROM v_fait_commandes
UNION ALL SELECT 'v_fait_ventes',    COUNT(*), 1289 FROM v_fait_ventes;

-- C2. Les KPI de reference, recalcules depuis la couche de presentation.
SELECT ROUND(SUM(fv.ca_ligne), 2)                              AS ca_livre,
       ROUND(SUM(fv.cout_ligne), 2)                            AS cout_des_ventes,
       ROUND(SUM(fv.marge_ligne), 2)                           AS marge_brute,
       ROUND(SUM(fv.marge_ligne) / SUM(fv.ca_ligne) * 100, 2)  AS taux_marge_pct,
       ROUND(SUM(fv.remise), 2)                                AS remises_accordees,
       SUM(fv.quantite)                                        AS articles_vendus,
       COUNT(DISTINCT fv.id_commande)                          AS commandes_facturees
FROM v_fait_ventes fv
JOIN v_fait_commandes fc ON fc.id_commande = fv.id_commande
WHERE fc.statut = 'livrée';
-- Attendu : 89 012,69 | 59 290,00 | 29 722,69 | 33,39 | 1 510,31 | 1 964 | 552

-- C3. Le taux d'annulation exige le grain EN-TETE : la preuve par l'exemple.
SELECT COUNT(*)                                            AS total_commandes,
       COUNT(*) FILTER (WHERE statut = 'annulée')          AS annulees,
       ROUND(COUNT(*) FILTER (WHERE statut = 'annulée') * 100.0
             / COUNT(*), 2)                                AS taux_annulation_pct
FROM v_fait_commandes;
-- Attendu : 648 | 71 | 10,96
-- Depuis v_fait_ventes seule on trouverait 646 commandes : la demonstration que
-- les deux tables de faits sont bien necessaires.

-- C4. La ville est propre des la sortie de la base.
SELECT COUNT(DISTINCT ville) AS nb_villes FROM v_dim_client;
-- Attendu : 7 (et non 18)

-- C5. Le CA par ville, sans aucun nettoyage cote Power BI.
SELECT dc.ville, ROUND(SUM(fv.ca_ligne), 2) AS ca
FROM v_fait_ventes fv
JOIN v_fait_commandes fc ON fc.id_commande = fv.id_commande
JOIN v_dim_client dc     ON dc.id_client   = fc.id_client
WHERE fc.statut = 'livrée'
GROUP BY dc.ville
ORDER BY ca DESC;
-- Attendu : Kinshasa 41 966,75 | Goma 13 030,73 | Kisangani 11 615,71 |
--           Matadi 8 689,70 | Lubumbashi 6 864,11 | Bukavu 4 539,44 |
--           Mbuji-Mayi 2 306,25
