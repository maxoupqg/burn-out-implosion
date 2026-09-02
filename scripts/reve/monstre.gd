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

## Émis quand il tombe. La CHOSE ne l'émet jamais.
signal abattu(monstre: Monstre)
## La chose sans nom a touché le rêveur : la nuit s'arrête là.
signal a_reveille()

const REGLAGES := {
	Genre.CORVEE: {"pv": 2, "rayon": 18.0, "vitesse": 115.0, "couleur": Color(0.45, 0.5, 0.62)},
	Genre.TENACE: {"pv": 4, "rayon": 26.0, "vitesse": 132.0, "couleur": Color(0.78, 0.52, 0.3)},
	Genre.BOSS: {"pv": 9, "rayon": 42.0, "vitesse": 104.0, "couleur": Color(0.78, 0.32, 0.34)},
	Genre.CHOSE: {"pv": 0, "rayon": 30.0, "vitesse": 158.0, "couleur": Color(0.1, 0.09, 0.12)},
}

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
var _etiquette: Label = null


static func creer(p_genre: int, p_fil: Fil) -> Monstre:
	var m := Monstre.new()
	m.genre = p_genre
	m.fil = p_fil

	var r: Dictionary = REGLAGES[p_genre]
	m.pv = r["pv"]
	m.rayon = r["rayon"]
	m.vitesse = r["vitesse"]
	m.couleur = r["couleur"]

	m.collision_layer = 4
	# Les murs, et rien d'autre : deux monstres se traversent, et aucun ne
	# bouscule le rêveur. Le contact est un calcul de distance, pas une poussée.
	m.collision_mask = 1

	var forme := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = m.rayon
	forme.shape = cercle
	m.add_child(forme)

	m._etiquette = Label.new()
	m._etiquette.text = m.nom_affiche()
	m._etiquette.position = Vector2(-100.0, -m.rayon - 34.0)
	m._etiquette.size = Vector2(200.0, 24.0)
	m._etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m._etiquette.add_theme_font_size_override("font_size", 14)
	m._etiquette.modulate = Color(1, 1, 1, 0.45)
	m.add_child(m._etiquette)

	return m


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

	if _cible == null or not is_instance_valid(_cible):
		return

	var vers := _cible.global_position - global_position
	var distance := vers.length()

	velocity = vers.normalized() * vitesse
	move_and_slide()

	if distance <= rayon + 18.0 and _repos_contact <= 0.0:
		_repos_contact = 0.8
		if genre == Genre.CHOSE:
			a_reveille.emit()
		else:
			var reveur := _cible as Reveur
			if reveur != null:
				reveur.encaisser(global_position)


## Encaisser un coup. Renvoie vrai si ça a servi à quelque chose — taper la
## chose sans nom ne sert à rien, et il faut que ça se sente dans la main.
func encaisser() -> bool:
	if invincible():
		_flash_touche = 0.1
		queue_redraw()
		return false

	pv -= 1
	_flash_touche = 0.12
	queue_redraw()
	if pv <= 0:
		abattu.emit(self)
		queue_free()
	return true


func _draw() -> void:
	var c := couleur
	if _flash_touche > 0.0:
		c = Color(1, 1, 1) if not invincible() else Color(0.35, 0.3, 0.36)
	draw_circle(Vector2.ZERO, rayon, c)

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
