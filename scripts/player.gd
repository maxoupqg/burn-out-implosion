extends CharacterBody2D

## Vitesse maximale sur l'axe horizontal, en pixels/seconde.
@export var speed: float = 260.0
## Réactivité au démarrage. Plus c'est haut, plus le perso part sec.
@export var acceleration: float = 2200.0
## Réactivité à l'arrêt. Plus c'est haut, plus le perso pile net.
@export var friction: float = 2600.0
## Compression de l'axe vertical : donne la lecture "vue de dessus légèrement
## isométrique". 1.0 = vue de dessus stricte, 0.5 = très écrasé.
@export_range(0.3, 1.0, 0.05) var iso_ratio: float = 0.6

## Dernière direction non nulle. Servira à orienter les interactions.
var facing: Vector2 = Vector2.DOWN

var _a_portee: Array[Interactif] = []
var _occupe_par: Interactif = null

@onready var _portee: Area2D = $Portee


func _ready() -> void:
	_portee.area_entered.connect(_sur_entree_portee)
	_portee.area_exited.connect(_sur_sortie_portee)


func _physics_process(delta: float) -> void:
	# Pendant une tâche, on est cloué sur place. C'est le prix du temps.
	# Le point peut disparaître sous nos pieds : un fil ramassé s'efface du sol.
	if _occupe_par != null and not is_instance_valid(_occupe_par):
		_occupe_par = null
	if _occupe_par != null:
		if _occupe_par.occupe:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		_occupe_par = null

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input != Vector2.ZERO:
		facing = input

	# On écrase la composante verticale : à l'écran, un pas "vers le haut"
	# parcourt moins de pixels qu'un pas "sur le côté".
	var target := Vector2(input.x, input.y * iso_ratio) * speed
	var rate := acceleration if input != Vector2.ZERO else friction

	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interagir"):
		return
	if _occupe_par != null and is_instance_valid(_occupe_par) and _occupe_par.occupe:
		return

	var point := _plus_proche()
	if point != null and point.lancer():
		_occupe_par = point


func _plus_proche() -> Interactif:
	var meilleur: Interactif = null
	var distance_min := INF

	for point in _a_portee:
		if not is_instance_valid(point) or not point.disponible():
			continue
		var d := global_position.distance_to(point.global_position)
		if d < distance_min:
			distance_min = d
			meilleur = point

	return meilleur


func _sur_entree_portee(area: Area2D) -> void:
	var cible := area as Interactif
	if cible != null and not _a_portee.has(cible):
		_a_portee.append(cible)


func _sur_sortie_portee(area: Area2D) -> void:
	var cible := area as Interactif
	if cible != null:
		_a_portee.erase(cible)
