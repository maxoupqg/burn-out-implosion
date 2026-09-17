class_name Interactif
extends Area2D

## Base commune aux choses du monde avec lesquelles on interagit.
##
## Toute action coûte du temps, et ce temps se voit : la barre met
## `coût réel × SECONDES_PAR_UNITE` à se remplir. C'est là que le
## multiplicateur cesse d'être un chiffre pour devenir une attente.

const SECONDES_PAR_UNITE := 0.55

var occupe: bool = false

var _duree: float = 0.0
var _ecoule: float = 0.0

@onready var _etiquette: Label = $Etiquette
@onready var _barre: ProgressBar = $Barre


func _ready() -> void:
	Partie.fils_change.connect(rafraichir)
	Partie.taches_change.connect(rafraichir)
	Partie.besoins_change.connect(rafraichir)
	Partie.temps_change.connect(func(_restant: float) -> void: rafraichir())
	Partie.jour_change.connect(func(_j: int) -> void: rafraichir())
	_barre.visible = false
	rafraichir()


## Y a-t-il quelque chose à faire ici, maintenant ?
func disponible() -> bool:
	return false


## Y a-t-il quelque chose à déléguer ici (§4) ? Presque rien : on ne délègue
## pas un canapé, ni un dispositif, ni un fil ramassé par terre. Seul le meuble
## qui porte une tâche répond oui.
func delegable() -> bool:
	return false


## Exécute et paie l'action. Renvoie le coût réel en unités de temps,
## ou -1 si l'action n'a pas pu être payée.
func _executer() -> float:
	return -1.0


## Même contrat, pour le second verbe.
func _deleguer() -> float:
	return -1.0


func rafraichir() -> void:
	pass


func lancer(en_deleguant: bool = false) -> bool:
	if occupe:
		return false
	if not (delegable() if en_deleguant else disponible()):
		return false

	var cout := _deleguer() if en_deleguant else _executer()
	if cout < 0.0:
		return false

	occupe = true
	_duree = maxf(0.2, cout * SECONDES_PAR_UNITE)
	_ecoule = 0.0
	_barre.value = 0.0
	_barre.visible = true
	return true


func _process(delta: float) -> void:
	if not occupe:
		return

	_ecoule += delta
	_barre.value = clampf(_ecoule / _duree, 0.0, 1.0) * 100.0

	if _ecoule >= _duree:
		occupe = false
		_barre.visible = false
		rafraichir()
