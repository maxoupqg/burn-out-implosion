class_name Lit
extends Interactif

## Aller se coucher (§7). Le seul meuble qui ne coûte rien et qui décide de
## tout : c'est lui qui met fin à la journée, et depuis le §16 c'est lui qui
## ouvre la nuit.
##
## **Disponible à toute heure, et c'est le point.** Le §7 veut que l'heure du
## coucher soit une décision — « ma dernière unité de temps : une tâche de plus,
## ou fermer un fil pour dormir correctement ? ». Se coucher à midi doit donc
## rester possible, avec tout ce que ça abandonne. Le lit ne refuse jamais.
##
## Il ne fait pas le travail lui-même : il le demande. La nuit se monte au
## niveau de la scène de jeu, qui seule peut endormir le monde.

const COULEUR_DRAP := Color(0.5, 0.5, 0.58)
const COULEUR_DRAP_FINIE := Color(0.3, 0.3, 0.34)

## On va se coucher. C'est `main.gd` qui décide de ce qui se passe ensuite —
## une nuit jouée, ou le barème du §7.
signal coucher_demande

@onready var _matelas: Polygon2D = $Matelas


func disponible() -> bool:
	return not Partie.finie


func _executer() -> float:
	coucher_demande.emit()
	# Gratuit : la journée est finie, il n'y a plus rien avec quoi la payer.
	return 0.0


func rafraichir() -> void:
	if Partie.finie:
		_matelas.color = COULEUR_DRAP_FINIE
		_etiquette.text = ""
		return

	_matelas.color = COULEUR_DRAP
	_etiquette.modulate = Color(1, 1, 1)

	# On annonce ce qu'on emporte, jamais ce qu'on va y gagner.
	#
	# Le §7 mettait sa ligne *après* la nuit : « nuit agitée — 5 cases demain ».
	# Depuis le §16 la nuit se joue, donc ce résultat n'est plus promis à
	# personne, et l'annoncer serait mentir. La déplacer *avant* la décision est
	# de toute façon plus fort : ça transforme un bilan en choix.
	var cases := Partie.cases_occupees()
	if cases == 0:
		_etiquette.text = "Lit : se coucher   ·   la tête est vide"
	else:
		_etiquette.text = "Lit : se coucher   ·   tu emportes %d case%s" % [
			cases, "s" if cases > 1 else "",
		]
