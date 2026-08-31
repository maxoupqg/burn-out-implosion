class_name Dispositif
extends Interactif

## L'objet posé dans une pièce qui porte un fil ancré (§3).
##
## Chaque emplacement est typé pour un fil précis : le tableau des menus ne
## prend que « Les repas ». Ça encode gratuitement la règle du §9 — un
## dispositif dans la mauvaise pièce ne fonctionne pas.

const COULEUR_LIBRE := Color(0.38, 0.42, 0.5)
const COULEUR_PRET := Color(0.55, 0.78, 0.6)
const COULEUR_ANCRE := Color(0.42, 0.66, 0.88)
const COULEUR_USE := Color(0.72, 0.5, 0.28)
const COULEUR_BLOQUE := Color(1.0, 0.4, 0.35)

## Le fil que cet emplacement accepte. On y glisse un `.tres` de
## `donnees/fils/`. Un emplacement typé encode gratuitement la règle du §9.
@export var fil_def: FilDef
@export var nom_dispositif: String = "Dispositif"

@onready var _panneau: Polygon2D = $Panneau


func fil() -> Fil:
	return Partie.fils.get(fil_def.id) if fil_def != null else null


func ancre() -> bool:
	var f := fil()
	return f != null and f.etat == Fil.Etat.ANCRE


func disponible() -> bool:
	return fil_def != null and Partie.peut_ancrer(fil_def.id)


func _executer() -> float:
	var cout := Partie.cout_reel(Partie.COUT_ANCRAGE)
	if not Partie.ancrer_fil(fil_def.id):
		return -1.0
	return cout


func rafraichir() -> void:
	var f := fil()

	if f == null:
		_etiquette.text = nom_dispositif
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	# Un fil ancré reste visible, accroché à son dispositif (§3).
	# Sa tension devient l'usure du dispositif : à bout, il décroche.
	if ancre():
		var use := f.tension >= Fil.TENSION_SEUIL - 1
		_panneau.color = COULEUR_USE if use else COULEUR_ANCRE
		_etiquette.text = "%s\n%s" % [f.nom, "va lâcher" if use else "en place"]
		_etiquette.modulate = COULEUR_BLOQUE if use else Color(1, 1, 1, 0.75)
		return

	if disponible():
		_panneau.color = COULEUR_PRET
		_etiquette.text = "%s : ancrer « %s »   %.1f" % [
			nom_dispositif, f.nom, Partie.cout_reel(Partie.COUT_ANCRAGE)
		]
		_etiquette.modulate = Color(1, 1, 1)
		return

	# Indisponible : dire pourquoi, c'est ce qui apprend la règle du §5.
	_panneau.color = COULEUR_LIBRE
	_etiquette.modulate = COULEUR_BLOQUE
	if not f.ancrable:
		# Le §8 en une ligne : un dispositif ne marche que sur du prévisible.
		_etiquette.text = "%s : ça ne se délègue pas" % nom_dispositif
	elif f.etat != Fil.Etat.OUVERT:
		_etiquette.text = nom_dispositif
		_etiquette.modulate = Color(1, 1, 1, 0.3)
	elif Partie.cases_occupees() >= Partie.slots:
		_etiquette.text = "%s : aucune case libre" % nom_dispositif
	else:
		_etiquette.text = "%s : pas assez de temps" % nom_dispositif
