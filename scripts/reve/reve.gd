extends Node2D

## Le prototype gris du dream system (§16, §17).
##
## Ce qu'on cherche à sentir, et rien d'autre :
##   1. est-ce que frapper une corvée est agréable ?
##   2. est-ce que l'horloge force à choisir *lesquelles* on nettoie ?
##   3. est-ce que se servir d'un ancré vaut mieux que taper ?
##   4. est-ce que fuir la chose sans nom fait ce qu'on veut qu'elle fasse ?
##
## Ce qui n'est délibérément pas là : butin, statistiques, équipement,
## progression. La §16 les a refusés, et un proto qui en contient ne répond plus
## à la question posée — il répond « oui c'est fun », mais grâce au butin.
##
## La nuit ne touche pas à `Partie`. Elle affiche ce qu'elle aurait rendu.
## Le branchement sur `coucher()` viendra quand les verbes seront tranchés.

## Durée d'une nuit, en secondes. Le curseur le plus important du proto : c'est
## lui qui décide si on nettoie tout ou si on doit choisir.
@export var duree_nuit: float = 75.0
## Ce qu'un coup encaissé retire à la nuit. Il n'y a pas de barre de vie : se
## faire toucher, c'est mal dormir, donc perdre de la nuit.
@export var cout_contact: float = 2.5
## Force la distribution de test (une corvée, une tenace, un boss, un ancré, une
## chose) au lieu de lire l'état réel de la journée. À laisser vrai tant qu'on
## prototype : sinon le premier jour ne montre que des corvées.
@export var contenu_de_test: bool = true

const PLACES := [
	Vector2(-520, -240), Vector2(480, -280), Vector2(-260, 160),
	Vector2(560, 180), Vector2(-620, 260), Vector2(220, -120),
	Vector2(80, 320), Vector2(-80, -360),
]

## Où l'état du fil devient un genre de monstre. Le §16 en tableau.
const TEST := {
	"courses": Monstre.Genre.CORVEE,
	"linge": Monstre.Genre.TENACE,
	"factures": Monstre.Genre.BOSS,
	"malade": Monstre.Genre.CHOSE,
}

var _reveur: Reveur = null
var _monstres: Array[Monstre] = []
var _ancres: Array[AncreDeReve] = []
var _reste: float = 0.0
var _a_nettoyer: int = 0
var _abattus: int = 0
var _finie: bool = false
var _reveille: bool = false

@onready var _monde: Node2D = $Monde
@onready var _horloge: Label = $Interface/Horloge
@onready var _jauge: ColorRect = $Interface/Jauge
@onready var _resultat: Label = $Interface/Resultat


func _ready() -> void:
	_reste = duree_nuit
	_resultat.hide()
	_poser_le_reveur()
	_peupler()
	_maj_horloge()


func _process(delta: float) -> void:
	if _finie:
		return
	_reste -= delta
	if _reste <= 0.0:
		_reste = 0.0
		_terminer()
	_maj_horloge()


# --- Construction ------------------------------------------------------------

func _poser_le_reveur() -> void:
	_reveur = Reveur.creer()
	_reveur.position = Vector2(0, 300)
	_reveur.a_frappe.connect(_sur_frappe)
	_reveur.touche.connect(_sur_touche)
	_monde.add_child(_reveur)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.zoom = Vector2(0.85, 0.85)
	_reveur.add_child(camera)
	camera.make_current()


## La journée écrit le niveau. Rien n'est tiré au sort tant qu'il reste un fil
## à traduire — c'est la règle centrale du §16, et c'est aussi ce qui rend le
## procédural presque inutile ici.
func _peupler() -> void:
	var place := 0
	for fil in _fils_de_la_nuit():
		if fil.etat == Fil.Etat.ANCRE:
			var ancre := AncreDeReve.creer(fil)
			ancre.position = PLACES[place % PLACES.size()]
			ancre.utilisee.connect(_sur_ancre_utilisee)
			_monde.add_child(ancre)
			_ancres.append(ancre)
			place += 1
			continue

		if fil.etat != Fil.Etat.OUVERT and fil.etat != Fil.Etat.LACHE:
			continue

		var monstre := Monstre.creer(_genre_de(fil), fil)
		monstre.position = PLACES[place % PLACES.size()]
		monstre.viser(_reveur)
		monstre.abattu.connect(_sur_abattu)
		monstre.a_reveille.connect(_sur_reveil)
		_monde.add_child(monstre)
		_monstres.append(monstre)
		if not monstre.invincible():
			_a_nettoyer += 1
		place += 1


