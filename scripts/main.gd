extends Node2D

## La scène de jeu. Elle ne contient que le joueur, la caméra et l'interface :
## le décor, lui, va et vient.
##
## Une seule pièce est chargée à la fois (§9). C'est ce qui donne son poids au
## §6 : un fil lâché par terre dans la cuisine n'est plus visible nulle part
## quand on est au salon. Le bandeau dit qu'on a laissé tomber quelque chose,
## il ne dit pas où. Pour le récupérer, il faut se souvenir, marcher, et payer.

const SCENE_FIL_AU_SOL := preload("res://scenes/fil_au_sol.tscn")
const SCENE_REVE := preload("res://scenes/reve.tscn")

const PIECES := {
	"cuisine": preload("res://scenes/pieces/cuisine.tscn"),
	"salon": preload("res://scenes/pieces/salon.tscn"),
	"salle_de_bain": preload("res://scenes/pieces/salle_de_bain.tscn"),
	"chambre": preload("res://scenes/pieces/chambre.tscn"),
}

## On se réveille où l'on s'est couché. La chambre est donc le premier et le
## dernier écran de chaque journée, et elle pend au salon : sortir du lit coûte
## un couloir, y retourner aussi. C'est le prix de la journée, tous les jours.
const PIECE_DEPART := "chambre"

var _piece: Piece = null
## Une porte peut être touchée plusieurs fois dans la même frame (deux corps,
## deux zones). On ne paie qu'un seul couloir.
var _en_transition: bool = false
var _nuit: Reve = null

@onready var _camera: Camera2D = $Camera
@onready var _monde: Node2D = $Monde
@onready var _joueur: CharacterBody2D = $Monde/Player
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	Partie.fil_deborde.connect(_sur_fil_deborde)
	_entrer(PIECE_DEPART, "")


## Charge une pièce et jette la précédente. `depuis` est la pièce d'où l'on
## vient : elle décide de quel côté on repose le joueur.
func _entrer(piece_id: String, depuis: String) -> void:
	if not PIECES.has(piece_id):
		push_error("Pièce inconnue : %s" % piece_id)
		return

	if _piece != null:
		_monde.remove_child(_piece)
		_piece.queue_free()
		_piece = null

	_piece = PIECES[piece_id].instantiate()

	# Deux pièces voisines ont leur porte commune aux mêmes coordonnées : celle
	# d'en face naît donc pile sous les pieds du joueur, qui vient d'entrer par
	# ici. On les fait naître muettes.
	for porte in _piece.portes():
		porte.monitoring = false
		porte.franchie.connect(_sur_porte_franchie)

	var couchage := _piece.lit()
	if couchage != null:
		couchage.coucher_demande.connect(_sur_coucher_demande)

	_monde.add_child(_piece)

	_joueur.global_position = _piece.point_arrivee(depuis)
	_joueur.velocity = Vector2.ZERO

	_poser_les_fils_de_la_piece()

	# Le déplacement du joueur n'est vu par le serveur physique qu'au pas
	# suivant. Rouvrir les portes avant, c'est traverser tout le logement d'une
	# traite en payant chaque couloir.
	var posee := _piece
	await get_tree().physics_frame
	if _piece != posee:
		return
	for porte in _piece.portes():
		porte.monitoring = true
	_en_transition = false


func _sur_porte_franchie(vers: String) -> void:
	if _en_transition or Partie.finie:
		return
	_en_transition = true
	# On est dans l'émission d'un signal d'une porte de la pièce qu'on va
	# libérer : on ne touche pas à l'arbre maintenant.
	_changer_de_piece.call_deferred(vers)


func _changer_de_piece(vers: String) -> void:
	var depuis := _piece.piece_id if _piece != null else ""
	Partie.changer_de_piece()
	_entrer(vers, depuis)


# --- La nuit ----------------------------------------------------------------

func _sur_coucher_demande() -> void:
	if _nuit != null or Partie.finie:
		return
	# On est dans la propagation d'entrée d'un nœud du monde qu'on s'apprête à
	# endormir. On ne touche pas à l'arbre maintenant.
	_passer_la_nuit.call_deferred()


