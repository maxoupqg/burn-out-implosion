class_name Reveur
extends CharacterBody2D

## Le personnage dans son rêve (§16). Trois verbes : frapper, s'élancer, se
## servir d'un ancré.
##
## Il est posé dans `scenes/reve.tscn` — forme, caméra, calques. Le script ne
## fait que le comportement. Le dessin reste à la main : c'est un proto gris, il
## n'aura pas d'assets avant qu'on sache si c'est amusant.
##
## Son masque ne contient que les murs : les monstres se détectent à la distance
## et jamais au moteur physique, pour qu'une corvée ne puisse pas nous pousser.

## Portée du coup, en pixels, mesurée depuis le centre du rêveur jusqu'au *bord*
## de la cible. Court : frapper doit demander de s'approcher — mais à 74 il
## fallait entrer dans un boss pour le toucher, et la marge sur un tenace tenait
## en 30 pixels.
@export var portee_frappe: float = 96.0
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

## Durée d'affichage du cône de frappe. 0,12 s était sous le seuil de lecture :
## on tapait sans jamais voir où.
const DUREE_FLASH := 0.2

var facing: Vector2 = Vector2.DOWN
var en_elan: bool = false

var _recharge_frappe: float = 0.0
var _recharge_elan: float = 0.0
var _reste_elan: float = 0.0
var _flash_frappe: float = 0.0
## Temps pendant lequel le recul d'un contact tient la main. Sans lui, la vitesse
## de recul est écrasée par l'input dès la frame suivante et on ne sait pas
## qu'on vient de se faire toucher.
var _recul: float = 0.0
## Positions laissées derrière pendant l'élan. Sans cette traînée, un
## déplacement de 260 pixels en 0,18 s se lit comme une téléportation ratée.
var _trainee: Array[Vector2] = []


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

	if _recul > 0.0:
		_recul -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 1800.0 * delta)
		move_and_slide()
		return

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
	_flash_frappe = DUREE_FLASH
	a_frappe.emit(global_position, facing)
	queue_redraw()


## Vrai si une cible est dans le cône du coup. La nuit s'en sert pour trier les
## monstres — c'est le rêveur qui sait où il tape, pas eux.
##
## Tout se mesure sur le bord de la cible, jamais sur son centre : une grosse
## masse doit se toucher de loin et sur les côtés, comme elle en a l'air.
func dans_la_frappe(point: Vector2, rayon_cible: float = 0.0) -> bool:
	var vers := point - global_position
	var distance := vers.length()
	if distance - rayon_cible > portee_frappe:
		return false
	if distance <= rayon_cible or vers == Vector2.ZERO:
		return true
	# Le cône s'ouvre de ce que la cible occupe à cette distance : sinon le bord
	# d'un boss est dans la zone dessinée à l'écran mais hors du test.
	var marge := rad_to_deg(asin(clampf(rayon_cible / distance, 0.0, 1.0)))
	return absf(rad_to_deg(facing.angle_to(vers))) <= cone_frappe + marge


## Vrai quand rien ne peut nous atteindre. C'est ici, et nulle part ailleurs, que
## se décide ce qui touche le rêveur — sinon la chose sans nom se retrouve avec
## sa propre règle et l'élan ne la traverse pas.
func intouchable() -> bool:
	return en_elan and elan_invulnerable


## Encaisser. Sans barre de vie : se faire toucher coûte de la nuit, pas des
## points de vie (§16 — pas de mort définitive dans le rêve).
func encaisser(depuis: Vector2) -> void:
	velocity = (global_position - depuis).normalized() * 420.0
	_recul = 0.14
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
		# Un secteur plein qui s'efface, plutôt qu'un trait d'arc : c'est la zone
		# qui touche, il faut la voir comme une surface et pas comme une bordure.
		var reste := _flash_frappe / DUREE_FLASH
		var demi := deg_to_rad(cone_frappe)
		var angle := facing.angle()
		var portee := portee_frappe * (0.72 + 0.28 * reste)
		var points := PackedVector2Array([Vector2.ZERO])
		for i in 17:
			points.append(Vector2.RIGHT.rotated(angle - demi + demi * 2.0 * i / 16.0) * portee)
		draw_colored_polygon(points, Color(1, 1, 1, 0.28 * reste))
		draw_arc(Vector2.ZERO, portee, angle - demi, angle + demi, 24, Color(1, 1, 1, 0.7 * reste), 4.0)
