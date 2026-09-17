class_name Contenu
extends RefCounted

## Le contenu de la semaine, séparé des règles. `partie.gd` dit comment le jeu
## marche ; ce fichier dit seulement où trouver avec quoi on joue.
##
## Un `.tres` par fil et par tâche, dans `res://donnees/`. Ajouter du contenu,
## c'est créer un fichier dans le bon dossier — pas toucher au code. Ce qui est
## chargé ici est en lecture seule : `fils()` et `taches()` renvoient des
## objets de partie neufs, c'est ce qui permet de recommencer sans traîner
## l'état de la précédente.

const DOSSIER_FILS := "res://donnees/fils"
const DOSSIER_TACHES := "res://donnees/taches"
const DOSSIER_BESOINS := "res://donnees/besoins"

## Où un fil lâché peut tomber. Le plan complet est Cuisine ↔ Salon ↔ Salle de
## bain, plus la Chambre qui pend au salon — mais la chambre n'est pas là.
##
## Elle est la seule pièce qu'on traverse forcément, matin et soir : un fil
## tombé dedans serait revu tous les jours, donc jamais oublié. Ce serait
## l'exact contraire du §6, dont tout l'intérêt est de ne pas savoir où.
const PIECES := ["cuisine", "salon", "salle_de_bain"]


## Où tombe un fil qu'on vient de lâcher. Au hasard : la charge mentale ne
## range pas ce qu'elle laisse tomber.
static func piece_au_hasard() -> String:
	return String(PIECES.pick_random())


static func fils() -> Array[Fil]:
	var defs := _charger(DOSSIER_FILS)

	# Ordre stable, et lisible : la semaine dans l'ordre où elle arrive. Le
	# bandeau s'en sert, et le §7 aussi — c'est le dernier fil ouvert qui tombe
	# quand on se lève avec une tête trop petite.
	defs.sort_custom(func(a: FilDef, b: FilDef) -> bool:
		if a.jour_arrivee != b.jour_arrivee:
			return a.jour_arrivee < b.jour_arrivee
		return a.id < b.id
	)

	var liste: Array[Fil] = []
	for def: FilDef in defs:
		liste.append(Fil.depuis(def))
	return liste


static func taches() -> Array[Tache]:
	var defs := _charger(DOSSIER_TACHES)
	defs.sort_custom(func(a: TacheDef, b: TacheDef) -> bool: return a.id < b.id)

	var liste: Array[Tache] = []
	for def: TacheDef in defs:
		# Une tâche sans fil ne serait rattachée à rien : elle n'apparaîtrait
		# nulle part et empêcherait son domaine de se clore. Autant le dire.
		if def.fil == null:
			push_warning("Tâche « %s » sans fil : elle ne sera pas jouable." % def.id)
			continue
		liste.append(Tache.depuis(def))
	return liste


## Les besoins du corps (§18). Aucun tri utile : ils ne s'ordonnent ni par
## arrivée ni par dépendance — un corps n'a pas de calendrier. L'ordre des
## identifiants suffit à rendre l'affichage stable d'une partie à l'autre.
static func besoins() -> Array[Besoin]:
	var defs := _charger(DOSSIER_BESOINS)
	defs.sort_custom(func(a: BesoinDef, b: BesoinDef) -> bool: return a.id < b.id)

	var liste: Array[Besoin] = []
	for def: BesoinDef in defs:
		# Une capacité nulle ferait un besoin à sec dès la première seconde, donc
		# une partie perdue d'avance sans que rien ne l'explique.
		if def.capacite <= 0.0:
			push_warning("Besoin « %s » sans capacité : ignoré." % def.id)
			continue
		liste.append(Besoin.depuis(def))
	return liste


## Charge tous les `.tres` d'un dossier. Les identifiants vides ou en double
## sont signalés ici : ce sont les deux seules façons de casser le contenu, et
## elles seraient invisibles autrement — la partie se lancerait, un fil
## manquerait, et rien ne le dirait.
static func _charger(dossier: String) -> Array[Resource]:
	var defs: Array[Resource] = []
	var vus := {}

	for fichier in DirAccess.get_files_at(dossier):
		# À l'export, Godot convertit les ressources texte en binaire et laisse
		# un `.remap` : c'est le nom d'origine qu'il faut charger.
		var nom_fichier := fichier.trim_suffix(".remap")
		if not nom_fichier.ends_with(".tres"):
			continue

		# Volontairement non typé : `id` n'existe que sur les scripts de
		# définition, pas sur `Resource`, et le typer ferait échouer la
		# compilation sur les lignes suivantes.
		var def = ResourceLoader.load(dossier.path_join(nom_fichier))
		if def == null:
			continue

		if String(def.id).is_empty():
			push_warning("%s n'a pas d'identifiant : ignoré." % nom_fichier)
			continue
		if vus.has(def.id):
			push_warning("Identifiant « %s » en double : %s ignoré." % [def.id, nom_fichier])
			continue

		vus[def.id] = true
		defs.append(def)

	return defs
