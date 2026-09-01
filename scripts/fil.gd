class_name Fil
extends RefCounted

## Un fil vivant dans une partie (§3). Ce n'est pas une tâche : c'est un
## domaine qui *génère* des tâches. Tant qu'il est ouvert, il occupe de la
## place.
##
## `def` dit ce que le fil est, une fois pour toutes ; cet objet dit ce qu'il
## est devenu cette semaine. Seul l'état ci-dessous change en cours de partie —
## tout le reste est en lecture seule, recopié depuis la définition.

enum Etat {
	ENATTENTE,  ## Pas encore arrivé dans la semaine. N'existe nulle part.
	OUVERT,     ## Dans la tête. Occupe des cases, compte dans le multiplicateur.
	ANCRE,      ## Dans le monde, accroché à un dispositif. Occupe zéro case.
	LACHE,      ## Tombé par terre. Plus dans la tête, plus affiché nulle part.
	FERME,      ## Réglé. Ne revient pas. Réservé aux fils temporaires.
	ECARTE,     ## Mis de côté volontairement (§5). Revient de force, et pire.
}

## Tension à partir de laquelle le fil prend une case supplémentaire.
const TENSION_SEUIL := 2

var def: FilDef

# --- État de la run ---------------------------------------------------------

var etat: Etat = Etat.OUVERT
## Monte d'un cran par journée où l'on a laissé traîner une de ses tâches,
## redescend d'un cran quand on est à jour. C'est ce qui rend « ne rien
## faire » ruineux en cases (§4).
var tension: int = 0
## Nuits passées au sol. Un fil oublié trop longtemps devient irrattrapable.
var jours_au_sol: int = 0
## Jour où un fil écarté revient dans la tête, qu'on ait fait de la place ou
## non. Sans date de retour, vider sa tête serait un bouton « supprimer ».
var jour_retour: int = 0
## Pièce où il est tombé (§6). Vide tant qu'il n'est pas par terre. Le jeu ne
## l'affiche jamais : c'est au joueur de se rappeler où il a lâché quoi.
var piece_id: String = ""

# --- Lecture de la définition -----------------------------------------------

var id: String:
	get:
		return def.id

var nom: String:
	get:
		return def.nom

var ancrable: bool:
	get:
		return def.ancrable

var jour_arrivee: int:
	get:
		return def.jour_arrivee

var jour_echeance: int:
	get:
		return def.jour_echeance

var temporaire: bool:
	get:
		return def.temporaire

var tension_par_nuit: int:
	get:
		return def.tension_par_nuit

var annonce: bool:
	get:
		return def.annonce


## Un fil neuf, tel qu'il commence la semaine.
static func depuis(p_def: FilDef) -> Fil:
	var fil := Fil.new()
	fil.def = p_def
	fil.etat = Etat.OUVERT if p_def.jour_arrivee <= 1 else Etat.ENATTENTE
	return fil


## Un fil qui pèse : dans la tête, ou accroché à un dispositif qui s'use.
func actif() -> bool:
	return etat == Etat.OUVERT or etat == Etat.ANCRE


## Nombre de cases occupées dans la tête. Un fil négligé enfle.
func taille() -> int:
	return 2 if tension >= TENSION_SEUIL else 1
