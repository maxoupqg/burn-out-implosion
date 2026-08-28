class_name Tache
extends RefCounted

## L'unité concrète, exécutable dans une pièce (§3). Coûte du temps.
## La faire ne ferme jamais son fil : ça repousse juste sa prochaine apparition.
##
## Sauf récurrence 0 : la tâche est alors un one-shot. C'est ce qui permet à un
## imprévu d'être réellement réglé — on ne « gère » pas un gosse malade
## indéfiniment, on le soigne.

var id: String
var fil_id: String
var nom: String
var cout_base: float
var recurrence_jours: int
## Premier jour où la tâche réapparaît.
var disponible_le: int = 1
## One-shot déjà faite : elle ne revient plus.
var terminee: bool = false


func _init(p_id: String, p_fil_id: String, p_nom: String, p_cout_base: float, p_recurrence_jours: int) -> void:
	id = p_id
	fil_id = p_fil_id
	nom = p_nom
	cout_base = p_cout_base
	recurrence_jours = p_recurrence_jours


func une_seule_fois() -> bool:
	return recurrence_jours <= 0


func est_disponible(jour: int) -> bool:
	return not terminee and jour >= disponible_le
