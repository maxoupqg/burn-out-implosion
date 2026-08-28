extends CanvasLayer

## Le HUD-tête (§10) : les fils vivent en haut de l'écran, les tâches vivent
## dans le monde. La règle doit s'enseigner par la position, pas par du texte.

const LARGEUR_CASE := 130.0
const HAUTEUR_CASE := 34.0
const ESPACEMENT := 8.0

const JOURS := [
	"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche",
]
## Au-delà, on n'annonce pas : c'est encore trop loin pour peser.
const HORIZON_METEO := 3
## Un événement est dit une fois, puis plus jamais. C'est le principe du §6 :
## le jeu ne rappelle pas ce que tu as lâché, il te laisse le découvrir par terre.
const DUREE_FLASH := 4.0

const COULEUR_VIDE := Color(1, 1, 1, 0.12)
const COULEUR_NEGLIGE := Color(0.95, 0.55, 0.3)
const COULEUR_A_JOUR := Color(0.55, 0.78, 0.6)
const COULEUR_TENSION := Color(0.55, 0.12, 0.12)
const COULEUR_TEXTE_FIL := Color(0.1, 0.09, 0.11)
const COULEUR_CALME := Color(0.75, 0.78, 0.8)
const COULEUR_CRAME := Color(1.0, 0.35, 0.28)
const COULEUR_ECHEANCE := Color(1.0, 0.55, 0.4)

var _mult_precedent: float = 1.0
## `coucher()` émet quatre signaux d'affilée. Sans ce garde-fou on
## reconstruirait le bandeau quatre fois et on lancerait autant de tweens
## concurrents sur le multiplicateur.
var _sale: bool = true

var _flashs := PackedStringArray()
var _flash_restant: float = 0.0

@onready var _slots: HBoxContainer = $Slots
@onready var _mult: Label = $Multiplicateur
@onready var _jour: Label = $Jour
@onready var _temps: Label = $Temps
@onready var _meteo: Label = $Meteo


func _ready() -> void:
	Partie.fils_change.connect(_salir)
	Partie.taches_change.connect(_salir)
	Partie.temps_change.connect(_maj_temps)
	Partie.jour_change.connect(_maj_jour)

	Partie.fil_arrive.connect(func(fil: Fil) -> void: _flasher("%s, maintenant." % fil.nom))
	Partie.fil_ferme.connect(func(fil: Fil) -> void: _flasher("%s : réglé." % fil.nom))
	Partie.fil_deborde.connect(func(fil: Fil) -> void: _flasher("%s t'est tombé des mains." % fil.nom))
	Partie.fil_decroche.connect(func(fil: Fil) -> void: _flasher("%s : le dispositif a lâché." % fil.nom))

	_maj_temps(Partie.temps_restant)
	_maj_jour(Partie.jour)


func _salir() -> void:
	_sale = true


## Dit une fois, puis oublié.
func _flasher(texte: String) -> void:
	if _flash_restant <= 0.0:
		_flashs.clear()
	_flashs.append(texte)
	_flash_restant = DUREE_FLASH
	_sale = true


func _process(delta: float) -> void:
	if _flash_restant > 0.0:
		_flash_restant -= delta
		if _flash_restant <= 0.0:
			_flashs.clear()
			_sale = true

	if not _sale:
		return
	_sale = false
	_maj_tete()
	_maj_meteo()


func _maj_tete() -> void:
	for enfant in _slots.get_children():
		_slots.remove_child(enfant)
		enfant.queue_free()

	for fil in Partie.fils_ouverts():
		_slots.add_child(_case_fil(fil))

	for _i in Partie.cases_libres():
		var vide := ColorRect.new()
		vide.custom_minimum_size = Vector2(LARGEUR_CASE, HAUTEUR_CASE)
		vide.color = COULEUR_VIDE
		_slots.add_child(vide)

	var m := Partie.multiplicateur()
	_mult.text = "× %.1f" % m
	# Le multiplicateur doit être lisible en jouant, pas seulement après coup.
	var t := clampf(inverse_lerp(1.0, 1.8, m), 0.0, 1.0)
	_mult.add_theme_color_override("font_color", COULEUR_CALME.lerp(COULEUR_CRAME, t))

	# Le soulagement doit être franc (§10) : quand la charge retombe, ça se voit.
	if m < _mult_precedent:
		_souffler()
	_mult_precedent = m


