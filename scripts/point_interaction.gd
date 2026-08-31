class_name PointInteraction
extends Interactif

## Le meuble qui porte une tâche. Les tâches vivent dans le monde (§10) :
## on ne les lit pas dans un menu, on va les chercher.

const COULEUR_ACTIF := Color(0.95, 0.55, 0.3)
const COULEUR_TROP_CHER := Color(1.0, 0.4, 0.35)

## La tâche que ce meuble porte. On y glisse un `.tres` de `donnees/taches/`.
@export var tache_def: TacheDef
@export var nom_meuble: String = "Meuble"

@onready var _pastille: Polygon2D = $Pastille


func tache() -> Tache:
	return Partie.taches.get(tache_def.id) if tache_def != null else null


func disponible() -> bool:
	return Partie.tache_active(tache())


func _executer() -> float:
	var cout := Partie.cout_reel(tache().cout_base)
	if not Partie.faire_tache(tache_def.id):
		return -1.0
	return cout


func rafraichir() -> void:
	var t := tache()

	if t == null or not disponible():
		_pastille.visible = false
		_etiquette.text = nom_meuble
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	var cout := Partie.cout_reel(t.cout_base)
	_pastille.visible = true
	_pastille.color = COULEUR_ACTIF
	_etiquette.text = "%s   %.1f" % [t.nom, cout]
	# Une tâche qu'on n'a plus les moyens de faire aujourd'hui.
	_etiquette.modulate = COULEUR_TROP_CHER if cout > Partie.temps_restant else Color(1, 1, 1)
