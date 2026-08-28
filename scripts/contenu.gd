class_name Contenu
extends RefCounted

## Le contenu de la semaine, séparé des règles. `partie.gd` dit comment le jeu
## marche ; ce fichier dit avec quoi on joue.
##
## La semaine est écrite pour monter : deux fils lundi, un de plus mardi,
## un de plus mercredi avec une échéance, et jeudi l'imprévu qui n'était pas
## au programme. C'est le jour 4 ou 5 qui doit faire mal.

## Les pièces du logement, dans l'ordre du plan : Cuisine ↔ Salon ↔ Salle de
## bain. Aller de la cuisine à la salle de bain se paie donc deux fois (§9).
const PIECES := ["cuisine", "salon", "salle_de_bain"]


## Où tombe un fil qu'on vient de lâcher. Au hasard : la charge mentale ne
## range pas ce qu'elle laisse tomber.
static func piece_au_hasard() -> String:
	return String(PIECES.pick_random())


## Renvoie des objets neufs à chaque appel : c'est ce qui permet de
## recommencer une partie sans traîner l'état de la précédente.
static func fils() -> Array[Fil]:
	var liste: Array[Fil] = []

	liste.append(Fil.new("repas", "Les repas"))
	liste.append(Fil.new("linge", "Le linge"))

	var courses := Fil.new("courses", "Les courses")
	courses.jour_arrivee = 2
	liste.append(courses)

	var factures := Fil.new("factures", "Les factures")
	factures.jour_arrivee = 3
	factures.jour_echeance = 6
	liste.append(factures)

	# L'imprévu. Non ancrable : aucun dispositif ne le porte à ta place, on
	# paie en personne. Temporaire : il se ferme quand c'est réglé. Et il
	# enfle deux fois plus vite, parce qu'on ne le remet pas à demain.
	var malade := Fil.new("malade", "Le petit est malade", false)
	malade.jour_arrivee = 4
	malade.annonce = false
	malade.temporaire = true
	malade.tension_par_nuit = 2
	liste.append(malade)

	for fil in liste:
		fil.etat = Fil.Etat.OUVERT if fil.jour_arrivee <= 1 else Fil.Etat.ENATTENTE

	return liste


static func taches() -> Array[Tache]:
	var liste: Array[Tache] = [
		# Cuisine
		Tache.new("cuisiner", "repas", "Faire à manger", 2.0, 1),
		Tache.new("vaisselle", "repas", "Vider le lave-vaisselle", 1.0, 1),
		Tache.new("liste", "courses", "Faire la liste", 1.0, 2),
		Tache.new("ranger_courses", "courses", "Ranger les courses", 1.5, 3),
		# Salle de bain
		Tache.new("machine", "linge", "Lancer une machine", 1.0, 2),
		Tache.new("etendre", "linge", "Étendre le linge", 2.0, 2),
		# Salon
		Tache.new("courrier", "factures", "Ouvrir le courrier", 1.0, 2),
		Tache.new("payer", "factures", "Payer les factures", 2.0, 3),
		# L'imprévu : cher, une seule fois, et éclaté dans les trois pièces.
		# C'est voulu : le jour où le petit est malade, on ne fait que marcher.
		Tache.new("temperature", "malade", "Prendre la température", 2.0, 0),
		Tache.new("medecin", "malade", "Appeler le médecin", 2.5, 0),
		Tache.new("sirop", "malade", "Préparer le sirop", 3.0, 0),
	]
	return liste
