extends CanvasLayer

## L'écran de fin (§11). Il ne note pas le joueur : il lui raconte sa semaine.
##
## Le seul chiffre qui compte est le nombre de fois où l'on a réussi à
## s'asseoir. Zéro est le résultat le plus courant, et c'est le propos.

const TITRES := {
	"effondrement": "Tu as lâché.",
	"semaine": "Dimanche soir.",
}

const SOUS_TITRES := {
	"effondrement": "Trois choses par terre en même temps.\nTu ne sais même plus lesquelles.",
	"semaine": "La semaine est passée.\nLundi recommence dans quelques heures.",
}

@onready var _titre: Label = $Panneau/Titre
@onready var _sous_titre: Label = $Panneau/SousTitre
@onready var _bilan: Label = $Panneau/Bilan
@onready var _recommencer: Button = $Panneau/Recommencer


func _ready() -> void:
	visible = false
	Partie.partie_finie.connect(_afficher)
	_recommencer.pressed.connect(_relancer)


func _afficher(raison: String) -> void:
	_titre.text = TITRES.get(raison, "Fin.")
	_sous_titre.text = SOUS_TITRES.get(raison, "")
	_bilan.text = _ecrire_bilan()
	visible = true
	get_tree().paused = true


func _ecrire_bilan() -> String:
	var ancres := PackedStringArray()
	var au_sol := PackedStringArray()
	var regles := PackedStringArray()
	for fil: Fil in Partie.fils.values():
		match fil.etat:
			Fil.Etat.ANCRE: ancres.append(fil.nom)
			Fil.Etat.LACHE: au_sol.append(fil.nom)
			Fil.Etat.FERME: regles.append(fil.nom)

	var lignes := PackedStringArray()
	lignes.append("%d jours tenus." % mini(Partie.jour - 1, Partie.JOURS_SEMAINE))

	# Le vrai score. Il est presque toujours à zéro, et c'est le propos.
	if Partie.fois_assis == 0:
		lignes.append("Tu ne t'es pas assis une seule fois.")
	elif Partie.fois_assis == 1:
		lignes.append("Tu t'es assis une fois.")
	else:
		lignes.append("Tu t'es assis %d fois." % Partie.fois_assis)

	lignes.append("")
	if not ancres.is_empty():
		lignes.append("Tenu par un dispositif : %s" % ", ".join(ancres))
	if not regles.is_empty():
		lignes.append("Réglé : %s" % ", ".join(regles))
	if not au_sol.is_empty():
		lignes.append("Resté par terre : %s" % ", ".join(au_sol))

	return "\n".join(lignes)


func _relancer() -> void:
	get_tree().paused = false
	# Recharger la scène ne touche pas à l'autoload : c'est ici qu'on remet
	# la semaine à zéro, avec des fils neufs.
	Partie.reinitialiser()
	get_tree().reload_current_scene.call_deferred()
