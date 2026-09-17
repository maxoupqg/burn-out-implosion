class_name PointInteraction
extends Interactif

## Le meuble qui porte une tâche. Les tâches vivent dans le monde (§10) :
## on ne les lit pas dans un menu, on va les chercher.

const COULEUR_ACTIF := Color(0.95, 0.55, 0.3)
const COULEUR_TROP_CHER := Color(1.0, 0.4, 0.35)

## La tâche que ce meuble porte. On y glisse un `.tres` de `donnees/taches/`.
@export var tache_def: TacheDef
@export var nom_meuble: String = "Meuble"

@onready var _pastille: Polygon2D = $Pastille


func tache() -> Tache:
	return Partie.taches.get(tache_def.id) if tache_def != null else null


func disponible() -> bool:
	return Partie.tache_active(tache())


func delegable() -> bool:
	return Partie.peut_deleguer(tache())


func _executer() -> float:
	var cout := Partie.cout_reel(tache().cout_base)
	if not Partie.faire_tache(tache_def.id):
		return -1.0
	return cout


func _deleguer() -> float:
	var cout := Partie.cout_reel(Partie.reglages.cout_delegation)
	if not Partie.deleguer_tache(tache_def.id):
		return -1.0
	return cout


func rafraichir() -> void:
	var t := tache()

	if t == null or not disponible():
		_pastille.visible = false
		_etiquette.text = nom_meuble
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	var cout := Partie.cout_reel(t.cout_base)
	_pastille.visible = true
	_pastille.color = COULEUR_ACTIF
	_etiquette.text = "%s   %.1f" % [t.nom, cout]

	# Ce que la tâche ouvre ou referme ailleurs. Sans cette ligne, faire à manger
	# et débarrasser se ressemblent : deux tâches d'un même fil, à deux prix. La
	# conséquence est le seul endroit où elles diffèrent, donc elle s'annonce
	# avant l'appui, pas après.
	var annonces := PackedStringArray()
	for effet: EffetTache in t.def.effets:
		if effet != null and effet.annonce() != "":
			annonces.append(effet.annonce())
	if not annonces.is_empty():
		_etiquette.text += "\n%s" % "   ·   ".join(annonces)

	# Une tâche déléguée qu'on n'a pas relancée revient ici, plein tarif, comme
	# si de rien n'était — pendant que sa case reste gelée dans la tête. Le lien
	# entre les deux doit se lire sur le meuble, sinon on paie les deux sans
	# jamais comprendre que c'est la même chose.
	var relance := Partie.relance_de(t.id)
	if relance != null:
		_etiquette.text += "\ndéjà chez %s%s" % [
			Partie.reglages.nom_delegataire,
			"   —   va le relancer" if relance.due(Partie.jour) else "",
		]
	# Le second verbe s'affiche sur la tâche elle-même : c'est en la regardant
	# qu'on doit voir qu'on peut ne pas la faire soi-même, et pour combien.
	# Quand la tête est pleine on le dit ici plutôt que de faire disparaître la
	# ligne : c'est comme ça qu'on apprend que déléguer prend une case.
	elif t.delegable:
		if Partie.cases_libres() > 0:
			# Les deux moitiés du prix, ensemble, et le fait que la seconde
			# revienne. Séparées, on croit déléguer pour 0,6 une tâche qui en
			# coûte 1,2 ; sans le « par jour », on croit avoir payé une fois.
			_etiquette.text += "\nF  déléguer   %.1f puis %.1f/jour" % [
				Partie.cout_reel(Partie.reglages.cout_delegation),
				Partie.cout_reel(Partie.reglages.cout_relance),
			]
		else:
			_etiquette.text += "\nF  déléguer : plus de place"
	# Une tâche qu'on n'a plus les moyens de faire aujourd'hui.
	_etiquette.modulate = COULEUR_TROP_CHER if cout > Partie.temps_restant else Color(1, 1, 1)
