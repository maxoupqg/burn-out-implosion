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

@export var rayon_effet: float = 220.0

var fil: Fil = null
var usee: bool = false

var _etiquette: Label = null


static func creer(p_fil: Fil) -> AncreDeReve:
	var a := AncreDeReve.new()
	a.fil = p_fil
	a.collision_layer = 8
	a.collision_mask = 0
	a.monitoring = false

	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = 40.0
	forme.shape = cercle
	a.add_child(forme)

	a._etiquette = Label.new()
	a._etiquette.position = Vector2(-140.0, -78.0)
	a._etiquette.size = Vector2(280.0, 44.0)
	a._etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a._etiquette.add_theme_font_size_override("font_size", 14)
	a.add_child(a._etiquette)
	a._rafraichir()

	return a


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
