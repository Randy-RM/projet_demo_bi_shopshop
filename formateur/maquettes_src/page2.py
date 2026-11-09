# -*- coding: utf-8 -*-
"""Maquette page 2 - Produits & clients."""
import io, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import *
exec(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "donnees.py"),
             encoding="utf-8").read())

OUT = sys.argv[1]
c = Canvas()
M = 26

def taux_color(t):
    return RED if t < 25 else (AMBER if t < 40 else TEAL)

def chip(x, y, w, h, txt, col, size=10):
    c.rrect(x, y, w, h, h / 2, fill=fade(col, .84))
    c.text(x + w / 2, y + (h - size * 1.45) / 2, txt, size, "b",
           mix(col, (0, 0, 0), .25), anchor="ma")

def tri(x, y, col, open_=False):
    if open_:
        c.d.polygon([(s(x), s(y)), (s(x + 9), s(y)), (s(x + 4.5), s(y + 6))], fill=col)
    else:
        c.d.polygon([(s(x + 1), s(y - 1)), (s(x + 7), s(y + 3.5)), (s(x + 1), s(y + 8))], fill=col)

# ============================ EN-TETE =========================================
c.text(M, 22, "ShopShop", 27, "sb", RED)
wlogo = c.tw("ShopShop", 27, "sb")
c.text(M + wlogo + 10, 29, "—  Produits & clients", 20, "l", INK)
c.text(M, 60, "Commandes livrées  ·  janv. 2025 – oct. 2026  ·  montants en USD",
       11.5, "r", MUTED)

c.rrect(1600 - M - 212, 26, 212, 24, 12, fill=fade(TEAL, .86))
c.text(1600 - M - 106, 32, "PAGE 2 / 2  ·  PRODUITS & CLIENTS", 9, "b", (36, 118, 110), anchor="ma")
c.text(1600 - M, 58, "Source : couche de présentation SQL · base shopshop",
       10.5, "r", MUTED, anchor="ra")

# ============================ SEGMENTS ========================================
sy = 94
c.text(M, sy + 7, "FILTRES", 9, "b", MUTED, spacing=1.2)
x = M + 78
c.text(x, sy + 7, "Catégorie", 11, "sb", BODY); x += 68
c.rrect(x, sy, 210, 28, 14, fill=CARD, outline=BORDER)
c.text(x + 16, sy + 6, "Toutes les catégories", 11, "r", BODY)
c.d.polygon([(s(x + 184), s(sy + 12)), (s(x + 194), s(sy + 12)), (s(x + 189), s(sy + 18))], fill=MUTED)
x += 234
c.text(x, sy + 7, "Canal", 11, "sb", BODY); x += 44
for lab, on in (("Boutique", False), ("En ligne", False), ("Mobile Money", False)):
    w = c.tw(lab, 11, "r") + 28
    c.rrect(x, sy, w, 28, 14, fill=CARD, outline=BORDER)
    c.text(x + w / 2, sy + 6, lab, 11, "r", BODY, anchor="ma")
    x += w + 8
c.text(1600 - M, sy + 7, "Date de référence : 31/10/2026", 10.5, "r", MUTED, anchor="ra")

# ============================ TOP 10 PRODUITS =================================
r1y, r1h = 142, 310
px, py, pw, ph = card(c, M, r1y, 790, r1h, "Top 10 des produits par chiffre d'affaires",
                      "visuel 6  ·  chip = taux de marge")

prod = D['top_produits']
mx = max(v for _, v, _, _, _ in prod)
rowh = ph / len(prod)
bx = px + 192
bw = pw - 192 - 78 - 74
for i, (nom, ca, marge, taux, qte) in enumerate(prod):
    yy = py + i * rowh + rowh / 2
    nm = nom if c.tw(nom, 10.5, "r") < 180 else nom[:24] + "…"
    c.text(px + 180, yy - 7, nm, 10.5, "r", BODY, anchor="ra")
    L = bw * ca / mx
    c.rrect(bx, yy - 9, max(L, 5), 18, 4, fill=fade(RED, i * 0.065))
    c.text(bx + bw + 68, yy - 7, money(ca) + " $", 10.5, "sb", INK, anchor="ra")
    chip(px + pw - 66, yy - 9, 66, 18, "{} %".format(str(taux).replace(".", ",")), taux_color(taux), 9.5)

