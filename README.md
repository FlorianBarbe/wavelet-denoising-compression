# Transformée discrète en ondelettes — TP ARSIG

Étude de la DWT avec MATLAB : construction de fonctions d’échelle et d’ondelettes, débruitage de signaux 1D et compression d’images par sélection des coefficients.

Travail réalisé dans le cadre de l’option DATASIM à Centrale Nantes.

**Auteurs : Florian Barbe et Hugo Agostin.**

[Lire le compte rendu](compte_rendu_DWT_etat_actuel.pdf) · [Source LaTeX](compte_rendu_DWT_etat_actuel.tex)

## Contenu

- `scripts/TPHaar.m` : fonctions d’échelle et ondelettes de Haar et Daubechies 4, puis débruitage de Blocks et Doppler.
- `scripts/TPimage.m` : compression de `cameraman.tif` avec les deux filtres et comparaison des reconstructions.
- `scripts/ajoute_bruit.m` : ajout de bruit blanc gaussien.
- `figures/` : figures PNG utilisées dans le rapport et dans cette page.

Organisation attendue pour l’exécution :

```text
TP_DWT/
├── README.md
├── scripts/
│   ├── TPHaar.m
│   ├── TPimage.m
│   ├── ajoute_bruit.m
│   ├── blocks.mat
│   ├── Doppler.mat
│   ├── cameraman.tif
│   └── WaveLab802_datasim2026/
├── figures/
├── compte_rendu_DWT_etat_actuel.tex
└── compte_rendu_DWT_etat_actuel.pdf
```

## Exécution

Prérequis : MATLAB, Image Processing Toolbox pour `im2double`, et la version pédagogique `WaveLab802_datasim2026`. Les exports fournis ont été produits avec MATLAB R2025b.

Placer le dossier WaveLab complet dans `scripts/`, comme dans l’arborescence ci-dessus. Les fonctions `DWT_datasim`, `DWTinv_datasim`, `DWT2_datasim`, `DWT2inv_datasim`, `plot_dwt` et `im_dwt2` sont des ajouts pédagogiques à WaveLab : une distribution standard seule ne suffit pas nécessairement.

Dans MATLAB, depuis le dossier `TP_DWT`, lancer le premier script :

```matlab
run(fullfile('scripts','TPHaar.m'));
```

Puis, après avoir consulté les figures, lancer le second :

```matlab
run(fullfile('scripts','TPimage.m'));
```

Les scripts affichent les figures sans exporter de fichiers automatiquement. Chaque script commence par `close all` : lancer le second ferme donc les fenêtres du premier.

## Fonctions d’échelle et ondelettes

La DWT inverse d’un vecteur contenant un seul coefficient non nul permet de reconstruire une fonction de la base. Un coefficient d’approximation produit une fonction d’échelle ; un coefficient de détail produit une ondelette.

![Fonction d’échelle et ondelette de Daubechies 4, obtenues par DWT inverse](figures/TPHaar_03.png)

## Débruitage de Blocks et Doppler

Pour chaque signal, la même réalisation du bruit est utilisée avec les deux filtres, à un SNR de 10 dB. Les coefficients faibles sont supprimés par seuillage dur, puis le signal est reconstruit par DWT inverse.

Le seuil universel de Donoho–Johnstone est `sigma_b * sqrt(2*log(N))`. Une estimation de `sigma_b` par MAD sur les détails fins permet aussi de calculer un seuil statistique à partir du seul signal bruité.

La recherche du meilleur seuil parcourt une grille allant de zéro à deux fois le seuil estimé par MAD. Cette limite est un choix pratique, pas une garantie théorique. Le seuil « optimal » désigne le minimum sur la grille testée ; sa sélection utilise le signal propre connu en simulation.

| Signal | Ondelette | Erreur au seuil optimal | Erreur au seuil DJ |
|---|---|---:|---:|
| Blocks | Haar | 12,52 % | 12,83 % |
| Blocks | Daubechies 4 | 15,56 % | 18,40 % |
| Doppler | Haar | 24,34 % | 29,79 % |
| Doppler | Daubechies 4 | 18,20 % | 20,26 % |

Ces valeurs correspondent aux réalisations illustrées ci-dessous. Haar convient mieux aux plateaux de Blocks ; Daubechies 4 représente mieux les oscillations de Doppler.

![Comparaison des reconstructions du signal Blocks](figures/TPHaar_13.png)

![Comparaison des reconstructions du signal Doppler](figures/TPHaar_14.png)

![Erreurs relatives superposées et seuils repérés pour les deux signaux](figures/TPHaar_15.png)

## Compression d’images

La DWT 2D est calculée sur quatre niveaux. Pour chaque pourcentage choisi, seuls les plus grands coefficients en valeur absolue sont conservés, à leur position d’origine.

![Daubechies 4 : reconstructions à 1, 5 et 25 % de coefficients conservés et images d’erreur absolue](figures/TPimage_07.png)

![Comparaison des erreurs de compression avec Haar et Daubechies 4](figures/TPimage_05.png)

Les deux filtres donnent des erreurs proches, sans avantage systématique pour l’un d’eux. Le pourcentage de coefficients conservés n’est pas un rapport de taille de fichier mesuré : le stockage des positions et le codage ne sont pas pris en compte.

## Références et dépendances

- D. L. Donoho et I. M. Johnstone, *Ideal spatial adaptation by wavelet shrinkage*, Biometrika, 81(3), 425–455, 1994. [DOI](https://doi.org/10.1093/biomet/81.3.425). Le seuil universel et l’estimation du bruit par MAD sont discutés p. 444–446.
- MathWorks, [`wnoisest`](https://www.mathworks.com/help/wavelet/ref/wnoisest.html), documentation de l’estimation du bruit par MAD.
- WaveLab 802 et ajouts pédagogiques DATASIM : conserver les mentions d’origine et les conditions de redistribution de la bibliothèque, notamment `Documentation/COPYING.m` et `Documentation/THANKS.m`.

Le sujet de TP, la bibliothèque, ses adaptations et les données tierces ne doivent pas être présentés comme des créations originales des auteurs du compte rendu.