func _fils_de_la_nuit() -> Array[Fil]:
	if not contenu_de_test:
		var reels: Array[Fil] = []
		for fil: Fil in Partie.fils.values():
			if fil.etat == Fil.Etat.OUVERT or fil.etat == Fil.Etat.ANCRE \
				or fil.etat == Fil.Etat.LACHE:
				reels.append(fil)
		return reels

	# En test : on force un exemplaire de chaque genre, sinon le premier jour ne
	# produit que des corvées et on ne sent rien de ce qu'on veut sentir.
	var fils := Contenu.fils()
	for fil in fils:
		if fil.id == "repas":
			fil.etat = Fil.Etat.ANCRE
		elif fil.id == "malade":
			fil.etat = Fil.Etat.LACHE
		else:
			fil.etat = Fil.Etat.OUVERT
	return fils


## Le tableau du §16. En mode réel, tout se lit sur le fil ; en test, sur la
## table ci-dessus.
func _genre_de(fil: Fil) -> int:
	if fil.etat == Fil.Etat.LACHE:
		return Monstre.Genre.CHOSE

	if contenu_de_test:
		return TEST.get(fil.id, Monstre.Genre.CORVEE)

	# Le boss n'est pas le fil le plus gros : c'est celui dont la date tombe
	# demain. Sinon une mauvaise journée offrirait le meilleur combat, et on
	# rouvre le couplage que le §16 a refusé.
	if fil.jour_echeance == Partie.jour + 1:
		return Monstre.Genre.BOSS
	if fil.tension >= Fil.TENSION_SEUIL:
		return Monstre.Genre.TENACE
	return Monstre.Genre.CORVEE


# --- Jeu ---------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and not _finie:
		_utiliser_ancre()

	# Un proto se rejoue vingt fois de suite : la relance doit être immédiate.
	var touche := event as InputEventKey
	if touche != null and touche.pressed and not touche.echo and touche.keycode == KEY_R:
		get_tree().reload_current_scene()


func _utiliser_ancre() -> void:
	for ancre in _ancres:
		if is_instance_valid(ancre) and ancre.a_portee(_reveur.global_position):
			ancre.utiliser()
			return


## Le cône est calculé par le rêveur, qui seul sait où il regarde.
func _sur_frappe(_origine: Vector2, _direction: Vector2) -> void:
	for monstre in _monstres.duplicate():
		if is_instance_valid(monstre) and _reveur.dans_la_frappe(monstre.global_position):
			monstre.encaisser()


## La machine fait le travail : ce qui est autour tombe, sans lever la main.
## La chose sans nom n'est pas concernée — un dispositif ne règle pas ce qu'on
## a laissé tomber.
func _sur_ancre_utilisee(centre: Vector2, rayon: float) -> void:
	for monstre in _monstres.duplicate():
		if not is_instance_valid(monstre) or monstre.invincible():
			continue
		if monstre.global_position.distance_to(centre) <= rayon:
			while is_instance_valid(monstre) and monstre.pv > 0:
				monstre.encaisser()


func _sur_abattu(monstre: Monstre) -> void:
	_monstres.erase(monstre)
	_abattus += 1
	if _abattus >= _a_nettoyer:
		_terminer()


func _sur_touche() -> void:
	_reste = maxf(_reste - cout_contact, 0.0)
	if _reste <= 0.0:
		_terminer()


func _sur_reveil() -> void:
	if _finie:
		return
	_reveille = true
	_terminer()


# --- Fin de nuit -------------------------------------------------------------

func _maj_horloge() -> void:
	_horloge.text = "nuit   %.0f" % _reste
	_jauge.size.x = 320.0 * clampf(_reste / duree_nuit, 0.0, 1.0)


## Ce que la nuit rend : des cases, et rien d'autre (§16). Le plancher à 4 et le
## plafond à 6 restent le plafond du monde — une nuit héroïque ne donne pas 8.
func _terminer() -> void:
	if _finie:
		return
	_finie = true

	for monstre in _monstres:
		if is_instance_valid(monstre):
			monstre.set_physics_process(false)
	_reveur.set_physics_process(false)

	var delta := 0
	var pourquoi := ""
	if _reveille:
		delta = -1
		pourquoi = "Quelque chose t'a rattrapé. Tu ne sais toujours pas quoi."
	elif _abattus >= _a_nettoyer:
		delta = 1
		pourquoi = "Nuit blanche au sens propre : il ne restait rien."
	else:
		delta = 0
		pourquoi = "Le jour s'est levé sur ce qui traînait encore."

	_resultat.text = "%s\n\n%d / %d abattus\n\n%s case demain\n\nR — recommencer" % [
		pourquoi, _abattus, _a_nettoyer, "%+d" % delta,
	]
	_resultat.show()
