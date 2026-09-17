class_name Jauge
extends VBoxContainer

## Une jauge du corps : l'humeur, et une par besoin.
##
## Le §18 refusait les jauges (« elle se lit sur le personnage, une jauge en
## ferait une chose à optimiser »). C'est moi qui avais écrit ça, et il a
## tranché l'inverse le 2026-09-17. Il a raison sur le fond : une fin de partie
## à trois jours doit se voir venir, et le seul reproche du playtest externe
## portait déjà sur ce que le jeu ne montre pas. Le visage viendra en plus, pas
## à la place.
##
## Même construction que les jauges de tension du bandeau : deux rectangles,
## dont l'un a son ancre droite pilotée. Pas de `ProgressBar` — on ne peut pas
## en changer la couleur de remplissage sans lui écrire un thème entier.

const COULEUR_PLEINE := Color(0.55, 0.78, 0.6)
const COULEUR_BASSE := Color(0.95, 0.55, 0.3)
const COULEUR_VIDE := Color(1.0, 0.35, 0.28)
## En dessous, ça passe à l'orange : il reste de quoi tenir, mais c'est le
## moment d'y aller.
const SEUIL_BAS := 0.3

@onready var _titre: Label = $Titre
@onready var _remplissage: ColorRect = $Fond/Remplissage


func afficher(titre: String, part: float) -> void:
	var p := clampf(part, 0.0, 1.0)
	_titre.text = titre
	_remplissage.anchor_right = p

	var couleur := COULEUR_PLEINE
	if p <= 0.0:
		couleur = COULEUR_VIDE
	elif p < SEUIL_BAS:
		couleur = COULEUR_BASSE
	_remplissage.color = couleur
	_titre.modulate = Color(1, 1, 1, 0.7) if p >= SEUIL_BAS else couleur
