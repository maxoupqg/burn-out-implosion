class_name Reve
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
## La nuit ne touche jamais à `Partie` elle-même : elle *propose* un nombre de
## cases par `nuit_finie`, et c'est `partie.gd` qui l'applique et le borne. Le
## rêve ne connaît donc ni le plancher à 4 ni le plafond à 6 — il ne peut pas
## les franchir même en le voulant.
##
## Elle se joue de deux façons : lancée seule (F6) pour régler le ressenti, ou
## montée en calque au-dessus de `main.tscn` quand on va se coucher.

## Ce que la nuit rend au réveil : des cases, et rien d'autre (§16). `paisible`
## dit qu'il n'y avait rien du tout — c'est ce qui ouvre le plafond haut.
signal nuit_finie(delta: int, paisible: bool)

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
## Durée du figement quand un coup porte, en secondes réelles. Au-delà de 0,08 le
## rêve devient pâteux ; en dessous de 0,03 on ne le sent plus.
@export_range(0.0, 0.12, 0.01) var hitstop: float = 0.05

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

var _monstres: Array[Monstre] = []
var _ancres: Array[AncreDeReve] = []
var _reste: float = 0.0
var _a_nettoyer: int = 0
var _abattus: int = 0
var _finie: bool = false
var _reveille: bool = false
var _en_hitstop: bool = false
## Ce que la nuit va rendre, une fois qu'on aura accusé réception du bilan.
var _delta: int = 0
var _paisible: bool = false
var _attend_reveil: bool = false

@onready var _monde: Node2D = $Monde
## Posé dans la scène, pas construit en code : c'est la seule façon d'avoir ses
## curseurs de ressenti — portée, cône, cadence, élan — dans l'inspecteur, et
## c'est là qu'on passe la session à les bouger.
@onready var _reveur: Reveur = $Monde/Reveur
## En calque au-dessus du jeu, deux caméras coexistent : celle du logement et
## celle-ci. Le rêve prend la vue en arrivant, et la rend au réveil.
@onready var _camera: Camera2D = $Monde/Reveur/Camera2D
@onready var _horloge: Label = $Interface/Horloge
@onready var _jauge: ColorRect = $Interface/Jauge
@onready var _resultat: Label = $Interface/Resultat


func _ready() -> void:
	# On se rejoue au R en plein hitstop : sans ça le rêve suivant démarre figé.
	Engine.time_scale = 1.0
	_reste = duree_nuit
	_resultat.hide()
	_camera.make_current()
	_reveur.a_frappe.connect(_sur_frappe)
	_reveur.touche.connect(_sur_touche)
	_peupler()
	_maj_horloge()

	if _monstres.is_empty():
		_nuit_sans_reve()


func _process(delta: float) -> void:
	if _finie:
		return
	_reste -= delta
	if _reste <= 0.0:
		_reste = 0.0
		_terminer()
	_maj_horloge()


# --- Construction ------------------------------------------------------------

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


## Rien à affronter : on ne fait pas jouer ça.
##
## Une arène vide n'est pas une nuit facile, c'est soixante-quinze secondes de
## marche — et `_terminer` n'y serait même jamais atteint, puisqu'il n'est
## appelé que par un monstre abattu, un contact, un réveil ou l'horloge.
##
## Deux nuits très différentes se cachent là-dessous, et c'est pourquoi on ne
## récompense pas l'arène vide mais la tête vide : **une relance ne produit
## aucun monstre**. Le §16 lui donne un mur pour un fil ancré, une chose sans
## nom pour un fil au sol, et rien du tout pour ce qu'on a passé à quelqu'un.
## Celui qui a tout délégué se couche donc l'arène déserte et la tête pleine :
## il n'a personne à affronter, il n'a pas pour autant bien dormi.
func _nuit_sans_reve() -> void:
	_finie = true
	_reveur.set_physics_process(false)

	# Rien à montrer : ni décor, ni horloge, ni aide. Une ligne sur du noir.
	_monde.hide()
	for enfant in $Interface.get_children():
		enfant.visible = enfant == _resultat

	_paisible = Partie.cases_occupees() == 0
	# La nuit paisible ne se compte pas, elle pose le chiffre : `delta` ne sert
	# alors à rien et `Partie` l'ignore. Le barème ne parle que de l'autre cas,
	# celui de la tête pleine sans personne en face.
	_delta = 0 if _paisible else Partie.delta_de_nuit_calculee()
	_attend_reveil = true

	var texte := ""
	var effet := ""
	if _paisible:
		texte = "Nuit paisible.\n\nIl n'y avait rien à porter."
		effet = "%d cases demain" % Partie.reglages.slots_nuit_paisible
	else:
		texte = "Personne à affronter.\n\nTu as quand même mal dormi."
		effet = "%+d case demain" % _delta

	_resultat.text = "%s\n\n%s\n\n%s" % [
		texte, effet, "R — recommencer" if _autonome() else "E — se lever",
	]
	_resultat.show()


