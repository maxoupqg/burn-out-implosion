class_name FilAuSol
extends Interactif

## Un fil qu'on a laissé tomber (§6). Il a quitté le bandeau : il n'existe
## plus que là, par terre, dans une pièce.
##
## C'est l'oubli rendu spatial. Le jeu ne te dit pas que tu as oublié quelque
## chose — il arrête simplement de te le rappeler. Tu le retrouves en passant,
## ou tu ne le retrouves pas.

const COULEUR_FRAIS := Color(0.62, 0.5, 0.32)
const COULEUR_MOISI := Color(0.6, 0.24, 0.24)
const COULEUR_HORS_PORTEE := Color(1.0, 0.4, 0.35)
## Ramasser ne coûte pas de temps, mais l'action doit se voir.
const DUREE_SYMBOLIQUE := 0.6

var fil_id: String = ""

@onready var _tas: Polygon2D = $Tas


func fil() -> Fil:
	return Partie.fils.get(fil_id)


func disponible() -> bool:
	return Partie.peut_ramasser(fil_id)


func _executer() -> float:
	if not Partie.ramasser_fil(fil_id):
		return -1.0
	# Le nœud disparaît une fois la barre finie : c'est `_process` qui le libère.
	return DUREE_SYMBOLIQUE


func rafraichir() -> void:
	var f := fil()

	if f == null or f.etat != Fil.Etat.LACHE:
		_etiquette.text = ""
		return

	var moisi := f.jours_au_sol >= 2
	_tas.color = COULEUR_MOISI if moisi else COULEUR_FRAIS

	if disponible():
		_etiquette.text = "%s   au sol depuis %d jour%s\nramasser" % [
			f.nom, f.jours_au_sol, "s" if f.jours_au_sol > 1 else ""
		]
		_etiquette.modulate = Color(1, 1, 1)
	else:
		# On ne ramasse pas un fil la tête pleine. Un fil moisi en demande deux.
		_etiquette.text = "%s   %s" % [
			f.nom, "il faut deux cases libres" if f.taille() > 1 else "il faut une case libre"
		]
		_etiquette.modulate = COULEUR_HORS_PORTEE


func _process(delta: float) -> void:
	super(delta)
	if occupe:
		return
	# Ramassé : le fil est remonté dans la tête, l'objet n'a plus lieu d'être.
	var f := fil()
	if f != null and f.etat != Fil.Etat.LACHE:
		queue_free()
