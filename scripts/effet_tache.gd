class_name EffetTache
extends Resource

## Ce qu'une tâche laisse derrière elle, en dehors de son propre fil (§3).
##
## Une tâche faite change le monde ailleurs que sur son meuble : faire à manger
## met un repas sur la table, débarrasser l'enlève. Ces conséquences ne sont pas
## écrites dans `partie.gd` — elles se glissent dans la liste `effets` du `.tres`
## de la tâche, comme on y glisse déjà son fil et son prérequis.
##
## C'est une classe de base vide exprès : ajouter une famille de conséquence, ce
## sera écrire une sous-classe ici, et pas rouvrir la boucle qui résout les
## tâches. `Partie` ne saura jamais ce qu'un effet fait, seulement qu'il en
## existe un et qu'il faut l'appliquer.

## Appliquée une fois, au moment où la tâche cesse d'être à faire — qu'on l'ait
## faite soi-même ou passée à quelqu'un d'autre.
func appliquer() -> void:
	pass


## Ce que le meuble annonce avant qu'on appuie, s'il y a quelque chose à dire.
## Vide par défaut : un effet qui ne se voit pas ne se raconte pas non plus.
func annonce() -> String:
	return ""
