class_name TacheDef
extends Resource

## La définition d'une tâche (§3). Un `.tres` par tâche dans
## `res://donnees/taches/`.
##
## Le fil et le prérequis sont des références d'objets, pas des identifiants
## recopiés : on les pose par glisser-déposer dans l'inspecteur, et une faute
## de frappe n'est plus possible.
##
## Pour placer la tâche dans le monde, on glisse ce `.tres` sur le
## `PointInteraction` du meuble qui la porte. Les tâches vivent dans le monde
## (§10) : leur adresse est celle d'un meuble, pas une ligne de code.

@export var id: String = ""
@export var nom: String = "Une tâche"
## Le domaine dont elle relève. Une tâche sans fil n'existe pas.
@export var fil: FilDef
@export var cout_base: float = 1.0
## Jours avant réapparition. 0 = one-shot, la tâche ne revient jamais.
@export var recurrence_jours: int = 1
## Peut-on la passer à quelqu'un d'autre (§4) ? Presque tout se délègue ; ce
## qui ne se délègue pas doit avoir une raison qu'on peut dire à voix haute.
@export var delegable: bool = true

@export_group("Enchaînement")
## La tâche qui ouvre celle-ci. Tant qu'elle n'est pas faite, celle-ci n'existe
## pas dans le monde : on ne vide pas un lave-vaisselle qu'on n'a pas rempli.
##
## Une tâche à prérequis n'a pas d'horaire propre — sa récurrence est ignorée.
## Ce n'est pas le calendrier qui la rend possible, c'est le travail déjà fait.
@export var prerequis: TacheDef
## Jours entre la tâche mère et l'ouverture de celle-ci. 0 = dans la foulée
## (le lave-vaisselle), 1 = le lendemain (le linge qui tourne la nuit).
@export var delai_prerequis: int = 0
