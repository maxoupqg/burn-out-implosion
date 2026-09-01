class_name Pnj
extends Interactif

## L'autre personne du logement. On lui délègue depuis n'importe quel meuble ;
## on ne le relance qu'ici (§4).
##
## C'est tout l'intérêt qu'il soit un endroit et pas un menu : déléguer est
## quasi gratuit sur le moment, et le lendemain il faut traverser le logement
## pour réclamer. Le prix n'est pas dans le geste — il est dans le trajet, et
## dans la case que la relance garde bloquée jusqu'à ce qu'on y aille.

const COULEUR_CALME := Color(0.46, 0.55, 0.72)
const COULEUR_ATTENDU := Color(0.95, 0.55, 0.3)
const COULEUR_TROP_CHER := Color(1.0, 0.4, 0.35)

@onready var _corps: Polygon2D = $Body
@onready var _pastille: Polygon2D = $Pastille


func disponible() -> bool:
	return Partie.peut_relancer()


func _executer() -> float:
	var cout := Partie.cout_reel(Partie.reglages.cout_relance)
	if not Partie.relancer():
		return -1.0
	return cout


func rafraichir() -> void:
	var dues := Partie.relances_dues()
	var en_cours := Partie.relances_en_tete().size() - dues.size()

	if dues.is_empty():
		_pastille.visible = false
		_corps.color = COULEUR_CALME
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		# On dit qu'il reste quelque chose en l'air, sans dire quoi : c'est
		# encore chez lui, ça ne pèse pas encore.
		if en_cours > 0:
			_etiquette.text = "%s\nil s'en occupe" % Partie.reglages.nom_delegataire
		else:
			_etiquette.text = Partie.reglages.nom_delegataire
		return

	var cout := Partie.cout_reel(Partie.reglages.cout_relance)
	_pastille.visible = true
	_corps.color = COULEUR_ATTENDU
	# Nommer ce qu'on vient réclamer : sinon relancer devient un bouton, et la
	# charge qu'on porte redevient invisible. Et dire ce que ça fait : redemander
	# quand il y a de quoi refaire, en sortir quand il n'y a plus rien. Sans ça
	# on ne comprend jamais comment l'arrangement s'arrête.
	_etiquette.text = "%s : relancer   %.1f\n%s — %s" % [
		Partie.reglages.nom_delegataire,
		cout,
		dues[0].tache.nom,
		"qu'il le refasse" if Partie.tache_active(dues[0].tache) else "c'est fini, la case se libère",
	]
	if dues.size() > 1:
		_etiquette.text += "   (+%d)" % (dues.size() - 1)
	_etiquette.modulate = COULEUR_TROP_CHER if cout > Partie.temps_restant else Color(1, 1, 1)