## La nuit est un calque, pas un changement de scène (§16). Recharger vers
## `reve.tscn` puis revenir repartirait de la première pièce et perdrait où l'on
## dort — or on se réveille dans son lit, pas dans la cuisine.
##
## Le monde est mis en sommeil plutôt que simplement caché : il continuerait
## sinon à marcher dans le noir, à franchir des portes et à payer les couloirs —
## et surtout ses murs resteraient dans l'espace physique, où le rêveur irait
## buter dedans sans rien voir. Les deux décors se superposent à l'origine.
func _passer_la_nuit() -> void:
	# La soirée d'abord, et c'est tout l'enjeu de l'ordre : le rêve lit l'état
	# des fils *après* que les tensions ont monté, que les dispositifs ont lâché
	# et que les échéances sont tombées. Un prélèvement qui vient de céder ne
	# doit pas se présenter comme un mur la nuit même.
	Partie.passer_la_soiree()

	_endormir(true)

	_nuit = SCENE_REVE.instantiate()
	_nuit.nuit_finie.connect(_sur_nuit_finie)
	add_child(_nuit)


func _sur_nuit_finie(delta: int, paisible: bool) -> void:
	_reveiller.call_deferred(delta, paisible)


func _reveiller(delta: int, paisible: bool) -> void:
	remove_child(_nuit)
	_nuit.queue_free()
	_nuit = null

	# Le monde revient d'abord, la journée ensuite : `se_lever` fait tomber des
	# fils, et il faut que le logement soit là pour les recevoir.
	_endormir(false)
	_camera.make_current()
	Partie.se_lever(delta, paisible)


## Endormir le logement, c'est le sortir de l'arbre — pas le cacher. Un corps
## caché collisionne toujours ; hors de l'arbre, il quitte l'espace physique,
## ne processe plus et ne reçoit plus rien. On garde la référence, donc l'état :
## on se réveille exactement où l'on s'est couché.
##
## Le HUD, lui, reste et se contente d'être désactivé. C'est voulu : son minuteur
## de flashs se fige au lieu de courir, sinon « les factures te sont tombées des
## mains » s'annoncerait pendant le rêve et aurait expiré au réveil.
func _endormir(dort: bool) -> void:
	if dort:
		remove_child(_monde)
	else:
		add_child(_monde)

	_hud.process_mode = Node.PROCESS_MODE_DISABLED if dort else Node.PROCESS_MODE_INHERIT
	_hud.visible = not dort


# --- Fils au sol ------------------------------------------------------------

func _sur_fil_deborde(fil: Fil) -> void:
	# Appelé au milieu d'une itération sur les fils : rien dans l'arbre tout de
	# suite. Et si le fil est tombé ailleurs, on n'a rien à afficher.
	if _piece != null and fil.piece_id == _piece.piece_id:
		_poser_les_fils_de_la_piece.call_deferred()


## Reconstruit les tas au sol visibles ici. Les fils tombés dans les autres
## pièces n'ont aucune existence tant qu'on n'y est pas.
##
## L'emplacement est tiré de l'identifiant du fil, pas au hasard : un tas doit
## être au même endroit d'une visite à l'autre, sinon revenir le chercher ne
## veut plus rien dire.
func _poser_les_fils_de_la_piece() -> void:
	if _piece == null or _piece.spots.is_empty():
		return

	var deja := {}
	var occupes := {}
	for enfant in _piece.get_children():
		if enfant is FilAuSol:
			deja[enfant.fil_id] = true
			occupes[enfant.position] = true

	for fil in Partie.fils_au_sol():
		if fil.piece_id != _piece.piece_id or deja.has(fil.id):
			continue

		var n := _piece.spots.size()
		var depart := absi(fil.id.hash()) % n
		var place := _piece.spots[depart]
		for i in n:
			var candidat: Vector2 = _piece.spots[(depart + i) % n]
			if not occupes.has(candidat):
				place = candidat
				break

		var noeud: FilAuSol = SCENE_FIL_AU_SOL.instantiate()
		# Avant l'entrée dans l'arbre : `_ready` s'en sert pour se dessiner.
		noeud.fil_id = fil.id
		noeud.position = place
		_piece.add_child(noeud)
		occupes[place] = true


# --- DEBUG — à retirer ------------------------------------------------------

## N : passer la nuit sans la jouer, où qu'on soit. Tant que le rêve n'est pas
## jouable (deux runs, deux morts), brancher sec rendrait le jour intestable :
## chaque journée finirait par une nuit ratée. On retombe sur le barème du §7.
func _unhandled_key_input(event: InputEvent) -> void:
	var touche := event as InputEventKey
	if touche == null or not touche.pressed or touche.echo:
		return

	if touche.keycode == KEY_N and _nuit == null:
		Partie.coucher()
		_poser_les_fils_de_la_piece()
		print("Jour %d — %d cases pour %d slots." % [
			Partie.jour, Partie.cases_occupees(), Partie.slots
		])
