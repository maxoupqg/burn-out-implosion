class_name Miroir
extends Interactif

## Vider sa tête (§5). La soupape, et le seul verbe gratuit du jeu.
##
## Il est ici et pas au salon parce que la salle de bain est la pièce où l'on
## va le moins : décider de ne plus penser à quelque chose demande de s'être
## déplacé pour ça. C'est le même principe que Sam — le prix est dans le trajet.
##
## On ne choisit pas ce qu'on écarte. Le miroir prend ce qui pèse le plus, et
## le dit avant qu'on appuie : le joueur voit ce qu'il va lâcher, et peut
## repartir. C'est plus vrai qu'un menu, et ça évite un sélecteur (§13).

const COULEUR_ETEINT := Color(0.3, 0.34, 0.4)
const COULEUR_PRET := Color(0.62, 0.74, 0.82)
const COULEUR_BLOQUE := Color(1.0, 0.4, 0.35)

@onready var _glace: Polygon2D = $Glace


func disponible() -> bool:
	return Partie.peut_vider_tete()


func _executer() -> float:
	if not Partie.vider_tete():
		return -1.0
	# Gratuit, et il faut que ça le reste : une soupape qui coûte du temps est
	# fermée exactement le jour où l'on en a besoin. Le prix se paie dans deux
	# nuits, et il ne se négocie pas.
	return 0.0


func rafraichir() -> void:
	var fil := Partie.fil_a_ecarter()

	if fil == null:
		_glace.color = COULEUR_ETEINT
		_etiquette.modulate = COULEUR_BLOQUE
		_etiquette.text = "Miroir : rien à mettre de côté"
		return

	_glace.color = COULEUR_PRET
	_etiquette.modulate = Color(1, 1, 1)
	# Le verbe se dit à la première personne, et dans les mots où on se le dit
	# vraiment. « Vider sa tête » sonne comme du repos ; c'est le geste le plus
	# violent du jeu, et le seul qu'on s'adresse à soi-même dans une glace.
	#
	# La date de retour reste collée dessous : sans elle, on croit à un bouton
	# « supprimer » et on découvre la facture deux jours plus tard.
	_etiquette.text = "« j'm'en bats les couilles de %s »\nça revient %s, et en pire" % [
		fil.nom, Partie.nom_jour(Partie.jour + Partie.reglages.delai_retour)
	]
