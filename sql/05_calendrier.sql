-- =====================================================================================
-- SHOPSHOP - FICHIER 5 / LE CALENDRIER (CADEAU)
--
-- A executer apres les fichiers 1 et 2. Vous n'avez rien a ecrire ici : on vous
-- donne cette vue toute faite. Elle fait partie de votre couche de presentation
-- (etape 3), mais c'est de la plomberie technique, pas de la logique metier.
--
-- A QUOI SERT UNE TABLE DE DATES, ET POURQUOI VOUS NE POUVEZ PAS VOUS EN PASSER
--
-- Dans la base, les dates n'existent que les jours ou quelqu'un a achete quelque
-- chose. S'il n'y a eu aucune vente le 14 mars, le 14 mars n'existe nulle part.
-- Pour Power BI, un mois sans vente n'est pas "un mois a zero" : c'est un mois qui
-- n'existe pas. Votre courbe saute par-dessus, et personne ne voit le trou.
--
-- Une table de dates, c'est une table qui contient TOUS les jours de la periode,
-- qu'il se soit passe quelque chose ou non. C'est elle qui permet a Power BI de :
--   . afficher les mois dans l'ordre, et sans trou ;
--   . comparer 2026 a 2025 (la fonction DAX SAMEPERIODLASTYEAR) ;
--   . filtrer plusieurs tableaux a la fois avec un seul segment de dates.
--
-- Regle a retenir : UN MODELE POWER BI SANS TABLE DE DATES EST UN MODELE INCOMPLET.
-- Peu importe le projet, peu importe l'entreprise. C'est non negociable.
-- =====================================================================================

DROP VIEW IF EXISTS v_dim_calendrier CASCADE;

-- =====================================================
-- Vue      : v_dim_calendrier
-- Auteur   : Equipe pedagogique (fournie avec le projet)
-- Creee le : 2026-11-01
-- Objectif : fournir a Power BI une ligne par jour, du 1er janvier 2025 au
--            31 decembre 2026, avec des libelles de mois en francais.
-- Sources  : generate_series (aucune table : on fabrique les dates)
-- =====================================================
CREATE VIEW v_dim_calendrier AS
SELECT
    -- generate_series fabrique une suite : ici, un jour apres l'autre.
    jour::date AS date_jour,

    EXTRACT(YEAR  FROM jour)::int AS annee,
    EXTRACT(MONTH FROM jour)::int AS mois_numero,

    -- On ecrit les noms de mois a la main plutot qu'avec TO_CHAR.
    -- Pourquoi ? Parce que TO_CHAR suit la langue du serveur PostgreSQL : sur une
    -- machine configuree en anglais, vous obtiendriez "January". Une vue doit
    -- donner le meme resultat chez tout le monde, point.
    CASE EXTRACT(MONTH FROM jour)::int
        WHEN  1 THEN 'janvier'   WHEN  2 THEN 'février'   WHEN  3 THEN 'mars'
        WHEN  4 THEN 'avril'     WHEN  5 THEN 'mai'       WHEN  6 THEN 'juin'
        WHEN  7 THEN 'juillet'   WHEN  8 THEN 'août'      WHEN  9 THEN 'septembre'
        WHEN 10 THEN 'octobre'   WHEN 11 THEN 'novembre'  WHEN 12 THEN 'décembre'
    END AS nom_mois,

    -- Le libelle court affiche sous votre courbe : "janv. 2025", "févr. 2025"...
    CASE EXTRACT(MONTH FROM jour)::int
        WHEN  1 THEN 'janv.' WHEN  2 THEN 'févr.' WHEN  3 THEN 'mars'
        WHEN  4 THEN 'avr.'  WHEN  5 THEN 'mai'   WHEN  6 THEN 'juin'
        WHEN  7 THEN 'juil.' WHEN  8 THEN 'août'  WHEN  9 THEN 'sept.'
        WHEN 10 THEN 'oct.'  WHEN 11 THEN 'nov.'  WHEN 12 THEN 'déc.'
    END || ' ' || EXTRACT(YEAR FROM jour)::text AS mois_annee,

    -- LA COLONNE QUI SAUVE VOTRE COURBE.
    -- "janv. 2025" est du texte. Power BI trie le texte par ordre alphabetique :
    -- votre annee commencerait en avril, puis aout, puis decembre... Cette colonne
    -- donne 202501, 202502, 202503 : des nombres, qui se trient correctement.
    -- Dans Power BI vous direz : "trier mois_annee par mois_tri" (etape 4).
    (EXTRACT(YEAR FROM jour) * 100 + EXTRACT(MONTH FROM jour))::int AS mois_tri,

    'T' || EXTRACT(QUARTER FROM jour)::text AS trimestre

FROM generate_series(
        DATE '2025-01-01',   -- premier jour de la premiere annee de donnees
        DATE '2026-12-31',   -- dernier jour de la derniere annee de donnees
        INTERVAL '1 day'
     ) AS jour;

-- IMPORTANT : la periode va du 1er janvier au 31 decembre, ANNEES CIVILES COMPLETES,
-- meme si les ventes s'arretent au 31 octobre 2026. Les fonctions de comparaison
-- annuelle de Power BI ont besoin d'annees entieres pour fonctionner.


-- =====================================================================================
-- VERIFICATION
-- =====================================================================================
SELECT COUNT(*)          AS nb_jours,
       MIN(date_jour)    AS premier_jour,
       MAX(date_jour)    AS dernier_jour,
       COUNT(DISTINCT mois_annee) AS nb_mois
FROM v_dim_calendrier;
-- Attendu : 730 jours (365 + 365), du 2025-01-01 au 2026-12-31, 24 mois.

SELECT mois_annee, mois_tri
FROM v_dim_calendrier
GROUP BY mois_annee, mois_tri
ORDER BY mois_tri
LIMIT 5;
-- Attendu : janv. 2025 (202501) / févr. 2025 (202502) / mars 2025 (202503) ...
