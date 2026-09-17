class_name Monstre
extends CharacterBody2D

## Ce qu'un fil devient la nuit (§16). Un seul script, quatre genres : c'est
## l'état du fil au coucher qui décide lequel, jamais un tirage au sort.
##
## Le tableau du §16 en code :
##   ouvert, tension 0   → CORVEE  — banal, ça meurt vite, c'est agréable
##   ouvert, tension 2   → TENACE  — plus dur, et ça ne meurt pas pour de bon
##   échéance demain     → BOSS    — le rêve d'avant la date butoir
##   lâché par terre     → CHOSE   — increvable, sans nom, on la fuit
##
## La ligne qui compte est la dernière. Le §6 a effacé le fil lâché du bandeau :
## le joueur ne l'a plus en mémoire, au sens propre. Il le retrouve ici sans
## savoir ce que c'est, et le seul moyen de s'en débarrasser est d'aller le
## ramasser dans la journée.

enum Genre { CORVEE, TENACE, BOSS, CHOSE }

## La scène décrit le monstre ; ce script ne décrit que sa conduite. Chargée à la
## demande et pas en `preload` : la scène pointe vers ce script, et un preload
## dans l'autre sens ferait un cycle au chargement.
const CHEMIN_SCENE := "res://scenes/reve/monstre.tscn"

static var _scene: PackedScene = null

## Émis quand il tombe. La CHOSE ne l'émet jamais.
signal abattu(monstre: Monstre)
## La chose sans nom a touché le rêveur : la nuit s'arrête là.
signal a_reveille()

## `sonne` et `recul` sont ce que le coup fait à la cible. Sans eux, un tenace à
## 4 PV demande de rester collé 1,4 s pendant qu'il touche toutes les 0,8 s : le
## combat n'est pas difficile, il est perdu d'avance. C'est aussi là que se règle
## le caractère de chacun — le boss encaisse sans reculer, le tenace se décroche.
const REGLAGES := {
	Genre.CORVEE: {
		"pv": 2, "rayon": 18.0, "vitesse": 115.0, "couleur": Color(0.45, 0.5, 0.62),
		"sonne": 0.22, "recul": 320.0,
	},
	Genre.TENACE: {
		"pv": 4, "rayon": 26.0, "vitesse": 132.0, "couleur": Color(0.78, 0.52, 0.3),
		# 0,24 contre une cadence de 0,34 : il regagne un dixième de seconde de
		# marche entre deux coups. Il avance encore, mais on le repousse plus vite
		# qu'il n'arrive — et ça reste en deçà du verrouillage complet.
		"sonne": 0.24, "recul": 280.0,
	},
	Genre.BOSS: {
		"pv": 9, "rayon": 42.0, "vitesse": 104.0, "couleur": Color(0.78, 0.32, 0.34),
		"sonne": 0.1, "recul": 90.0,
	},
	Genre.CHOSE: {
		"pv": 0, "rayon": 30.0, "vitesse": 140.0, "couleur": Color(0.1, 0.09, 0.12),
		"sonne": 0.0, "recul": 0.0,
	},
}

## Freinage du recul, en pixels/seconde². Assez mou pour qu'on voie la cible
## partir, assez sec pour qu'elle ne glisse pas jusqu'au bout de l'arène.
const FREIN_RECUL := 1500.0

## La poussée d'un ancré, plus forte que celle d'un coup et identique pour tous :
## ce n'est pas la main du rêveur, c'est le dispositif. Le boss part comme la
## corvée — un mur déjà bâti ne demande pas qui arrive dessus.
const POUSSEE_ANCRE := 700.0

## Durée du blanchiment au coup.
const DUREE_FLASH := 0.16

## Typé `int` et pas `Genre` : l'enum sert à nommer, pas à contraindre, et le
## typer force des conversions explicites à chaque frontière pour rien.
var genre: int = Genre.CORVEE
## Le fil dont il sort. Sert au nom affiché — et la CHOSE ne le dit jamais.
var fil: Fil = null
var pv: int = 2
var rayon: float = 18.0
var vitesse: float = 115.0
var couleur: Color = Color.GRAY

var _cible: Node2D = null
var _repos_contact: float = 0.0
var _flash_touche: float = 0.0
## Temps restant à être sonné. Tant qu'il court, le monstre subit son recul, ne
## poursuit plus et ne touche pas : c'est la fenêtre que le coup achète.
var _sonne: float = 0.0

@onready var _forme: CollisionShape2D = $Forme
@onready var _etiquette: Label = $Etiquette


## Le code ne pose que ce qui dépend du genre — c'est-à-dire du fil qu'on avait
## sur les bras en se couchant. Tout le reste est dans la scène.
static func creer(p_genre: int, p_fil: Fil) -> Monstre:
	if _scene == null:
		_scene = load(CHEMIN_SCENE)

	var m: Monstre = _scene.instantiate()
	m.genre = p_genre
	m.fil = p_fil

	var r: Dictionary = REGLAGES[p_genre]
	m.pv = r["pv"]
	m.rayon = float(r["rayon"])
	m.vitesse = float(r["vitesse"])
	m.couleur = r["couleur"]

	return m