func _souffler() -> void:
	_mult.pivot_offset = _mult.size / 2.0
	_mult.scale = Vector2(1.4, 1.4)
	var anim := create_tween()
	anim.tween_property(_mult, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Un fil négligé est plus large : il mange une case de plus. La règle se lit
## à l'écran sans qu'on ait à l'expliquer.
func _case_fil(fil: Fil) -> ColorRect:
	var taille := fil.taille()
	var case := ColorRect.new()
	case.custom_minimum_size = Vector2(
		LARGEUR_CASE * taille + ESPACEMENT * (taille - 1), HAUTEUR_CASE
	)
	case.color = COULEUR_NEGLIGE if Partie.fil_neglige(fil) else COULEUR_A_JOUR

	var nom := Label.new()
	nom.anchor_right = 1.0
	nom.anchor_bottom = 1.0
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nom.add_theme_font_size_override("font_size", 14)
	nom.add_theme_color_override("font_color", COULEUR_TEXTE_FIL)
	nom.text = fil.nom
	if fil.jour_echeance > 0:
		nom.text += "\navant %s" % _nom_jour(fil.jour_echeance)
		nom.add_theme_font_size_override("font_size", 12)
	case.add_child(nom)

	# Jauge de tension : ce qu'on va payer si on se couche là-dessus.
	if fil.tension > 0:
		var jauge := ColorRect.new()
		jauge.color = COULEUR_TENSION
		jauge.anchor_top = 1.0
		jauge.anchor_bottom = 1.0
		jauge.anchor_right = clampf(float(fil.tension) / float(Fil.TENSION_SEUIL), 0.0, 1.0)
		jauge.offset_top = -5.0
		case.add_child(jauge)

	return case


## Ce qui arrive et qu'on peut encore anticiper. L'imprévu n'y figure jamais —
## c'est précisément ce qui en fait un imprévu.
func _maj_meteo() -> void:
	# Ce qui vient d'arriver passe devant ce qui va arriver.
	if not _flashs.is_empty():
		_meteo.text = "   ·   ".join(_flashs)
		_meteo.modulate = COULEUR_CRAME
		return

	var annonces := PackedStringArray()

	for fil: Fil in Partie.fils.values():
		if fil.etat != Fil.Etat.ENATTENTE or not fil.annonce:
			continue
		var dans := fil.jour_arrivee - Partie.jour
		if dans > HORIZON_METEO:
			continue
		annonces.append("%s %s" % [
			fil.nom, "arrive demain" if dans <= 1 else "arrive dans %d jours" % dans
		])

	for fil: Fil in Partie.fils.values():
		if fil.jour_echeance <= 0 or not fil.actif():
			continue
		var reste := fil.jour_echeance - Partie.jour
		if reste < 0 or reste > HORIZON_METEO:
			continue
		annonces.append("%s : %s" % [
			fil.nom, "c'est aujourd'hui" if reste == 0 else "plus que %d jours" % reste
		])

	_meteo.text = "   ·   ".join(annonces)
	_meteo.modulate = COULEUR_ECHEANCE if annonces.size() > 1 else Color(1, 1, 1)


func _nom_jour(j: int) -> String:
	return JOURS[(j - 1) % JOURS.size()]


func _maj_temps(restant: float) -> void:
	_temps.text = "Temps  %.1f / %.0f" % [restant, Partie.temps_du_jour(Partie.jour)]


func _maj_jour(jour: int) -> void:
	_jour.text = _nom_jour(jour)
