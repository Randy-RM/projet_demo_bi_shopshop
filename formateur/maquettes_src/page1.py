# -*- coding: utf-8 -*-
"""Maquette page 1 - Vue d'ensemble."""
import io, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import *
exec(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "donnees.py"),
             encoding="utf-8").read())

OUT = sys.argv[1]
c = Canvas()

M = 26
MOIS_COURT = {1:"janv.",2:"févr.",3:"mars",4:"avr.",5:"mai",6:"juin",
              7:"juil.",8:"août",9:"sept.",10:"oct.",11:"nov.",12:"déc."}

# ============================ EN-TETE =========================================
c.text(M, 22, "ShopShop", 27, "sb", RED)
wlogo = c.tw("ShopShop", 27, "sb")
c.text(M + wlogo + 10, 29, "—  Vue d'ensemble", 20, "l", INK)
c.text(M, 60, "Commandes livrées  ·  janv. 2025 – oct. 2026  ·  montants en USD",
       11.5, "r", MUTED)

c.rrect(1600 - M - 196, 26, 196, 24, 12, fill=fade(TEAL, .86))
c.text(1600 - M - 98, 32, "PAGE 1 / 2  ·  VUE D'ENSEMBLE", 9, "b", (36, 118, 110), anchor="ma")
c.text(1600 - M, 58, "Source : couche de présentation SQL · base shopshop",
       10.5, "r", MUTED, anchor="ra")

# ============================ SEGMENTS ========================================
sy = 94
c.text(M, sy + 7, "FILTRES", 9, "b", MUTED, spacing=1.2)
x = M + 78
c.text(x, sy + 7, "Année", 11, "sb", BODY); x += 48
for lab, on in (("2025", False), ("2026", True)):
    w = 56
    c.rrect(x, sy, w, 28, 14, fill=RED if on else CARD, outline=RED if on else BORDER)
    c.text(x + w / 2, sy + 6, lab, 11, "sb", CARD if on else BODY, anchor="ma")
    x += w + 8
x += 24
c.text(x, sy + 7, "Catégorie", 11, "sb", BODY); x += 68
c.rrect(x, sy, 210, 28, 14, fill=CARD, outline=BORDER)
c.text(x + 16, sy + 6, "Toutes les catégories", 11, "r", BODY)
c.d.polygon([(s(x + 184), s(sy + 12)), (s(x + 194), s(sy + 12)), (s(x + 189), s(sy + 18))],
            fill=MUTED)

c.text(1600 - M, sy + 7, "Date de référence : 31/10/2026", 10.5, "r", MUTED, anchor="ra")

# ============================ KPI =============================================
ky, kh, kw, gap = 142, 106, 375, 16
kpis = [
    ("Chiffre d'affaires livré", money(89012.69) + " $", "554 commandes livrées", RED),
    ("Marge brute",              money(29722.69) + " $", "après 59 290 $ de coût d'achat", CRIMSON),
    ("Taux de marge",            "33,4 %",               "sur le périmètre livré", TEAL),
    ("Taux d'annulation",        "11,0 %",               "71 commandes sur 648",  AMBER),
]
for i, (e, v, n, col) in enumerate(kpis):
    kpi(c, M + i * (kw + gap), ky, kw, kh, e, v, n, col)

# ============================ COURBE ==========================================
cx0, cy0, cw, ch = M, 264, 1048, 308
px, py, pw, ph = card(c, cx0, cy0, cw, ch, "Chiffre d'affaires par mois",
                      "visuel 2  ·  comparaison avec l'année précédente")

mois = D['mois']
vals = [v for _, v in mois]
n1 = [None] * 12 + [vals[i] for i in range(10)]          # N-1 : 2025-01..10 décalé sur 2026

step, top = 2000.0, 10000.0          # palier fixe : laisse de l'air au-dessus du pic
LX, LY = px + 54, py + 14
LW, LH = pw - 54, ph - 42

def X(i): return LX + i * (LW / (len(vals) - 1))
def Y(v): return LY + LH - (v / top) * LH

for k in range(6):
    v = step * k
    c.line([(LX, Y(v)), (LX + LW, Y(v))], GRID if k else BORDER, 1)
    c.text(LX - 12, Y(v) - 7, money(v), 10, "r", MUTED, anchor="ra")

pts = [(X(i), Y(v)) for i, v in enumerate(vals)]
c.fillpoly([(LX, Y(0))] + pts + [(X(len(vals) - 1), Y(0))], RED, 26)
c.line(pts, RED, 2.6)

n1pts = [(X(i), Y(v)) for i, v in enumerate(n1) if v is not None]
c.dash(n1pts, MUTED, 2, on=8, off=6)

for i, v in enumerate(vals):
    c.dot(X(i), Y(v), 3.2, CARD, RED, 2)

# pic d'août 2026
ipk = vals.index(max(vals))
c.dot(X(ipk), Y(vals[ipk]), 5.5, RED, CARD, 2)
lab = money(vals[ipk]) + " $"
lw = c.tw(lab, 10.5, "sb") + 20
c.rrect(X(ipk) - lw / 2, Y(vals[ipk]) - 34, lw, 23, 11, fill=RED)
c.text(X(ipk), Y(vals[ipk]) - 30, lab, 10.5, "sb", CARD, anchor="ma")

