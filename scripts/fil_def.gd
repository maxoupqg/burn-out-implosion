class_name FilDef
extends Resource

## La définition d'un fil (§3) : ce qu'il est, indépendamment de toute partie.
##
## Un `.tres` par fil dans `res://donnees/fils/`. Tout s'édite dans
## l'inspecteur, rien ici n'est écrit pendant qu'on joue — l'état de la run vit
## dans `Fil`. Sans cette séparation, jouer modifierait les fichiers de contenu
## et `Partie.reinitialiser()` ne servirait plus à rien.

## Identifiant stable. C'est lui qui sert de clé partout ailleurs.
@export var id: String = ""
@export var nom: String = "Un fil"
## Un dispositif ne marche que sur du prévisible (§8).
@export var ancrable: bool = true
## Jour où le fil entre dans la tête. Avant ça il est ENATTENTE.
@export var jour_arrivee: int = 1
## Jour où il est trop tard. 0 = pas d'échéance.
@export var jour_echeance: int = 0
## Se ferme quand toutes ses tâches sont faites. L'imprévu se gère, il ne
## s'endure pas.
@export var temporaire: bool = false
## Vitesse d'enflure. L'imprévu monte deux fois plus vite (§8).
@export var tension_par_nuit: int = 1
## Annoncé dans la météo (§11). L'imprévu, non — c'est sa définition.
@export var annonce: bool = true
