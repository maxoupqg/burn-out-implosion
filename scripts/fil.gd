class_name Fil
extends RefCounted

## Une préoccupation ouverte (§3). Ce n'est pas une tâche : c'est un domaine
## qui *génère* des tâches. Tant qu'il est ouvert, il occupe de la place.

enum Etat {
	ENATTENTE,  ## Pas encore arrivé dans la semaine. N'existe nulle part.
	OUVERT,     ## Dans la tête. Occupe des cases, compte dans le multiplicateur.
	ANCRE,      ## Dans le monde, accroché à un dispositif. Occupe zéro case.
	LACHE,      ## Tombé par terre. Plus dans la tête, plus affiché nulle part.
	FERME,      ## Réglé. Ne revient pas. Réservé aux fils temporaires.
}

## Tension à partir de laquelle le fil prend une case supplémentaire.
const TENSION_SEUIL := 2

var id: String
var nom: String
var ancrable: bool
var etat: Etat = Etat.OUVERT
## Monte d'un cran par journée où l'on a laissé traîner une de ses tâches,
## redescend d'un cran quand on est à jour. C'est ce qui rend « ne rien
## faire » ruineux en cases (§4).
var tension: int = 0

## Jour où le fil entre dans la tête. Avant ça il est ENATTENTE.
var jour_arrivee: int = 1
## Jour où il est trop tard. 0 = pas d'échéance.
var jour_echeance: int = 0
## Un fil temporaire se ferme quand toutes ses tâches sont faites : l'imprévu
## ne reste pas éternellement, mais il doit être géré.
var temporaire: bool = false
## Vitesse d'enflure. L'imprévu monte plus vite : une nuit d'inattention suffit.
var tension_par_nuit: int = 1
## Un fil annoncé apparaît dans la météo. L'imprévu, non — c'est tout l'objet.
var annonce: bool = true
## Nuits passées au sol. Un fil oublié trop longtemps devient irrattrapable.
var jours_au_sol: int = 0
## Pièce où il est tombé (§6). Vide tant qu'il n'est pas par terre. Le jeu ne
## l'affiche jamais : c'est au joueur de se rappeler où il a lâché quoi.
var piece_id: String = ""


func _init(p_id: String, p_nom: String, p_ancrable: bool = true) -> void:
	id = p_id
	nom = p_nom
	ancrable = p_ancrable


## Un fil qui pèse : dans la tête, ou accroché à un dispositif qui s'use.
func actif() -> bool:
	return etat == Etat.OUVERT or etat == Etat.ANCRE


## Nombre de cases occupées dans la tête. Un fil négligé enfle.
func taille() -> int:
	return 2 if tension >= TENSION_SEUIL else 1