for i in range(0, len(vals), 3):
    a, m = mois[i][0].split("-")
    c.text(X(i), LY + LH + 12, MOIS_COURT[int(m)] + " " + a[2:], 10, "r", MUTED, anchor="ma")

lx, ly = LX + 16, LY + 8
c.line([(lx, ly + 8), (lx + 22, ly + 8)], RED, 2.6)
c.text(lx + 29, ly, "CA livré", 10.5, "sb", BODY)
lx2 = lx + 29 + c.tw("CA livré", 10.5, "sb") + 20
c.dash([(lx2, ly + 8), (lx2 + 22, ly + 8)], MUTED, 2, on=6, off=4)
c.text(lx2 + 29, ly, "CA livré N-1", 10.5, "r", MUTED)

# ============================ ANNEAU ==========================================
dx0 = M + cw + gap
px, py, pw, ph = card(c, dx0, cy0, 1600 - M - dx0, ch, "Répartition par canal de vente",
                      "visuel 4")

canaux = D['canaux']
tot = sum(v for _, v in canaux)
ccx, ccy, rr, rw = px + 108, py + 112, 92, 30
cols = [RED, TEAL, AMBER]
ang = -90.0
for (lab, v), col in zip(canaux, cols):
    sweep = v / tot * 360
    c.arc(ccx, ccy, rr, rw, ang + 1.4, ang + sweep - 1.4, col)
    ang += sweep
c.text(ccx, ccy - 20, money(tot), 20, "sb", INK, anchor="ma")
c.text(ccx, ccy + 8, "USD livrés", 10.5, "r", MUTED, anchor="ma")

ly = py + 42
for (lab, v), col in zip(canaux, cols):
    lx = px + 228
    c.rrect(lx, ly + 4, 11, 11, 3, fill=col)
    c.text(lx + 22, ly, lab, 12, "sb", INK)
    c.text(lx + 22, ly + 20, money(v) + " $", 11.5, "r", BODY)
    c.text(px + pw, ly + 6, "{:.1f} %".format(v / tot * 100).replace(".", ","),
           14, "sb", col, anchor="ra")
    ly += 52

c.rrect(px, py + ph - 34, pw, 34, 6, fill=SOFT)
c.text(px + 14, py + ph - 26, "La boutique physique reste le premier canal (45 %).",
       10.5, "r", BODY)

# ============================ CATEGORIES ======================================
by, bh = 586, 288
px, py, pw, ph = card(c, M, by, 766, bh, "CA par catégorie",
                      "visuel 3  ·  trié par CA décroissant")

cats = D['categories']
mx = max(v for _, v, _, _, _ in cats)
rowh = ph / len(cats)
bx = px + 176
bw = pw - 176 - 92
for i, (nom, ca, marge, taux, qte) in enumerate(cats):
    yy = py + i * rowh + rowh / 2
    c.text(px + 162, yy - 15, nom, 11.5, "sb", INK, anchor="ra")
    c.text(px + 162, yy + 2, "{} art. · marge {} %".format(qte, str(taux).replace(".", ",")),
           9.5, "r", MUTED, anchor="ra")
    L = bw * ca / mx
    c.rrect(bx, yy - 13, bw, 26, 5, fill=(250, 251, 252))
    c.rrect(bx, yy - 13, max(L, 6), 26, 5, fill=fade(RED, i * 0.13))
    c.text(bx + L + 12, yy - 9, money(ca) + " $", 11.5, "sb", INK)

# ============================ VILLES ==========================================
vx0 = M + 766 + gap
px, py, pw, ph = card(c, vx0, by, 1600 - M - vx0, bh, "CA par ville",
                      "visuel 5  ·  7 villes après nettoyage")

villes = D['villes']
mx = max(v for _, v in villes)
base = py + ph - 26
htop = ph - 52
bw2 = 60
gapv = (pw - len(villes) * bw2) / (len(villes) + 1)
for i, (nom, v) in enumerate(villes):
    x = px + gapv + i * (bw2 + gapv)
    hh = max(htop * v / mx, 8)
    c.rrect(x, base - hh, bw2, hh, 5, fill=fade(TEAL, i * 0.11))
    c.text(x + bw2 / 2, base - hh - 19, money(v), 10.5, "sb", INK, anchor="ma")
    c.text(x + bw2 / 2, base + 7, nom, 10, "r", BODY, anchor="ma")
c.line([(px, base), (px + pw, base)], BORDER, 1)

# ============================ PIED ============================================
c.text(M, 878, "Maquette pédagogique — résultat attendu avec les règles R1 à R5.  "
               "Les chiffres affichés sont les valeurs de contrôle du projet.",
       10, "r", MUTED)
c.text(1600 - M, 878, "Projet BI · Formation Data Analyst", 10, "r", MUTED, anchor="ra")

c.save(OUT)
print("OK", OUT)
