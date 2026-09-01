class_name Porte
extends Area2D

## Une sortie vers une pièce voisine (§9).
##
## On la franchit en marchant — pas de touche, pas de menu. Le prix est écrit
## dessus et suit le multiplicateur : quand la tête est pleine, traverser le
## couloir coûte presque une tâche.

## Identifiant de la pièce de destination.
@export var vers: String = ""
## Son nom affiché. Le joueur doit savoir où il va avant de payer.
@export var nom_destination: String = ""
## Où l'on repose le joueur en arrivant *par* cette porte, relativement à elle.
## Assez loin pour ne pas la redéclencher aussitôt.
@export var decalage_arrivee: Vector2 = Vector2(-150, 0)

signal franchie(vers: String)

@onready var _etiquette: Label = $Etiquette


func _ready() -> void:
	body_entered.connect(_sur_entree)
	Partie.fils_change.connect(_rafraichir)
	Partie.temps_change.connect(func(_restant: float) -> void: _rafraichir())
	_rafraichir()


func arrivee() -> Vector2:
	return global_position + decalage_arrivee


func _sur_entree(corps: Node2D) -> void:
	if corps is CharacterBody2D:
		franchie.emit(vers)


func _rafraichir() -> void:
	_etiquette.text = "%s   → %.1f" % [nom_destination, Partie.cout_reel(Partie.reglages.cout_piece)]
