class_name Dispositif
extends Interactif

## L'objet posé dans une pièce qui porte un fil ancré (§3).
##
## Chaque emplacement est typé pour un fil précis : le tableau des menus ne
## prend que « Les repas ». Ça encode gratuitement la règle du §9 — un
## dispositif dans la mauvaise pièce ne fonctionne pas.

const COULEUR_LIBRE := Color(0.38, 0.42, 0.5)
const COULEUR_PRET := Color(0.55, 0.78, 0.6)
const COULEUR_ANCRE := Color(0.42, 0.66, 0.88)
const COULEUR_REGLE := Color(0.45, 0.72, 0.55)
const COULEUR_USE := Color(0.72, 0.5, 0.28)
const COULEUR_BLOQUE := Color(1.0, 0.4, 0.35)

## Le fil que cet emplacement accepte. On y glisse un `.tres` de
## `donnees/fils/`. Un emplacement typé encode gratuitement la règle du §9.
@export var fil_def: FilDef
@export var nom_dispositif: String = "Dispositif"
## Ce dispositif fait-il le travail, ou se contente-t-il de s'en souvenir ?
##
## Un prélèvement automatique paie vraiment : plus de courrier à ouvrir, plus
## de virement, le fil sort du jeu. Un tableau des menus ne cuisine pas — il
## rappelle, et il s'use. La propriété est ici et pas sur le fil : c'est
## l'objet qui travaille ou non, et un même domaine pourra un jour avoir les
## deux (un pense-bête et une vraie automatisation).
@export var definitif: bool = false
## Ce que coûte la mise en place, en unités de temps, avant multiplicateur.
## Réglable par emplacement : un prélèvement automatique ne se monte pas au
## même prix qu'un tableau qu'on accroche au mur. Valeur en dur et pas
## `Partie.COUT_ANCRAGE` : l'autoload n'existe pas dans l'éditeur.
@export var cout_ancrage: float = 4.0

@onready var _panneau: Polygon2D = $Panneau


func fil() -> Fil:
	return Partie.fils.get(fil_def.id) if fil_def != null else null


func ancre() -> bool:
	var f := fil()
	return f != null and f.etat == Fil.Etat.ANCRE


## Le fil que ce dispositif a réglé pour de bon. On ne le teste que sur un
## dispositif définitif : un fil temporaire fermé tout seul n'appartient à
## personne, et son emplacement doit rester muet.
func regle() -> bool:
	var f := fil()
	return definitif and f != null and f.etat == Fil.Etat.FERME


func disponible() -> bool:
	return fil_def != null and Partie.peut_ancrer(fil_def.id, cout_ancrage)


func _executer() -> float:
	var cout := Partie.cout_reel(cout_ancrage)
	if not Partie.ancrer_fil(fil_def.id, cout_ancrage, definitif):
		return -1.0
	return cout


func rafraichir() -> void:
	var f := fil()

	if f == null:
		_etiquette.text = nom_dispositif
		_etiquette.modulate = Color(1, 1, 1, 0.3)
		return

	# Rien à entretenir, rien à surveiller : la machine s'en charge. C'est le
	# seul endroit du jeu où quelque chose est vraiment fini.
	if regle():
		_panneau.color = COULEUR_REGLE
		_etiquette.text = "%s\nça se fait tout seul" % f.nom
		_etiquette.modulate = Color(1, 1, 1, 0.75)
		return

	# Un fil ancré reste visible, accroché à son dispositif (§3).
	# Sa tension devient l'usure du dispositif : à bout, il décroche.
	if ancre():
		var use := f.tension >= Fil.TENSION_SEUIL - 1
		_panneau.color = COULEUR_USE if use else COULEUR_ANCRE
		_etiquette.text = "%s\n%s" % [f.nom, "va lâcher" if use else "en place"]
		_etiquette.modulate = COULEUR_BLOQUE if use else Color(1, 1, 1, 0.75)
		return

	if disponible():
		_panneau.color = COULEUR_PRET
		# Dire lequel des deux on achète, avant de payer. Sans cette ligne, la
		# différence entre « ça se fait tout seul » et « à entretenir » ne se
		# découvre qu'après coup, et elle vaut deux unités de temps.
		_etiquette.text = "%s : ancrer « %s »   %.1f\n%s" % [
			nom_dispositif,
			f.nom,
			Partie.cout_reel(cout_ancrage),
			"tu n'y touches plus" if definitif else "à entretenir",
		]
		_etiquette.modulate = Color(1, 1, 1)
		return

	# Indisponible : dire pourquoi, c'est ce qui apprend la règle du §5.
	_panneau.color = COULEUR_LIBRE
	_etiquette.modulate = COULEUR_BLOQUE
	if not f.ancrable:
		# Le §8 en une ligne : un dispositif ne marche que sur du prévisible.
		_etiquette.text = "%s : ça ne se délègue pas" % nom_dispositif
	elif f.etat != Fil.Etat.OUVERT:
		_etiquette.text = nom_dispositif
		_etiquette.modulate = Color(1, 1, 1, 0.3)
	elif Partie.cases_occupees() >= Partie.slots:
		_etiquette.text = "%s : aucune case libre" % nom_dispositif
	else:
		_etiquette.text = "%s : pas assez de temps" % nom_dispositif