# ============================ TOP 10 CLIENTS ==================================
c2x = M + 790 + 16
px, py, pw, ph = card(c, c2x, r1y, 1600 - M - c2x, r1h, "Top 10 des clients par chiffre d'affaires",
                      "visuel 8  ·  46 % du CA total")

cli = D['top_clients']
mx = max(v for _, _, v, _, _ in cli)
rowh = ph / len(cli)
bx = px + 212
bw = pw - 212 - 96
for i, (nom, ville, ca, nb, rec) in enumerate(cli):
    yy = py + i * rowh + rowh / 2
    c.text(px + 196, yy - 12, nom, 10.5, "sb", INK, anchor="ra")
    c.text(px + 196, yy + 2, "{} · {} cmd".format(ville, nb), 9, "r", MUTED, anchor="ra")
    L = bw * ca / mx
    c.rrect(bx, yy - 9, max(L, 5), 18, 4, fill=fade(TEAL, i * 0.065))
    c.text(px + pw, yy - 7, money(ca) + " $", 10.5, "sb", INK, anchor="ra")

# ============================ BANDEAU LECTURE =================================
byn = r1y + r1h + 12
c.rrect(M, byn, 1600 - 2 * M, 38, 8, fill=(253, 246, 234), outline=fade(AMBER, .55))
c.rrect(M, byn + 8, 4, 22, 2, fill=AMBER)
c.text(M + 20, byn + 11, "CE QUE LE DASHBOARD DOIT FAIRE VOIR :", 10, "b", mix(AMBER, (0, 0, 0), .35))
wlab = c.tw("CE QUE LE DASHBOARD DOIT FAIRE VOIR :", 10, "b")
c.text(M + 28 + wlab, byn + 11,
       "les 4 produits qui font le plus de chiffre d'affaires sont exactement les 4 moins "
       "rentables en taux de marge.  Ce qui fait le volume n'est pas ce qui rapporte.",
       11, "r", BODY)

# ============================ MATRICE =========================================
r2y = byn + 50
r2h = 876 - r2y
px, py, pw, ph = card(c, M, r2y, 940, r2h, "Rentabilité par catégorie et par produit",
                      "visuel 7  ·  mise en forme conditionnelle sur le taux de marge")

HY = py + 2                      # ligne d'en-tetes, sous le titre de la carte
py, ph = py + 30, ph - 30        # la zone de lignes commence en dessous
COLQ, COLCA, COLMG, COLTX = px + 470, px + 610, px + 740, px + pw
c.text(px, HY, "CATÉGORIE  ›  PRODUIT", 8.5, "b", MUTED, spacing=.6)
for lab, cx in (("QUANTITÉ", COLQ), ("CA LIVRÉ", COLCA), ("MARGE", COLMG)):
    c.text(cx, HY, lab, 8.5, "b", MUTED, spacing=.6, anchor="ra")
c.text(COLTX, HY, "TAUX DE MARGE", 8.5, "b", MUTED, spacing=.6, anchor="ra")
c.line([(px, HY + 20), (px + pw, HY + 20)], BORDER, 1)

cats = {n: (ca, mg, tx, q) for n, ca, mg, tx, q in D['categories']}
detail = [p for p in D['produits_par_cat'] if p[0] == 'Téléphonie & Accessoires'][:4]
rows = []
for nom, ca, mg, tx, q in D['categories']:
    rows.append(("cat", nom, q, ca, mg, tx))
    if nom == 'Téléphonie & Accessoires':
        for _, pn, pca, pmg, ptx, pq in detail:
            rows.append(("prod", pn, pq, pca, pmg, ptx))