# --- Jeu ---------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# Avant tout le reste : sinon l'appui qui vient de déclencher un ancré, et
	# de vider la salle du même coup, servirait aussi à se lever.
	if _attend_reveil:
		if event.is_action_pressed("interagir"):
			_attend_reveil = false
			nuit_finie.emit(_delta, _paisible)
		return

	if event.is_action_pressed("interagir") and not _finie:
		_utiliser_ancre()

	# Un proto se rejoue vingt fois de suite : la relance doit être immédiate.
	# Mais en calque au-dessus du jeu, la scène courante est `main.tscn` : on
	# rechargerait la partie entière au lieu de la nuit.
	var touche := event as InputEventKey
	if touche != null and touche.pressed and not touche.echo and touche.keycode == KEY_R:
		if _autonome():
			get_tree().reload_current_scene()


## Vrai quand on lance `reve.tscn` toute seule pour régler le ressenti.
func _autonome() -> bool:
	return get_tree().current_scene == self


func _utiliser_ancre() -> void:
	for ancre in _ancres:
		if is_instance_valid(ancre) and ancre.a_portee(_reveur.global_position):
			ancre.utiliser()
			return


## Le cône est calculé par le rêveur, qui seul sait où il regarde.
func _sur_frappe(origine: Vector2, _direction: Vector2) -> void:
	var a_porte := false
	for monstre in _monstres.duplicate():
		if not is_instance_valid(monstre):
			continue
		# Le figement se mérite : `encaisser` renvoie faux sur la chose sans nom,
		# et le monde ne s'arrête donc pas quand on la frappe. C'est le contraste
		# entre les deux qui dit qu'on perd son temps, pas un message.
		if _reveur.dans_la_frappe(monstre.global_position, monstre.rayon):
			a_porte = monstre.encaisser(origine) or a_porte
	if a_porte:
		_hitstop()


## Le monde se fige le temps d'un battement de cil quand le coup porte. C'est ce
## qui sépare « j'ai appuyé » de « j'ai tapé », et ça ne coûte aucune mécanique.
func _hitstop() -> void:
	if hitstop <= 0.0 or _en_hitstop:
		return
	_en_hitstop = true
	Engine.time_scale = 0.04
	# Le timer doit ignorer le ralenti, sinon il dure vingt-cinq fois trop.
	await get_tree().create_timer(hitstop, true, false, true).timeout
	Engine.time_scale = 1.0
	_en_hitstop = false


## Le dispositif écarte ce qui arrivait et le retient un moment. Rien ne meurt
## ici : la nuit se gagne à la main, l'ancré ne fait que rendre le prochain coup
## jouable. La chose sans nom n'est pas concernée — un dispositif ne règle pas ce
## qu'on a laissé tomber.
##
## Pas de `duplicate()` : plus personne ne quitte la liste pendant le balayage.
func _sur_ancre_utilisee(centre: Vector2, rayon: float, duree: float) -> void:
	for monstre in _monstres:
		if not is_instance_valid(monstre):
			continue
		if monstre.global_position.distance_to(centre) <= rayon:
			monstre.repousser(centre, duree)


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


## Ce que la nuit rend : des cases, et rien d'autre (§16). Le résultat n'est pas
## appliqué ici — il attend qu'on le lise, puis part dans `nuit_finie`.
func _terminer() -> void:
	if _finie:
		return
	_finie = true

	# Une nuit peut se terminer en plein figement. Sans ça, le logement rouvrirait
	# au ralenti et on chercherait longtemps pourquoi.
	Engine.time_scale = 1.0

	for monstre in _monstres:
		if is_instance_valid(monstre):
			monstre.set_physics_process(false)
	_reveur.set_physics_process(false)

	var pourquoi := ""
	if _reveille:
		_delta = -1
		pourquoi = "Quelque chose t'a rattrapé. Tu ne sais toujours pas quoi."
	elif _abattus >= _a_nettoyer:
		_delta = 1
		pourquoi = "Nuit blanche au sens propre : il ne restait rien."
	else:
		_delta = 0
		pourquoi = "Le jour s'est levé sur ce qui traînait encore."

	_attend_reveil = true
	_resultat.text = "%s\n\n%d / %d abattus\n\n%s case demain\n\n%s" % [
		pourquoi, _abattus, _a_nettoyer, "%+d" % _delta,
		"R — recommencer" if _autonome() else "E — se lever",
	]
	_resultat.show()