## La taille est la seule chose que la scène ne peut pas porter : elle change
## avec le genre, donc le corps et l'étiquette se calent ici.
func _ready() -> void:
	var cercle := _forme.shape.duplicate() as CircleShape2D
	cercle.radius = rayon
	_forme.shape = cercle

	_etiquette.text = nom_affiche()
	_etiquette.position = Vector2(-100.0, -rayon - 34.0)


## Ce que le monstre dit de lui-même. La chose sans nom ne dit rien : c'est tout
## son intérêt, et l'afficher détruirait le §6 d'un seul coup.
func nom_affiche() -> String:
	if genre == Genre.CHOSE:
		return "?"
	return fil.nom if fil != null else "?"


func invincible() -> bool:
	return genre == Genre.CHOSE


func viser(cible: Node2D) -> void:
	_cible = cible


func _physics_process(delta: float) -> void:
	_repos_contact = maxf(_repos_contact - delta, 0.0)
	if _flash_touche > 0.0:
		_flash_touche = maxf(_flash_touche - delta, 0.0)
		queue_redraw()

	if _sonne > 0.0:
		_sonne -= delta
		velocity = velocity.move_toward(Vector2.ZERO, FREIN_RECUL * delta)
		move_and_slide()
		queue_redraw()
		return

	if _cible == null or not is_instance_valid(_cible):
		return

	var vers := _cible.global_position - global_position
	var distance := vers.length()

	velocity = vers.normalized() * vitesse
	move_and_slide()

	if distance > rayon + 18.0 or _repos_contact > 0.0:
		return

	var reveur := _cible as Reveur
	# On traverse sans rien laisser, et on ne consomme pas le repos : si l'élan
	# se termine encore dans la masse, elle reprend au premier pas. Passer au
	# travers ne coûte rien, mais ça coûte l'élan — et sa recharge.
	if reveur == null or reveur.intouchable():
		return

	_repos_contact = 0.8
	if genre == Genre.CHOSE:
		a_reveille.emit()
	else:
		reveur.encaisser(global_position)


## Encaisser un coup. Renvoie vrai si ça a servi à quelque chose — taper la
## chose sans nom ne sert à rien, et il faut que ça se sente dans la main.
##
## Elle est maintenant la seule à ne pas broncher : tout le reste part en arrière
## et s'arrête une fraction de seconde. On comprend qu'elle est d'une autre nature
## au premier coup, sans qu'une ligne d'interface ait à le dire.
func encaisser(depuis: Vector2) -> bool:
	if invincible():
		_flash_touche = DUREE_FLASH
		queue_redraw()
		return false

	pv -= 1
	_flash_touche = DUREE_FLASH
	_sonne = float(REGLAGES[genre]["sonne"])
	var fuite := global_position - depuis
	velocity = fuite.normalized() * float(REGLAGES[genre]["recul"])
	queue_redraw()
	if pv <= 0:
		abattu.emit(self)
		queue_free()
	return true


## Ce que fait un ancré : il écarte et il retient, il ne tue pas. Aucun PV ne
## part, donc la nuit reste entièrement à jouer à la main — l'ancré achète du
## temps et de la place, pas des morts.
##
## Renvoie vrai si ça a mordu. La chose sans nom n'est pas concernée : un
## dispositif ne règle pas ce qu'on a laissé tomber, il faut aller le ramasser
## dans la journée.
func repousser(centre: Vector2, duree: float) -> bool:
	if invincible():
		return false

	# On prolonge sans jamais raccourcir : un ancré déclenché sur une cible déjà
	# sonnée par un coup ne doit pas écourter ce que le coup avait acheté.
	_sonne = maxf(_sonne, duree)
	var fuite := global_position - centre
	# Pile au centre, il n'y a pas de direction : on prend la première venue
	# plutôt que de laisser un `normalized()` nul le clouer sur place.
	if fuite.is_zero_approx():
		fuite = Vector2.RIGHT
	velocity = fuite.normalized() * POUSSEE_ANCRE
	queue_redraw()
	return true


func _draw() -> void:
	var c := couleur
	# Le coup gonfle la cible en plus de la blanchir : à cette taille, un simple
	# changement de teinte sur 0,1 s passait inaperçu.
	var enfle := 0.0
	if _flash_touche > 0.0:
		c = Color(1, 1, 1) if not invincible() else Color(0.35, 0.3, 0.36)
		enfle = rayon * 0.22 * (_flash_touche / DUREE_FLASH)
	elif _sonne > 0.0:
		c = couleur.lightened(0.25)
	draw_circle(Vector2.ZERO, rayon + enfle, c)

	if invincible():
		# Rien à lire dessus : pas de jauge, pas de progression. On ne sait pas
		# ce que c'est et on ne sait pas si on en vient à bout, parce qu'on n'en
		# vient pas à bout.
		draw_arc(Vector2.ZERO, rayon + 8.0, 0.0, TAU, 32, Color(0.5, 0.45, 0.5, 0.35), 2.0)
		return

	# Les points de vie en pastilles : lisible sans interface, et ça dit d'un
	# coup d'œil qu'une corvée tenace n'est pas une corvée.
	var total: int = REGLAGES[genre]["pv"]
	for i in total:
		var x := (float(i) - float(total - 1) / 2.0) * 9.0
		var plein := i < pv
		draw_circle(
			Vector2(x, -rayon - 12.0), 3.5,
			Color(1, 1, 1, 0.85) if plein else Color(1, 1, 1, 0.18)
		)
