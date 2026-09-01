class_name Relance
extends RefCounted

## Ce qu'il reste d'une tâche déléguée (§4). Déléguer ne fait pas disparaître
## le travail de la tête : ça le transforme en « il faut que je pense à lui
## redemander ». C'est la charge mentale à l'état pur — le travail est parti,
## la charge est restée.
##
## Elle ne vit pas sur un meuble mais sur la personne à qui on a délégué : la
## relance se paie en déplacement, pas seulement en temps.

## La tâche qu'on a passée à quelqu'un d'autre. On garde l'objet plutôt que son
## identifiant : le fil et le nom s'en déduisent, et ils resteront justes.
var tache: Tache

## Premier jour où l'on peut — et doit — relancer. Pas le jour même : on ne
## court pas derrière quelqu'un dans l'heure qui suit. C'est ce décalage qui
## fait de la délégation un emprunt et pas un cadeau.
var due_le: int = 1


func due(jour: int) -> bool:
	return jour >= due_le
