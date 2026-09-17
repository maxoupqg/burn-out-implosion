class_name PointBesoin
extends Interactif

## Le meuble qui répond à un besoin du corps (§18). Frère de `PointInteraction`,
## et pas une variante de celui-ci.
##
## Les deux partagent `Interactif` — une adresse dans une pièce, une étiquette,
## une barre qui se remplit pendant que le temps part — et rien d'autre. Un
## besoin n'a pas de fil, donc pas de case, pas de tension, pas d'échéance et
## pas de délégataire : `delegable()` reste à false, et c'est une règle, pas un
## oubli. On ne fait pas boire quelqu'un à sa place.

## Plein ou presque. Une couleur d'eau, qui n'appelle pas.
const COULEUR_PLEIN := Color(0.45, 0.68, 0.85)
## À sec. La même que le rouge de fin : à partir d'ici, le compteur tourne.
const COULEUR_A_SEC := Color(1.0, 0.35, 0.28)
## En dessous de cette part de réserve, le meuble se met à insister.
const SEUIL_BAS := 0.3

## Le besoin que ce meuble satisfait. On y glisse un `.tres` de
## `donnees/besoins/`, comme on glisse une tâche sur un meuble.
@export var besoin_def: BesoinDef
@export var nom_meuble: String = "Meuble"

@onready var _pastille: Polygon2D = $Pastille


func besoin() -> Besoin:
	return Partie.besoins.get(besoin_def.id) if besoin_def != null else null


func disponible() -> bool:
	return Partie.peut_satisfaire(besoin())


func _executer() -> float:
	var b := besoin()
	var cout := Partie.cout_reel(b.cout_base)
	if not Partie.satisfaire_besoin(b.id):
		return -1.0
	return cout


func rafraichir() -> void:
	var b := besoin()

	if b == null:
		_pastille.visible = false
		_etiquette.text = nom_meuble
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	# Plein, le meuble s'éteint. C'est son extinction qui dit « ça va » — et son
	# rallumage qui apprend au joueur que boire a un moment, sans qu'aucune
	# ligne de texte ait à le lui expliquer.
	if b.plein():
		_pastille.visible = false
		_etiquette.text = "%s\nça va" % nom_meuble
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	var part := b.part()
	var couleur := COULEUR_PLEIN
	if b.a_sec():
		couleur = COULEUR_A_SEC
	elif part < SEUIL_BAS:
		couleur = COULEUR_PLEIN.lerp(COULEUR_A_SEC, 0.6)

	_pastille.visible = true
	_pastille.color = couleur

	# Pas de coût affiché : il est nul, et l'écrire ferait croire que le geste
	# est le prix. Le prix était le détour jusqu'ici, et il vient d'être payé.
	_etiquette.text = "%s\nE — %s" % [nom_meuble, b.verbe]
	_etiquette.modulate = couleur if part < SEUIL_BAS else Color(1, 1, 1)
