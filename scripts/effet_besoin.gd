class_name EffetBesoin
extends EffetTache

## Une tâche qui ouvre ou ferme l'accès à un besoin du corps (§18).
##
## Le robinet est toujours là ; le repas, non. Boire ne demande que de marcher
## jusqu'à l'évier, manger demande d'avoir cuisiné — et débarrasser la table
## reprend ce qu'on n'a pas mangé.
##
## Les deux sens sont dans la même ressource parce que c'est le même levier :
## séparer « ouvrir » et « fermer » en deux classes obligerait à les tenir en
## accord à la main le jour où l'accès se comptera autrement qu'en oui/non.
##
## Ça n'ajoute rien dans la réserve : cuisiner ne nourrit pas. La tâche rend le
## geste possible, le geste reste à faire, et il se paie à son meuble.

enum Geste {
	## Après cette tâche, le besoin se satisfait.
	OUVRE,
	## Après cette tâche, il ne se satisfait plus — même à moitié vide.
	FERME,
}

## Le besoin concerné. Une référence d'objet, pas un identifiant recopié : on la
## pose par glisser-déposer depuis `donnees/besoins/`.
@export var besoin: BesoinDef
@export var geste: Geste = Geste.OUVRE


func appliquer() -> void:
	if besoin == null:
		push_warning("EffetBesoin sans besoin : rien à ouvrir ni à fermer.")
		return
	var vivant: Besoin = Partie.besoins.get(besoin.id)
	if vivant == null:
		push_warning("EffetBesoin : aucun besoin « %s » dans la partie." % besoin.id)
		return
	if geste == Geste.OUVRE:
		vivant.ouvrir()
	else:
		vivant.fermer()


func annonce() -> String:
	if besoin == null:
		return ""
	if geste == Geste.OUVRE:
		return "puis %s" % besoin.verbe
	return "plus moyen de %s" % besoin.verbe
