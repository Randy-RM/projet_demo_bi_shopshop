# -*- coding: utf-8 -*-
"""
Regenere les deux maquettes PNG du dashboard ShopShop.

    python generer.py

Ce script :
  1. relit sql/02_charger_les_donnees.sql et recalcule TOUS les agregats
     (regles R1 a R5 du brief) dans une base SQLite en memoire ;
  2. ecrit donnees.py, le jeu de chiffres utilise par les maquettes ;
  3. rend ressources/maquettes/page1_vue_ensemble.png et page2_produits_clients.png.

Les maquettes ne contiennent donc AUCUN chiffre saisi a la main : elles sont
recalculees depuis les donnees du projet, comme le reste du corrige.

Prerequis : Python 3 + Pillow  (pip install pillow)
Polices    : Segoe UI (presente par defaut sur Windows)
"""
import io, os, re, sqlite3, subprocess, sys, pprint

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.abspath(os.path.join(ICI, "..", ".."))
DATA = os.path.join(RACINE, "sql", "02_charger_les_donnees.sql")
SORTIE = os.path.join(RACINE, "ressources", "maquettes")

DDL = """
CREATE TABLE clients (id_client INTEGER PRIMARY KEY, nom TEXT, ville TEXT, province TEXT, date_inscription TEXT);
CREATE TABLE categories (id_categorie INTEGER PRIMARY KEY, nom_categorie TEXT);
CREATE TABLE produits (id_produit INTEGER PRIMARY KEY, nom_produit TEXT, id_categorie INT, prix_vente REAL, cout_achat REAL);
CREATE TABLE commandes (id_commande INTEGER PRIMARY KEY, id_client INT, date_commande TEXT, statut TEXT, canal TEXT, montant REAL);
CREATE TABLE lignes_commande (id_ligne INTEGER PRIMARY KEY, id_commande INT, id_produit INT, quantite INT, remise_appliquee REAL);
"""

def initcap(s):
    out, up = [], True
    for ch in (s or ""):
        if ch.isalnum():
            out.append(ch.upper() if up else ch.lower()); up = False
        else:
            out.append(ch); up = True
    return "".join(out)

def extraire():
    con = sqlite3.connect(":memory:")
    con.executescript(DDL)
    sql = io.open(DATA, encoding="utf-8").read()
    for stmt in re.findall(r"INSERT INTO .*?;", sql, flags=re.S):
        con.executescript(stmt)
    con.create_function("initcap", 1, initcap)

    CA   = "lc.quantite*p.prix_vente-COALESCE(lc.remise_appliquee,0)"   # regle R3
    COUT = "lc.quantite*p.cout_achat"                                   # regle R4
    J = ("FROM lignes_commande lc JOIN produits p ON p.id_produit=lc.id_produit "
         "JOIN commandes c ON c.id_commande=lc.id_commande")
    W = "WHERE c.statut='livrée'"                                       # regle R2
    REF = "'2026-10-31'"                                                # regle R5

    d = {}
    d['mois'] = [(r[0], round(r[1], 2)) for r in con.execute(
        "SELECT substr(c.date_commande,1,7), SUM(%s) %s %s GROUP BY 1 ORDER BY 1" % (CA, J, W))]
    d['categories'] = [(r[0], round(r[1], 2), round(r[2], 2), round(100 * r[2] / r[1], 1), r[3])
                       for r in con.execute(
        """SELECT cat.nom_categorie, SUM(%s), SUM(%s)-SUM(%s), SUM(lc.quantite)
           %s JOIN categories cat ON cat.id_categorie=p.id_categorie %s
           GROUP BY 1 ORDER BY 2 DESC""" % (CA, CA, COUT, J, W))]
    d['canaux'] = [(r[0], round(r[1], 2)) for r in con.execute(
        "SELECT c.canal, SUM(%s) %s %s GROUP BY 1 ORDER BY 2 DESC" % (CA, J, W))]
    d['villes'] = [(r[0], round(r[1], 2)) for r in con.execute(
        """SELECT initcap(TRIM(cl.ville)), SUM(%s) %s JOIN clients cl ON cl.id_client=c.id_client %s
           GROUP BY 1 ORDER BY 2 DESC""" % (CA, J, W))]
    d['top_produits'] = [(r[0], round(r[1], 2), round(r[2], 2), round(100 * r[2] / r[1], 1), r[3])
                         for r in con.execute(
        """SELECT p.nom_produit, SUM(%s), SUM(%s)-SUM(%s), SUM(lc.quantite)
           %s %s GROUP BY p.id_produit ORDER BY 2 DESC LIMIT 10""" % (CA, CA, COUT, J, W))]
    d['produits_par_cat'] = [(r[0], r[1], round(r[2], 2), round(r[3], 2),
                              round(100 * r[3] / r[2], 1), r[4]) for r in con.execute(
        """SELECT cat.nom_categorie, p.nom_produit, SUM(%s), SUM(%s)-SUM(%s), SUM(lc.quantite)
           %s JOIN categories cat ON cat.id_categorie=p.id_categorie %s
           GROUP BY p.id_produit ORDER BY cat.nom_categorie, 3 DESC""" % (CA, CA, COUT, J, W))]
    d['top_clients'] = [(r[0], r[1], round(r[2], 2), r[3], r[4]) for r in con.execute(
        """SELECT cl.nom, initcap(TRIM(cl.ville)), SUM(%s), COUNT(DISTINCT c.id_commande),
                  CAST(julianday(%s)-julianday(MAX(c.date_commande)) AS INT)
           %s JOIN clients cl ON cl.id_client=c.id_client %s
           GROUP BY cl.id_client ORDER BY 3 DESC LIMIT 10""" % (CA, REF, J, W))]
    d['clients_dormants'] = [(r[0], r[1], round(r[2], 2), r[3], r[4]) for r in con.execute(
        """SELECT cl.nom, initcap(TRIM(cl.ville)), SUM(%s), COUNT(DISTINCT c.id_commande),
                  CAST(julianday(%s)-julianday(MAX(c.date_commande)) AS INT)
           %s JOIN clients cl ON cl.id_client=c.id_client %s
           GROUP BY cl.id_client ORDER BY 5 DESC LIMIT 8""" % (CA, REF, J, W))]

    # garde-fou : la maquette ne doit jamais afficher un chiffre faux
    ca_total = round(sum(v for _, v in d['mois']), 2)
    assert ca_total == 89012.69, "CA recalcule = %s (attendu 89 012,69)" % ca_total
    assert len(d['villes']) == 7, "villes = %d (attendu 7)" % len(d['villes'])

    io.open(os.path.join(ICI, "donnees.py"), "w", encoding="utf-8").write(
        "# -*- coding: utf-8 -*-\n# Fichier genere par generer.py - ne pas editer a la main.\nD = "
        + pprint.pformat(d, width=120) + "\n")
    print("  donnees.py ecrit   CA de controle = 89 012,69 USD  OK")

def rendre():
    if not os.path.isdir(SORTIE):
        os.makedirs(SORTIE)
    for script, nom in (("page1.py", "page1_vue_ensemble.png"),
                        ("page2.py", "page2_produits_clients.png")):
        subprocess.check_call([sys.executable, os.path.join(ICI, script),
                               os.path.join(SORTIE, nom)])

if __name__ == "__main__":
    print("1/2  extraction des chiffres depuis sql/02_charger_les_donnees.sql")
    extraire()
    print("2/2  rendu des maquettes")
    rendre()
    print("\nTermine. Images dans ressources/maquettes/")
