-- =====================================================================================
-- SHOPSHOP - FICHIER 1 / CREER LES TABLES
--
-- A executer EN PREMIER, sur une base vide nommee shopshop.
--
-- Ce fichier ne contient aucune donnee : il dessine seulement les "tiroirs"
-- dans lesquels le fichier 2 viendra ranger les lignes.
--
-- Ordre des fichiers du projet :
--     1. 01_creer_la_base.sql      <- vous etes ici (la structure)
--     2. 02_charger_les_donnees.sql   (les 648 commandes)
--     3. 03_vues_du_stagiaire.sql     (les 3 vues a auditer)
--     4. 05_calendrier.sql            (le calendrier, fourni tout fait)
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- 0. ON REPART DE ZERO
--
-- DROP TABLE IF EXISTS = "supprime cette table si elle existe deja, sinon ne dis rien".
-- CASCADE = "et supprime aussi tout ce qui dependait d'elle" (les vues, par exemple).
--
-- On supprime dans l'ordre INVERSE des dependances : d'abord les tables qui pointent
-- vers les autres (lignes_commande pointe vers commandes), ensuite celles qui sont
-- pointees. Sinon PostgreSQL refuse, comme on refuse d'enlever le pied d'une table
-- avant d'avoir enleve ce qui est pose dessus.
--
-- Consequence utile : vous pouvez relancer ce fichier autant de fois que necessaire.
-- -------------------------------------------------------------------------------------
DROP TABLE IF EXISTS lignes_commande CASCADE;
DROP TABLE IF EXISTS commandes       CASCADE;
DROP TABLE IF EXISTS produits        CASCADE;
DROP TABLE IF EXISTS categories      CASCADE;
DROP TABLE IF EXISTS clients         CASCADE;


-- =====================================================================================
-- 1. LES DIMENSIONS : le contexte. QUI ? QUOI ? OU ?
--
-- Une dimension repond a "de qui / de quoi parle-t-on ?".
-- Elle contient une ligne par chose : un client = une ligne, un produit = une ligne.
-- On y met des libelles qu'on affichera dans le dashboard (un nom de ville, un nom
-- de produit), pas des montants a additionner.
-- =====================================================================================

-- ------------------------------------------------------------------------- clients
-- 81 clients.
--
-- ATTENTION a la colonne ville : elle est saisie a la main par les vendeurs en
-- boutique, sans liste deroulante et sans controle. Resultat previsible : la meme
-- ville y est ecrite de plusieurs facons ("Kinshasa", "KINSHASA", "kinshasa ").
-- C'est le defaut le plus courant du monde reel, et vous allez le rencontrer.
CREATE TABLE clients (
    id_client        SERIAL PRIMARY KEY,   -- SERIAL = numero automatique 1, 2, 3...
    nom              VARCHAR(100) NOT NULL,
    ville            VARCHAR(60),          -- <-- saisie libre, donc sale
    province         VARCHAR(60),          -- saisie depuis une liste : propre
    date_inscription DATE NOT NULL
);

-- ---------------------------------------------------------------------- categories
-- 5 categories (Electronique, Telephonie, Vetements, Maison & Deco, Papeterie).
CREATE TABLE categories (
    id_categorie  SERIAL PRIMARY KEY,
    nom_categorie VARCHAR(50) NOT NULL
);

-- ------------------------------------------------------------------------ produits
-- 25 produits.
--
-- Deux colonnes de prix, et c'est volontaire :
--     prix_vente = ce que le client paie
--     cout_achat = ce que ShopShop a paye au fournisseur
-- La difference entre les deux, c'est la MARGE. Sans cout_achat, on ne peut faire
-- qu'un dashboard de chiffre d'affaires ; avec, on peut faire un dashboard de
-- rentabilite. C'est toute la difference entre "on vend beaucoup" et "on gagne
-- de l'argent" - et ce n'est pas toujours la meme chose.
CREATE TABLE produits (
    id_produit   SERIAL PRIMARY KEY,
    nom_produit  VARCHAR(100) NOT NULL,
    id_categorie INT REFERENCES categories(id_categorie),  -- lien vers categories
    prix_vente   DECIMAL(10, 2) NOT NULL,   -- en USD
    cout_achat   DECIMAL(10, 2) NOT NULL    -- en USD
);


