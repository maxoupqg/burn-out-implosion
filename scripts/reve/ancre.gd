class_name AncreDeReve
extends Area2D

## Un fil ancré, la nuit : pas un monstre, un outil (§16 — « un mur déjà bâti »).
##
## C'est le verbe qui n'existe que dans ce jeu. S'en servir, c'est faire faire
## le travail par la machine : ça balaie ce qui est autour, tout seul, sans que
## le rêveur lève la main. Ton arsenal de cette nuit, c'est la façon dont tu as
## joué hier — et ça ne s'achète pas dans le rêve.
##
## Usage unique. Sinon un joueur bien ancré n'a plus rien à jouer.

signal utilisee(centre: Vector2, rayon: float)

## Chargée à la demande et pas en `preload` : la scène pointe vers ce script, et
## un preload dans l'autre sens ferait un cycle au chargement.
const CHEMIN_SCENE := "res://scenes/reve/ancre.tscn"

static var _scene: PackedScene = null

@export var rayon_effet: float = 220.0

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
	utilisee.emit(global_position, rayon_effet)
	_rafraichir()
	queue_redraw()


func _rafraichir() -> void:
	var nom := fil.nom if fil != null else "Un dispositif"
	if usee:
		_etiquette.text = "%s\nça a servi" % nom
		_etiquette.modulate = Color(1, 1, 1, 0.25)
	else:
		_etiquette.text = "%s\nE — ça fait le travail" % nom
		_etiquette.modulate = Color(0.55, 0.82, 0.68)


func _draw() -> void:
	var c := Color(0.42, 0.66, 0.88) if not usee else Color(0.24, 0.26, 0.3)
	draw_circle(Vector2.ZERO, 40.0, c)
	if not usee:
		draw_arc(Vector2.ZERO, rayon_effet, 0.0, TAU, 48, Color(0.42, 0.66, 0.88, 0.13), 2.0)
