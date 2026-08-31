class_name Canape
extends Interactif

## S'asseoir (§11). L'action la plus chère du jeu et la seule qui ne produit
## rien — c'est exactement ce qui en fait la victoire.
##
## Il ne suffit pas d'avoir du temps : il faut une case vide dans la tête. On
## ne se repose pas en pensant à autre chose.

const COULEUR_LIBRE := Color(0.42, 0.36, 0.44)
const COULEUR_PRET := Color(0.55, 0.78, 0.6)
const COULEUR_BLOQUE := Color(1.0, 0.4, 0.35)

@onready var _assise: Polygon2D = $Assise


func disponible() -> bool:
	return Partie.peut_sasseoir()


func _executer() -> float:
	var cout := Partie.cout_reel(Partie.COUT_ASSIS)
	if not Partie.sasseoir():
		return -1.0
	return cout


func rafraichir() -> void:
	if disponible():
		# On ne rafraîchit que si le canapé est chargé, donc si le joueur est
		# au salon. Le vert vu ici est une occasion réellement offerte.
		Partie.signaler_canape_libre()
		_assise.color = COULEUR_PRET
		_etiquette.text = "Canapé : s'asseoir   %.1f" % Partie.cout_reel(Partie.COUT_ASSIS)
		_etiquette.modulate = Color(1, 1, 1)
		return

	_assise.color = COULEUR_LIBRE
	_etiquette.modulate = COULEUR_BLOQUE
	if Partie.cases_libres() == 0:
		_etiquette.text = "Canapé : la tête est pleine"
	else:
		_etiquette.text = "Canapé : pas assez de temps"
