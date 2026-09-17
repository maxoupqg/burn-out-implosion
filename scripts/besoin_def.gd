class_name BesoinDef
extends Resource

## La définition d'un besoin du corps (§18). Un `.tres` par besoin dans
## `res://donnees/besoins/`.
##
## **Un besoin n'est pas une tâche, et ne doit jamais le devenir.** `TacheDef`
## exige un fil (« une tâche sans fil n'existe pas ») et le survival system n'en
## a pas. Faire passer la soif par une tâche lui donnerait une case, une tension,
## une échéance et un délégataire — or on ne délègue pas sa soif. D'où ce type à
## part, qui ne partage avec les tâches que le fait d'avoir une adresse dans le
## monde.
##
## Ajouter la faim, plus tard, c'est déposer un `.tres` de plus ici et poser un
## meuble dans une pièce. Aucune ligne de code.

@export var id: String = ""
@export var nom: String = "Un besoin"
## Ce qu'on fait pour le satisfaire. Affiché sur le meuble, à la place du coût :
## le coût, justement, n'est pas là où on croit.
@export var verbe: String = "y répondre"

## Réserve du corps, comptée en unités de temps consommées. Elle descend en
## agissant, pas en dormant : une journée pleine assèche, une journée molle
## non. Sur un budget de 15, une capacité de 12 oblige à passer boire une fois
## dans la journée — sans jamais dire quand, et c'est tout l'intérêt.
@export var capacite: float = 12.0
## Le geste lui-même. À zéro pour la soif, et il faut que ça le reste : le prix
## de boire n'est pas le verre, c'est le détour jusqu'à la pièce — déjà facturé
## au tarif du jour par le §9. Dès que la soif coûte du vrai temps, c'est de la
## faim en plus petit et elle ne prouve plus rien.
@export var cout_base: float = 0.0

@export_group("Accès")
## Le geste est-il possible sans avoir rien fait avant ? Un robinet, oui : il
## coule depuis toujours. Un repas, non — il faut l'avoir cuisiné.
##
## Un besoin fermé au départ exige donc une tâche qui l'ouvre (`EffetBesoin`) et
## qui soit atteignable dès le premier jour, sinon le corps meurt sans recours.
@export var accessible_au_depart: bool = true
## Ce que le meuble dit quand il n'y a rien à prendre. C'est le seul endroit où
## le jeu explique pourquoi la table est éteinte alors qu'on a faim — sans ça, le
## joueur croit à un meuble décoratif et ne cherche pas la tâche qui l'allume.
@export var absence: String = ""
## Nuits pendant lesquelles l'accès tient une fois qu'une tâche l'a ouvert.
##
## 0 = il ne se referme jamais tout seul, c'est le robinet. 1 = le repas ne
## survit pas à la nuit. Sans ce compteur, cuisiner une fois ouvrirait l'accès
## pour toujours et le besoin sortirait du jeu dès le deuxième jour.
@export var jours_avant_peremption: int = 0

@export_group("À sec")
## Crans d'humeur perdus par unité de temps consommée la réserve vide.
##
## Rien ne se déclenche avant zéro. Conséquence assumée : un joueur qui passe
## boire ne perdra **jamais** un seul cran. Ce système ne mord que la
## négligence, et il ne s'excuse pas de mordre fort quand elle arrive.
@export var humeur_par_unite: float = 1.0
## Jours à sec avant que ça s'arrête pour de bon. 0 = ce besoin ne tue pas.
@export var jours_avant_fatal: int = 3

@export_group("Ce que ça dit")
## Affiché chaque matin tant que la réserve est vide, avec le décompte des jours
## restants ajouté derrière.
##
## Une fin annoncée est une règle ; une fin découverte au moment où elle tombe
## est un piège. Le playtest externe reproche déjà au jeu ce qui ne se voit
## pas — on ne va pas y ajouter une mort muette.
@export var alerte: String = "Tu n'as pas bu."
@export_multiline var titre_fin: String = "Tu ne t'es pas relevé."
@export_multiline var sous_titre_fin: String = ""
