# Objectif

Transformer les fichiers exportés par Survey Solutions dans un format qui ressemble plus à la structure du questionnaire papier.

En particulier :

- Créer un fichier par section du questionnaire
- Créer un fichier par roster
- Créer des identifiants de roster du nom dicté part le questionnaire papier
- Ramener toutes les variables vers le cas minuscule
- Supprimer les variables non-nécessaires

# Installation

## Télécharger ce répositoire

- Cliquer sur le bouton `Clone or download`
- Cliquer sur l'option `Download ZIP`
- Télécharger dans le dossier sur votre machine où vous voulez héberger ce projet

## Paramétrage

```
/*-----------------------------------------------------------------------------
Paramètres du programme
-----------------------------------------------------------------------------*/

local proj_dir 	""
local fichier_principal "menage.dta"
local case_ids_vars "grappe id_menage vague"
local pays ""
local annee "2021"

```

# Emploi

- Lancer le programme
- Retrouver les résultats dans `/data/output/`