-- =====================================================================================
-- 2. LES FAITS : les evenements mesurables. COMBIEN ?
--
-- Une table de faits contient ce qui s'est PASSE : une vente, une commande, un clic.
-- Elle grossit tous les jours, elle contient des nombres qu'on additionne, et elle
-- pointe vers les dimensions pour savoir de qui/quoi il s'agit.
--
-- Il y a ici DEUX tables de faits, parce qu'il y a deux niveaux de detail :
--     commandes        = 1 ligne par transaction      (648 lignes)
--     lignes_commande  = 1 ligne par produit achete   (1 289 lignes)
-- Ce "niveau de detail" porte un nom en BI : le GRAIN. Retenez le mot, il revient
-- tout le temps dans le projet.
-- =====================================================================================

-- ----------------------------------------------------------------------- commandes
-- 648 commandes, l'en-tete de chaque transaction.
--
-- ATTENTION a la colonne montant : c'est le total tape par la caissiere au moment
-- de l'encaissement. Il n'est JAMAIS recalcule ensuite. Si quelqu'un se trompe de
-- touche, l'erreur reste dans la base pour toujours. Traitez cette colonne avec
-- beaucoup de prudence (etape 2 du projet : l'audit qualite).
CREATE TABLE commandes (
    id_commande   SERIAL PRIMARY KEY,
    id_client     INT REFERENCES clients(id_client),
    date_commande DATE NOT NULL,
    statut        VARCHAR(20) CHECK (statut IN ('livrée', 'en_cours', 'annulée')),
    canal         VARCHAR(20) CHECK (canal  IN ('Boutique', 'En ligne', 'Mobile Money')),
    montant       DECIMAL(10, 2)   -- <-- saisi a la caisse, jamais verifie
);
-- CHECK (...) = PostgreSQL refusera toute autre valeur que celles de la liste.
-- C'est une garantie : vous ne trouverez jamais 'Livree' ou 'LIVREE' dans statut.

-- ----------------------------------------------------------------- lignes_commande
-- 1 289 lignes : le detail de ce qu'il y a dans chaque panier.
--
-- C'est la table la plus FINE de la base, donc la seule source fiable du chiffre
-- d'affaires : elle sait exactement quel produit, en quelle quantite, avec quelle
-- remise. On ne peut pas se tromper de touche sur un total qui n'existe pas.
--
-- remise_appliquee est en USD (une remise de 5 = 5 dollars de moins), PAS en
-- pourcentage. Et elle est parfois NULL. Retenez ca aussi.
CREATE TABLE lignes_commande (
    id_ligne         SERIAL PRIMARY KEY,
    id_commande      INT REFERENCES commandes(id_commande),
    id_produit       INT REFERENCES produits(id_produit),
    quantite         INT NOT NULL,
    remise_appliquee DECIMAL(10, 2) DEFAULT 0   -- <-- parfois NULL malgre le DEFAULT
);


-- =====================================================================================
-- 3. LES INDEX : pour que ce soit rapide
--
-- Un index, c'est l'equivalent de l'index alphabetique au dos d'un livre : au lieu
-- de lire les 300 pages pour trouver un mot, on regarde la bonne page directement.
--
-- PostgreSQL cree TOUT SEUL un index sur chaque cle primaire (id_client, id_produit...)
-- mais PAS sur les cles etrangeres (les colonnes qui pointent vers une autre table).
-- Or ce sont exactement celles que Power BI utilise a chaque rafraichissement.
-- D'ou ces six lignes.
-- =====================================================================================
CREATE INDEX idx_commandes_id_client     ON commandes       (id_client);
CREATE INDEX idx_commandes_date_commande ON commandes       (date_commande);
CREATE INDEX idx_commandes_statut        ON commandes       (statut);
CREATE INDEX idx_lignes_id_commande      ON lignes_commande (id_commande);
CREATE INDEX idx_lignes_id_produit       ON lignes_commande (id_produit);
CREATE INDEX idx_produits_id_categorie   ON produits        (id_categorie);


-- =====================================================================================
-- VERIFICATION : les 5 tables doivent exister et etre vides.
-- Copiez-collez cette requete et executez-la.
-- =====================================================================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
-- Resultat attendu : 5 lignes
--   categories / clients / commandes / lignes_commande / produits
--
-- Si vous voyez ces 5 noms : parfait, passez au fichier 02_charger_les_donnees.sql.