rh = (ph - 34) / len(rows)
for i, (kind, nom, q, ca, mg, tx) in enumerate(rows):
    yy = py + 4 + i * rh
    if kind == "cat":
        c.rect(px, yy, pw, rh - 1, fill=(250, 251, 252))
        tri(px + 4, yy + rh / 2 - 3, MUTED, open_=(nom == 'Téléphonie & Accessoires'))
        c.text(px + 20, yy + rh / 2 - 8, nom, 11, "sb", INK)
    else:
        c.text(px + 40, yy + rh / 2 - 8, nom, 10.5, "r", BODY)
    w = "sb" if kind == "cat" else "r"
    c.text(COLQ, yy + rh / 2 - 8, money(q), 10.5, w, INK if kind == "cat" else BODY, anchor="ra")
    c.text(COLCA, yy + rh / 2 - 8, money(ca) + " $", 10.5, w, INK if kind == "cat" else BODY, anchor="ra")
    c.text(COLMG, yy + rh / 2 - 8, money(mg) + " $", 10.5, w, INK if kind == "cat" else BODY, anchor="ra")
    # barre de donnees conditionnelle
    bx2, bw2 = COLMG + 24, COLTX - COLMG - 24 - 58
    col = taux_color(tx)
    c.rrect(bx2, yy + rh / 2 - 9, bw2, 18, 4, fill=(250, 251, 252))
    c.rrect(bx2, yy + rh / 2 - 9, max(bw2 * tx / 80.0, 5), 18, 4, fill=fade(col, .62))
    c.text(COLTX, yy + rh / 2 - 7, "{} %".format(str(tx).replace(".", ",")), 10, "b",
           mix(col, (0, 0, 0), .3), anchor="ra")
    c.line([(px, yy + rh - 1), (px + pw, yy + rh - 1)], (244, 245, 247), 1)

yy = py + 4 + len(rows) * rh
c.line([(px, yy), (px + pw, yy)], BORDER, 1)
c.text(px + 20, yy + 10, "Total", 11.5, "b", RED)
c.text(COLQ, yy + 10, money(1964), 11.5, "b", RED, anchor="ra")
c.text(COLCA, yy + 10, money(89012.69) + " $", 11.5, "b", RED, anchor="ra")
c.text(COLMG, yy + 10, money(29722.69) + " $", 11.5, "b", RED, anchor="ra")
c.text(COLTX, yy + 10, "33,4 %", 11.5, "b", RED, anchor="ra")

# ============================ CLIENTS DORMANTS ================================
c4x = M + 940 + 16
px, py, pw, ph = card(c, c4x, r2y, 1600 - M - c4x, r2h, "Clients — ancienneté du dernier achat",
                      "visuel 9")

HY = py + 2
py, ph = py + 30, ph - 30
CC, CV, CN, CA_, CR = px, px + 196, px + 268, px + 384, px + pw
c.text(CC, HY, "CLIENT", 8.5, "b", MUTED, spacing=.6)
c.text(CV, HY, "VILLE", 8.5, "b", MUTED, spacing=.6)
c.text(CN, HY, "CMD", 8.5, "b", MUTED, spacing=.6, anchor="ra")
c.text(CA_, HY, "CA LIVRÉ", 8.5, "b", MUTED, spacing=.6, anchor="ra")
c.text(CR, HY, "DERNIER ACHAT", 8.5, "b", MUTED, spacing=.6, anchor="ra")
c.line([(px, HY + 20), (px + pw, HY + 20)], BORDER, 1)

dorm = D['clients_dormants']
rh = (ph - 44) / len(dorm)
for i, (nom, ville, ca, nb, rec) in enumerate(dorm):
    yy = py + 4 + i * rh
    if i % 2 == 0:
        c.rect(px, yy, pw, rh - 1, fill=(250, 251, 252))
    c.text(CC, yy + rh / 2 - 8, nom, 10.5, "sb", INK)
    c.text(CV, yy + rh / 2 - 8, ville, 10.5, "r", BODY)
    c.text(CN, yy + rh / 2 - 8, str(nb), 10.5, "r", BODY, anchor="ra")
    c.text(CA_, yy + rh / 2 - 8, money(ca) + " $", 10.5, "r", BODY, anchor="ra")
    col = RED if rec > 180 else (AMBER if rec > 90 else TEAL)
    chip(CR - 74, yy + rh / 2 - 9, 74, 18, "{} jours".format(rec), col, 9.5)

c.rrect(px, py + ph - 36, pw, 36, 6, fill=SOFT)
c.text(px + 14, py + ph - 27,
       "8 clients n'ont plus rien acheté depuis plus de 8 mois.", 10.5, "r", BODY)

# ============================ PIED ============================================
c.text(M, 878, "Maquette pédagogique — résultat attendu avec les règles R1 à R5.  "
               "Les chiffres affichés sont les valeurs de contrôle du projet.", 10, "r", MUTED)
c.text(1600 - M, 878, "Projet BI · Formation Data Analyst", 10, "r", MUTED, anchor="ra")

c.save(OUT)
print("OK", OUT)
