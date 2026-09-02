class_name Reveur
extends CharacterBody2D

## Le personnage dans son rêve (§16). Trois verbes : frapper, s'élancer, se
## servir d'un ancré.
##
## Tout est dessiné à la main et construit en code : c'est un proto gris, il
## n'a pas d'assets et il n'en aura pas avant qu'on sache si c'est amusant.

## Portée du coup, en pixels. Court : frapper doit demander de s'approcher.
@export var portee_frappe: float = 74.0
## Demi-angle du cône de frappe, en degrés. Large = confortable, étroit =
## exigeant. C'est un des trois curseurs du ressenti.
@export_range(15.0, 180.0, 5.0) var cone_frappe: float = 70.0
@export var cadence_frappe: float = 0.34

@export var vitesse: float = 260.0
@export var acceleration: float = 2200.0
@export var friction: float = 2600.0
## Compression verticale, comme en journée : le rêve garde la même vue.
@export_range(0.3, 1.0, 0.05) var iso_ratio: float = 0.6

@export_group("Élan")
## 1450 × 0,18 = environ 260 pixels franchis d'un coup, contre 47 en marchant
## sur la même durée. En dessous de ça l'élan ne se voit pas : il faut qu'il
## déplace le rêveur d'une bonne longueur de corps, sinon on croit que la
## touche ne répond pas.
@export var vitesse_elan: float = 1450.0
@export var duree_elan: float = 0.18
@export var recharge_elan: float = 0.7
## La question qu'on s'est disputée, rendue testable : est-ce que l'élan rend
## intouchable ? Si oui, on est dans un jeu d'action classique et l'esquive
## devient la réponse à tout. Si non, elle ne sert qu'à se déplacer, et c'est le
## placement qui compte. Essaie les deux avant de trancher.
@export var elan_invulnerable: bool = false

## Émis à chaque coup porté, pour que la nuit décide qui est touché.
signal a_frappe(origine: Vector2, direction: Vector2)
## Le rêveur s'est fait toucher : ça coûte de la nuit.
signal touche()

var facing: Vector2 = Vector2.DOWN
var en_elan: bool = false

var _recharge_frappe: float = 0.0
var _recharge_elan: float = 0.0
var _reste_elan: float = 0.0
var _flash_frappe: float = 0.0
## Positions laissées derrière pendant l'élan. Sans cette traînée, un
## déplacement de 260 pixels en 0,18 s se lit comme une téléportation ratée.
var _trainee: Array[Vector2] = []


static func creer() -> Reveur:
	var r := Reveur.new()
	r.collision_layer = 2
	# Ne heurte que les murs. Les monstres se détectent à la distance, pas au
	# moteur physique : on ne veut pas se faire pousser par une corvée.
	r.collision_mask = 1
	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = 16.0
	forme.shape = cercle
	r.add_child(forme)
	return r


func _physics_process(delta: float) -> void:
	_recharge_frappe = maxf(_recharge_frappe - delta, 0.0)
	_recharge_elan = maxf(_recharge_elan - delta, 0.0)
	_flash_frappe = maxf(_flash_frappe - delta, 0.0)
	if _flash_frappe > 0.0:
		queue_redraw()

	if en_elan:
		_reste_elan -= delta
		if _reste_elan <= 0.0:
			en_elan = false
		_trainee.append(global_position)
		move_and_slide()
		queue_redraw()
		return

	if not _trainee.is_empty():
		_trainee.remove_at(0)
		queue_redraw()

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()

	if Input.is_action_pressed("elan") and _recharge_elan <= 0.0:
		_declencher_elan()
		return

	if Input.is_action_pressed("frapper") and _recharge_frappe <= 0.0:
		_frapper()

	var cible := Vector2(input.x, input.y * iso_ratio) * vitesse
	var taux := acceleration if input != Vector2.ZERO else friction
	velocity = velocity.move_toward(cible, taux * delta)
	move_and_slide()


func _declencher_elan() -> void:
	en_elan = true
	_reste_elan = duree_elan
	_recharge_elan = recharge_elan
	# Même compression verticale qu'à la marche : sans elle, un élan vers le haut
	# couvre plus de terrain qu'un élan sur le côté, et la vue ment.
	velocity = Vector2(facing.x, facing.y * iso_ratio) * vitesse_elan
	queue_redraw()


func _frapper() -> void:
	_recharge_frappe = cadence_frappe
	_flash_frappe = 0.12
	a_frappe.emit(global_position, facing)
	queue_redraw()


## Vrai si un point est dans le cône du coup. La nuit s'en sert pour trier les
## monstres — c'est le rêveur qui sait où il tape, pas eux.
func dans_la_frappe(point: Vector2) -> bool:
	var vers := point - global_position
	if vers.length() > portee_frappe:
		return false
	if vers == Vector2.ZERO:
		return true
	return absf(rad_to_deg(facing.angle_to(vers))) <= cone_frappe


## Encaisser. Sans barre de vie : se faire toucher coûte de la nuit, pas des
## points de vie (§16 — pas de mort définitive dans le rêve).
func encaisser(depuis: Vector2) -> void:
	if en_elan and elan_invulnerable:
		return
	velocity = (global_position - depuis).normalized() * 420.0
	touche.emit()


func _draw() -> void:
	for i in _trainee.size():
		var force := float(i + 1) / float(_trainee.size())
		draw_circle(_trainee[i] - global_position, 16.0 * force, Color(1, 1, 1, 0.13 * force))

	var couleur := Color(0.85, 0.87, 0.92) if not en_elan else Color(1, 1, 1)
	draw_circle(Vector2.ZERO, 16.0, couleur)
	# Le nez : il faut voir où l'on tape avant de taper.
	draw_line(Vector2.ZERO, facing.normalized() * 26.0, couleur, 4.0)

	if _flash_frappe > 0.0:
		var demi := deg_to_rad(cone_frappe)
		var angle := facing.angle()
		draw_arc(
			Vector2.ZERO, portee_frappe, angle - demi, angle + demi, 24,
			Color(1, 1, 1, 0.5), 5.0
		)
