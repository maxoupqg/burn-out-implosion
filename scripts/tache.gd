class_name Tache
extends RefCounted

## Une tâche vivante dans une partie (§3). L'unité concrète, exécutable dans
## une pièce. Coûte du temps.
##
## La faire ne ferme jamais son fil : ça repousse juste sa prochaine
## apparition. Même découpage que `Fil` — `def` est le contenu, le reste est
## l'état de la semaine en cours.

var def: TacheDef

# --- État de la run ---------------------------------------------------------

## Premier jour où la tâche réapparaît.
var disponible_le: int = 1
## En attente de sa tâche mère. Elle n'existe pas encore dans le monde.
var bloquee: bool = false
## One-shot déjà faite : elle ne revient plus.
var terminee: bool = false

# --- Lecture de la définition -----------------------------------------------

var id: String:
	get:
		return def.id

var nom: String:
	get:
		return def.nom

var cout_base: float:
	get:
		return def.cout_base

var recurrence_jours: int:
	get:
		return def.recurrence_jours

var delai_prerequis: int:
	get:
		return def.delai_prerequis

## Identifiant du domaine dont elle relève. Vide si le `.tres` est incomplet —
## `Contenu` le signale au démarrage plutôt que de laisser planter.
var fil_id: String:
	get:
		return def.fil.id if def.fil != null else ""


## Une tâche neuve. Celle qui attend une tâche mère naît fermée : elle
## n'apparaît dans aucune pièce tant que le travail amont n'est pas fait.
static func depuis(p_def: TacheDef) -> Tache:
	var tache := Tache.new()
	tache.def = p_def
	tache.bloquee = p_def.prerequis != null
	return tache


func une_seule_fois() -> bool:
	return def.recurrence_jours <= 0


func est_disponible(jour: int) -> bool:
	return not terminee and not bloquee and jour >= disponible_le
