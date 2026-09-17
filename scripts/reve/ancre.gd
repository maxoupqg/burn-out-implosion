class_name AncreDeReve
extends Area2D

## Un fil ancré, la nuit : pas un monstre, un outil (§16 — « un mur déjà bâti »).
##
## C'est le verbe qui n'existe que dans ce jeu. Ton arsenal de cette nuit, c'est
## la façon dont tu as joué hier — et ça ne s'achète pas dans le rêve.
##
## **Il écarte et il retient, il ne tue pas.** La première version balayait ce
## qui était autour, et gagnait la nuit d'un seul appui : tous les monstres
## convergent sur le rêveur, donc n'importe quel effet centré là les attrape
## tous, quel que soit le rayon. Ce n'était pas une question de réglage, c'était
## structurel — et la table du §16 dit « raccourci, salle sûre, porte qui s'ouvre
## seule », jamais « bombe ». Un dispositif ne fait pas le travail à ta place, il
## fait qu'il y a moins à faire d'un coup.
##
## Ce qu'il achète est donc du temps et de la place, et rien d'autre : la nuit
## reste entièrement à jouer à la main.
##
## Usage unique. Sinon un joueur bien ancré n'a plus rien à jouer.

signal utilisee(centre: Vector2, rayon: float, duree: float)

## Chargée à la demande et pas en `preload` : la scène pointe vers ce script, et
## un preload dans l'autre sens ferait un cycle au chargement.
const CHEMIN_SCENE := "res://scenes/reve/ancre.tscn"

static var _scene: PackedScene = null

@export var rayon_effet: float = 220.0
## Combien de temps ce qui a été écarté reste cloué. C'est le vrai curseur de
## l'ancré : assez pour souffler, respirer et choisir sa cible ; pas assez pour
## que la nuit se joue en attendant que ça repasse.
@export var duree_clouage: float = 3.0

var fil: Fil = null
var usee: bool = false

@onready var _etiquette: Label = $Etiquette


static func creer(p_fil: Fil) -> AncreDeReve:
	if _scene == null:
		_scene = load(CHEMIN_SCENE)

	var a: AncreDeReve = _scene.instantiate()
	a.fil = p_fil
	return a


func _ready() -> void:
	_rafraichir()


func a_portee(point: Vector2) -> bool:
	return not usee and global_position.distance_to(point) <= 90.0


func utiliser() -> void:
	if usee:
		return
	usee = true
	utilisee.emit(global_position, rayon_effet, duree_clouage)
	_rafraichir()
	queue_redraw()


func _rafraichir() -> void:
	var nom := fil.nom if fil != null else "Un dispositif"
	if usee:
		_etiquette.text = "%s\nça a servi" % nom
		_etiquette.modulate = Color(1, 1, 1, 0.25)
	else:
		_etiquette.text = "%s\nE — ça écarte et ça retient" % nom
		_etiquette.modulate = Color(0.55, 0.82, 0.68)


func _draw() -> void:
	var c := Color(0.42, 0.66, 0.88) if not usee else Color(0.24, 0.26, 0.3)
	draw_circle(Vector2.ZERO, 40.0, c)
	if not usee:
		draw_arc(Vector2.ZERO, rayon_effet, 0.0, TAU, 48, Color(0.42, 0.66, 0.88, 0.13), 2.0)
