class_name Besoin
extends RefCounted

## Un besoin vivant dans une partie (§18). Même découpage que `Fil` et
## `Tache` — `def` est le contenu, le reste est l'état de la run.
##
## La réserve est un capital de temps : on ne la perd pas au fil des heures,
## on la dépense en agissant. Une journée passée à courir assèche ; une journée
## où l'on n'a rien fait, non. C'est ce qui fait de « j'ai pas bu de la
## journée » un symptôme de dispersion et pas une négligence morale.

var def: BesoinDef

# --- État de la run ---------------------------------------------------------

## Ce qu'il reste dans le corps, en unités de temps.
var reserve: float = 0.0
## Nuits consécutives passées la réserve vide. C'est lui qui tue, pas la
## réserve : être à sec une heure avant de se coucher ne coûte qu'un cran.
var jours_a_sec: int = 0

# --- Lecture de la définition -----------------------------------------------

var id: String:
	get:
		return def.id

var nom: String:
	get:
		return def.nom

var verbe: String:
	get:
		return def.verbe

var capacite: float:
	get:
		return def.capacite

var cout_base: float:
	get:
		return def.cout_base

var humeur_par_unite: float:
	get:
		return def.humeur_par_unite


## Un besoin neuf. On commence le corps plein : le premier jour est l'état de
## grâce qu'on va perdre, pas un handicap de départ.
static func depuis(p_def: BesoinDef) -> Besoin:
	var besoin := Besoin.new()
	besoin.def = p_def
	besoin.reserve = p_def.capacite
	return besoin


func a_sec() -> bool:
	return reserve <= 0.0


func plein() -> bool:
	return reserve >= capacite


## Ce que la jauge affiche, entre 0 et 1.
func part() -> float:
	if capacite <= 0.0:
		return 0.0
	return clampf(reserve / capacite, 0.0, 1.0)


## Consomme des unités de temps et renvoie **la part vécue à sec** — celle qui
## va coûter de l'humeur.
##
## Le découpage compte : dépenser 5 unités avec 2 en réserve, c'est 2 unités
## couvertes puis 3 à sec. Sans ça, l'unité qui vide la réserve punirait comme
## si elle avait été entièrement subie, et le seuil deviendrait une falaise à
## l'endroit exact où le joueur ne peut plus rien anticiper.
func consommer(unites: float) -> float:
	var couvert := minf(reserve, unites)
	reserve -= couvert
	return unites - couvert


## Boire remplit tout. Pas de demi-mesure : le geste est gratuit, le doser
## n'ajouterait qu'une décision sans enjeu.
func remplir() -> void:
	reserve = capacite
	jours_a_sec = 0


## Jours restants avant que ça s'arrête. -1 si ce besoin ne tue pas.
func sursis() -> int:
	if def.jours_avant_fatal <= 0:
		return -1
	return maxi(def.jours_avant_fatal - jours_a_sec, 0)
