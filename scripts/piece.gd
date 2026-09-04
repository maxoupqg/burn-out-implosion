class_name Piece
extends Node2D

## Une pièce du logement (§9).
##
## Chaque pièce est une scène à part, et une seule est chargée à la fois. Ce
## n'est pas une économie de mémoire : c'est la règle du §6. Un fil lâché par
## terre dans la cuisine n'existe plus pour un joueur qui est au salon — il faut
## y retourner, donc payer, donc s'en souvenir.
##
## Les points d'arrivée sont des `@export` plutôt que des Marker2D : surcharger
## un enfant de scène instanciée dans un .tscn demande une syntaxe `index=`
## fragile qu'on préfère ne pas écrire à la main.

## Identifiant stable, celui qu'on écrit dans `Porte.vers` et `Fil.piece_id`.
@export var piece_id: String = ""
@export var nom_piece: String = "Pièce"
## Où le joueur apparaît quand il entre ici sans venir d'une porte (début de
## partie, ou pièce voisine disparue).
@export var depart: Vector2 = Vector2.ZERO
## Emplacements au sol pour les fils lâchés, dans les trous entre les meubles.
@export var spots: Array[Vector2] = []

@onready var _nom: Label = $Nom


func _ready() -> void:
	_nom.text = nom_piece


## Le lit, s'il y en a un ici. Une seule pièce en a un, et c'est elle qui
## termine la journée : la scène de jeu s'y branche en entrant, comme elle se
## branche aux portes.
func lit() -> Lit:
	for enfant in get_children():
		if enfant is Lit:
			return enfant
	return null


func portes() -> Array[Porte]:
	var liste: Array[Porte] = []
	for enfant in $Portes.get_children():
		if enfant is Porte:
			liste.append(enfant)
	return liste


## Où reposer le joueur qui arrive de la pièce `depuis`. On le pose devant la
## porte par laquelle il vient d'entrer — sinon il aurait la sensation d'avoir
## été téléporté au hasard.
func point_arrivee(depuis: String) -> Vector2:
	for porte in portes():
		if porte.vers == depuis:
			return porte.arrivee()
	return depart
