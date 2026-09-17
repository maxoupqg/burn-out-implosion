extends Node

## État global de la run. Autoload : accessible partout via `Partie`.
##
## Porte les deux ressources (§2), le calendrier de la semaine (§11) et le
## calcul de nuit (§7). Le contenu, lui, vit dans `contenu.gd`.

## Les noms de la semaine. Ici et pas dans le HUD : le jeu dit des dates
## ailleurs qu'en haut de l'écran — sur un fil à échéance, sur un miroir. Ce
## n'est pas un réglage : c'est un calendrier.
const NOMS_JOURS := [
	"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche",
]
const CHEMIN_REGLAGES := "res://donnees/reglages.tres"

signal temps_change(restant: float)
signal fils_change()
signal taches_change()
signal jour_change(jour: int)
## Un fil n'a pas pu entrer dans la tête : il tombe (§6).
signal fil_deborde(fil: Fil)
## Un dispositif qu'on n'a pas nourri a lâché : le fil remonte dans la tête.
signal fil_decroche(fil: Fil)
## Un fil arrive dans la semaine.
signal fil_arrive(fil: Fil)
## Un fil temporaire est réglé pour de bon.
signal fil_ferme(fil: Fil)
## On a décidé de ne plus y penser (§5).
signal fil_ecarte(fil: Fil)
## Et ça revient quand même.
signal fil_revient(fil: Fil)
## L'humeur a bougé (§18). Elle ne se remplit pas, elle se constate.
signal humeur_change(humeur: float)
## Une réserve du corps a bougé.
signal besoins_change()
## La run est terminée. `raison` vaut "effondrement", "semaine", ou
## l'identifiant du besoin qui a eu raison du corps.
signal partie_finie(raison: String)

## Tous les prix et tous les délais, éditables dans l'inspecteur (§2). Le reste
## de ce fichier ne contient plus un seul chiffre d'équilibrage : régler une
## semaine se fait dans `donnees/reglages.tres`, sans ouvrir un script.
var reglages: Reglages

var jour: int = 1
## Ces deux-là valent zéro tant que les réglages ne sont pas chargés :
## `reinitialiser()` leur donne leur vraie valeur dès `_ready`.
var temps_restant: float = 0.0
var slots: int = 0
## L'humeur (§18). Ce n'est pas un besoin, c'est le résultat de la façon dont
## on a joué. Elle ne s'achète nulle part — surtout pas au canapé : s'asseoir
## doit rester la chose qui n'avance rien, sinon le renoncement calculé, qui
## est le cœur validé du jeu, devient un calcul de rentabilité.
var humeur: float = 0.0
## Nombre de fois où l'on a réussi à ne rien faire. C'est le score.
var fois_assis: int = 0
## Journées où le canapé était libre et où l'on est reparti quand même.
## Zéro assise parce qu'on n'a jamais pu et zéro assise parce qu'on a calculé,
## ce n'est pas la même semaine.
var jours_refuses: int = 0
var finie: bool = false

var _canape_vu_libre: bool = false
var _assis_aujourdhui: bool = false

## id -> Fil
var fils: Dictionary = {}
## id -> Tache
var taches: Dictionary = {}
## id -> Besoin. Le corps (§18) : il ne prend aucune case et n'a aucun fil.
var besoins: Dictionary = {}
## Ce qu'on a délégué et qu'il faudra réclamer. Dans l'ordre où on l'a lâché :
## on relance ce qui traîne depuis le plus longtemps.
var relances: Array[Relance] = []


func _ready() -> void:
	# Avant tout le reste : sans réglages, il n'y a pas de premier jour. Un
	# fichier absent ou cassé ne doit pas empêcher de jouer — on repart sur les
	# valeurs écrites dans le script, et on le dit.
	reglages = ResourceLoader.load(CHEMIN_REGLAGES) as Reglages
	if reglages == null:
		push_warning("Réglages introuvables (%s) : valeurs par défaut." % CHEMIN_REGLAGES)
		reglages = Reglages.new()
	reinitialiser()


## Reconstruit une semaine neuve. Indispensable au redémarrage : recharger la
## scène ne touche pas à un autoload, et les anciens Fil traînent leur tension.
func reinitialiser() -> void:
	jour = 1
	slots = reglages.slots_base
	# Avant `temps_du_jour` : le budget dépend de l'humeur, et une humeur restée
	# à zéro d'une partie sur l'autre ferait démarrer lundi matin au plancher.
	humeur = reglages.humeur_max
	temps_restant = temps_du_jour(jour)
	fois_assis = 0
	jours_refuses = 0
	finie = false
	_canape_vu_libre = false
	_assis_aujourdhui = false

	fils.clear()
	taches.clear()
	besoins.clear()
	relances.clear()
	for fil in Contenu.fils():
		fils[fil.id] = fil
	for tache in Contenu.taches():
		taches[tache.id] = tache
	for besoin in Contenu.besoins():
		besoins[besoin.id] = besoin


# --- Lecture -----------------------------------------------------------------

func nom_jour(j: int) -> String:
	return NOMS_JOURS[(j - 1) % NOMS_JOURS.size()]


## Le budget d'une journée, humeur déduite (§18). Un cran perdu vaut une unité
## de temps en moins — pas un multiplicateur : celui-là appartient aux cases, et
## deux systèmes qui multiplient le même nombre deviennent illisibles.
func temps_du_jour(j: int) -> float:
	var base: float = reglages.temps_dimanche if j >= reglages.jours_semaine else reglages.temps_jour
	return maxf(reglages.temps_plancher, base - malus_humeur())


## Ce que l'humeur coûte aujourd'hui. Zéro tant qu'on est au maximum.
func malus_humeur() -> float:
	return maxf(reglages.humeur_max - humeur, 0.0) * reglages.temps_par_cran_humeur


## Le besoin qui vient d'avoir raison du corps, s'il y en a un.
func besoin_fatal() -> Besoin:
	for besoin: Besoin in besoins.values():
		if besoin.sursis() == 0:
			return besoin
	return null


## Ce que le corps a à dire, et qui doit se lire avant d'être subi. Vide tant
## qu'aucune réserve n'est à sec — ce qui est le cas normal.
##
## Une mort qu'on découvre au moment où elle tombe est un piège, pas une règle.
## Le seul reproche du playtest externe porte déjà sur ce que le jeu ne montre
## pas : on n'y ajoute pas un compte à rebours invisible.
func alerte_corps() -> String:
	var lignes := PackedStringArray()
	for besoin: Besoin in besoins.values():
		if not besoin.a_sec():
			continue
		var reste := besoin.sursis()
		if reste < 0:
			lignes.append(besoin.def.alerte)
		elif reste <= 1:
			lignes.append("%s Demain il sera trop tard." % besoin.def.alerte)
		else:
			lignes.append("%s Encore %d jours." % [besoin.def.alerte, reste])
	return "   ·   ".join(lignes)


func fils_ouverts() -> Array[Fil]:
	var ouverts: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.OUVERT:
			ouverts.append(fil)
	return ouverts


func fils_ecartes() -> Array[Fil]:
	var ecartes: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ECARTE:
			ecartes.append(fil)
	return ecartes


func fils_au_sol() -> Array[Fil]:
	var tombes: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.LACHE:
			tombes.append(fil)
	return tombes


## Cases réellement occupées dans la tête : un fil négligé en prend deux, et
## chaque relance en attente en prend une.
##
## C'est là, et nulle part ailleurs, que se paie la délégation (§4). « Il faut
## que je pense à lui redemander » n'est pas du travail restant : c'est une
## place prise dans la tête, et c'est exactement ce que le jeu raconte.
func cases_occupees() -> int:
	var total := relances_en_tete().size()
	for fil in fils_ouverts():
		total += fil.taille()
	return total


func cases_libres() -> int:
	return maxi(slots - cases_occupees(), 0)


func taches_du_fil(fil_id: String) -> Array[Tache]:
	var liste: Array[Tache] = []
	for tache: Tache in taches.values():
		if tache.fil_id == fil_id:
			liste.append(tache)
	return liste


## Les relances qui pèsent : celles dont le domaine est encore quelque part.
## Chacune prend une case, même sur un fil ancré — le dispositif se souvient du
## domaine, il ne se souvient pas qu'il faut relancer quelqu'un.
##
## Celles d'un fil tombé par terre n'y sont pas : elles dorment jusqu'à ce qu'on
## le ramasse. Le jeu ne dit jamais ce qu'on a lâché (§6), et ce n'est pas à
## l'autre de nous le rappeler.
func relances_en_tete() -> Array[Relance]:
	var portees: Array[Relance] = []
	for relance in relances:
		var fil: Fil = fils.get(relance.tache.fil_id)
		if fil != null and fil.actif():
			portees.append(relance)
	return portees


## Celles qu'on peut aller réclamer aujourd'hui. Celles du jour même n'y sont
## pas : on vient tout juste de demander.
func relances_dues() -> Array[Relance]:
	var dues: Array[Relance] = []
	for relance in relances_en_tete():
		if relance.due(jour):
			dues.append(relance)
	return dues


## La relance qui pèse sur cette tâche précise, s'il y en a une.
##
## Le meuble s'en sert pour dire que le travail est déjà parti chez quelqu'un.
## Sans ça, ne pas relancer est un piège muet : la tâche revient plein tarif sur
## son meuble, la case reste gelée dans la tête, et rien à l'écran ne relie les
## deux — le joueur paie les deux sans comprendre qu'il s'agit de la même chose.
func relance_de(tache_id: String) -> Relance:
	for relance in relances_en_tete():
		if relance.tache.id == tache_id:
			return relance
	return null


## Une relance qui traîne sur ce fil, réclamable ou pas encore.
func relance_en_attente(fil_id: String) -> bool:
	for relance in relances:
		if relance.tache.fil_id == fil_id:
			return true
	return false


## Une tâche n'existe dans le monde que si son fil est là. Tant que « Les
## courses » n'est pas arrivé, sa liste n'est pas à faire.
func tache_active(tache: Tache) -> bool:
	if tache == null or not tache.est_disponible(jour):
		return false
	var fil: Fil = fils.get(tache.fil_id)
	return fil != null and fil.actif()


## Un fil est négligé tant qu'une de ses tâches attend encore aujourd'hui.
##
## Une relance en attente n'entre pas là-dedans, et c'est délibéré : la tension
## dit « le travail n'a pas été fait », or une tâche déléguée a été faite. Si la
## relance faisait monter la tension, déléguer ferait décrocher les dispositifs,
## et le joueur qui délègue *et* ancre *et* relance se ferait punir pour avoir
## bien joué. Le prix de la délégation est en cases, pas ici.
func fil_neglige(fil: Fil) -> bool:
	for tache in taches_du_fil(fil.id):
		if tache.est_disponible(jour):
			return true
	return false


## Multiplicateur de charge (§2). Le couplage à sens unique : les cases
## pourrissent le temps, le temps n'achète jamais de cases. Le barème est dans
## les réglages.
func multiplicateur() -> float:
	return reglages.multiplicateur(cases_occupees())


func cout_reel(cout_base: float) -> float:
	return cout_base * multiplicateur()


# --- Actions -----------------------------------------------------------------

## Dépense du temps au tarif du jour. Renvoie false si la journée est trop
## entamée pour se le permettre.
func depenser_temps(cout_base: float) -> bool:
	var cout := cout_reel(cout_base)
	if cout > temps_restant:
		return false
	temps_restant -= cout
	temps_change.emit(temps_restant)
	_consommer_corps(cout)
	return true


## Le corps paie le temps réellement passé, multiplicateur compris : il ne sait
## pas pourquoi la journée a été longue, il sait qu'elle l'a été. C'est ce qui
## fait qu'une journée surchargée assèche plus vite qu'une journée calme, sans
## qu'aucune règle n'ait à le dire.
##
## Tant qu'il reste de la réserve, il ne se passe rien du tout. La punition ne
## commence qu'une fois à sec, et elle est vive : chaque unité vécue le gosier
## sec coûte un cran d'humeur, donc une unité de temps demain.
func _consommer_corps(consomme: float) -> void:
	if consomme <= 0.0 or besoins.is_empty():
		return

	var perdu := 0.0
	for besoin: Besoin in besoins.values():
		perdu += besoin.consommer(consomme) * besoin.humeur_par_unite

	besoins_change.emit()
	if perdu <= 0.0:
		return
	humeur = maxf(humeur - perdu, 0.0)
	humeur_change.emit(humeur)


## Boire, manger : le corps ne se négocie pas, donc il n'y a qu'un verbe et il
## n'a pas de variante. Rien à déléguer, rien à ancrer, rien à écarter.
func peut_satisfaire(besoin: Besoin) -> bool:
	if besoin == null or finie:
		return false
	# Rien à prendre : le repas n'a pas été fait, ou on vient de débarrasser. Le
	# besoin continue de se vider pendant ce temps-là — c'est précisément ce qui
	# fait qu'oublier de cuisiner coûte quelque chose.
	if not besoin.accessible:
		return false
	# Plein, le meuble s'éteint. Sans ça il resterait allumé en permanence et
	# n'apprendrait plus rien : c'est son extinction qui dit « ça va ».
	if besoin.plein():
		return false
	return cout_reel(besoin.cout_base) <= temps_restant


func satisfaire_besoin(besoin_id: String) -> bool:
	var besoin: Besoin = besoins.get(besoin_id)
	if not peut_satisfaire(besoin):
		return false
	# Payer d'abord, remplir ensuite : le geste lui-même se fait encore à sec,
	# et il doit être compté comme tel. À coût nul ça ne change rien ; le jour
	# où un besoin coûtera du temps, ça évitera une resquille d'une unité.
	if not depenser_temps(besoin.cout_base):
		return false

	besoin.remplir()
	besoins_change.emit()
	return true


## Faire une tâche (§4) : coûte du temps, laisse le fil ouvert, et repousse
## la tâche selon sa récurrence. Sauf une tâche d'imprévu : elle, elle se
## termine, et régler les dernières ferme le fil.
func faire_tache(tache_id: String) -> bool:
	var tache: Tache = taches.get(tache_id)
	if not tache_active(tache):
		return false
	if not depenser_temps(tache.cout_base):
		return false

	_resoudre(tache)
	taches_change.emit()
	_verifier_cloture(tache.fil_id)
	return true


## Ce qui arrive à une tâche une fois qu'elle n'est plus à faire — qu'on l'ait
## faite ou passée à quelqu'un. Le repas est cuit dans les deux cas, donc le
## lave-vaisselle est plein dans les deux cas : déléguer ne dispense pas de la
## suite, sinon ce serait un effacement et pas un transfert.
##
## **Tout tombe au même instant, y compris quand on délègue.** Une tentative de
## faire attendre les effets jusqu'à la relance a été essayée et retirée le
## 2026-09-17 : elle désynchronisait les deux moitiés d'une même tâche. Confier
## la cuisine débloquait « débarrasser la table » tout de suite, mais laissait
## l'assiette vide — le monde demandait de ranger un repas qui n'existait pas.
## Sam exécute sur-le-champ ; la relance sert au lendemain.
func _resoudre(tache: Tache) -> void:
	if tache.une_seule_fois():
		tache.terminee = true
	elif tache.def.prerequis != null:
		# Refermée, pas reprogrammée : elle attend que sa mère soit refaite.
		tache.bloquee = true
	else:
		tache.disponible_le = jour + tache.recurrence_jours

	# Faire une tâche en fait naître d'autres. C'est le travail qui appelle le
	# travail : cuisiner remplit le lave-vaisselle, la machine finit par
	# demander qu'on l'étende. Le délai décide si la suite tombe dans la foulée
	# ou seulement demain, donc si elle coûte un second déplacement.
	for suivante: Tache in taches.values():
		if suivante.def.prerequis == tache.def:
			suivante.bloquee = false
			suivante.disponible_le = jour + suivante.delai_prerequis

	_appliquer_effets(tache)


## Ce que la tâche change ailleurs que sur les fils : un repas apparaît sur la
## table, ou en disparaît. `Partie` ne sait pas ce que fait un effet, elle sait
## seulement qu'il faut l'appliquer — c'est ce qui permet d'en ajouter d'autres
## sans rouvrir ce fichier.
func _appliquer_effets(tache: Tache) -> void:
	if tache.def.effets.is_empty():
		return
	for effet: EffetTache in tache.def.effets:
		if effet != null:
			effet.appliquer()
	besoins_change.emit()


## Déléguer (§4) : l'exact contraire d'ancrer. Ancrer coûte très cher en temps
## et rend une case ; déléguer ne coûte presque pas de temps et en prend une.
##
## Il faut donc une case libre, comme pour ancrer et comme pour s'asseoir : on
## ne se décharge pas sur quelqu'un la tête déjà pleine. Déléguer est l'outil de
## celui qui manque de temps, pas de celui qui manque de place.
func peut_deleguer(tache: Tache) -> bool:
	if not tache_active(tache) or not tache.delegable:
		return false
	# Elle est déjà chez lui : redemander, c'est relancer, et ça se fait devant
	# lui. Sinon on paierait deux cases pour la même chose — et le bandeau
	# afficherait deux fois la même ligne, ce qui ne veut plus rien dire.
	if relance_de(tache.id) != null:
		return false
	if cases_libres() <= 0:
		return false
	return cout_reel(reglages.cout_delegation) <= temps_restant


func deleguer_tache(tache_id: String) -> bool:
	var tache: Tache = taches.get(tache_id)
	if not peut_deleguer(tache):
		return false
	if not depenser_temps(reglages.cout_delegation):
		return false

	_confier(tache)

	taches_change.emit()
	# Le fil ne change pas d'état, mais une case vient de se prendre dans la
	# tête : le travail est parti, la charge est restée. Ça doit se voir dans la
	# seconde, sinon déléguer a l'air gratuit.
	# Inutile de vérifier la clôture : la relance vient précisément de l'empêcher.
	fils_change.emit()
	return true


## Passer la tâche, et repartir avec la charge de vérifier. Le travail est fait,
## la place est prise : c'est très exactement le marché de la délégation.
func _confier(tache: Tache) -> void:
	_resoudre(tache)
	var relance := Relance.new()
	relance.tache = tache
	relance.due_le = jour + reglages.delai_relance
	relances.append(relance)


## Relancer : aller réclamer ce qu'on a délégué. On règle la plus vieille —
## c'est celle qui pourrit le plus longtemps un fil.
func peut_relancer() -> bool:
	return not relances_dues().is_empty() and cout_reel(reglages.cout_relance) <= temps_restant


func relancer() -> bool:
	if not peut_relancer():
		return false
	var relance := relances_dues()[0]
	if not depenser_temps(reglages.cout_relance):
		return false

	relances.erase(relance)
	# Relancer, ce n'est pas cocher « vérifié » : c'est lui redemander de le
	# faire. Si la tâche est revenue, il la refait, et il faudra revenir demain —
	# la délégation est un arrangement, pas un coup. Si elle n'est pas là
	# aujourd'hui, l'arrangement s'arrête et la case se libère : c'est le seul
	# moyen d'en sortir, venir un jour où il n'y a rien à refaire.
	var tache := relance.tache
	if tache_active(tache):
		_confier(tache)

	taches_change.emit()
	fils_change.emit()
	_verifier_cloture(tache.fil_id)
	return true


## Un fil temporaire dont plus rien n'attend est réglé : il rend ses cases
## et ne revient pas. L'imprévu se gère, il ne s'endure pas.
func _verifier_cloture(fil_id: String) -> void:
	var fil: Fil = fils.get(fil_id)
	if fil == null or not fil.temporaire or fil.etat != Fil.Etat.OUVERT:
		return
	for tache in taches_du_fil(fil_id):
		if not tache.terminee:
			return
	# Une relance en attente suffit à garder le fil ouvert : sans ça on solderait
	# un imprévu en déléguant tout, sans jamais vérifier que ça a été fait. Ce
	# n'est pas réglé tant qu'on n'a pas demandé si ça l'était.
	if relance_en_attente(fil_id):
		return
	fil.etat = Fil.Etat.FERME
	fil_ferme.emit(fil)
	fils_change.emit()


## Ancrer (§4) : ferme le fil et libère ses cases. Ses tâches continuent
## d'exister — le dispositif se souvient à ta place, il ne fait pas le boulot.
##
## Sauf les dispositifs qui, eux, le font vraiment. Un prélèvement automatique
## paie la facture ; à partir de là il n'y a plus de courrier à ouvrir ni de
## virement à faire, et le fil sort du jeu. Un tableau des menus, lui, ne
## cuisine pas : il rappelle, et il s'use si on ne le nourrit pas.
##
## Ce n'est pas le retour de l'allègement refusé au §4 : là on parlait de faire
## baisser le coût des tâches d'un fil ancré, ce qui brouillait Ancrer et
## Déléguer. Ici il n'y a plus de tâches du tout. C'est tout ou rien, et le
## joueur voit lequel des deux il achète avant de payer.
func peut_ancrer(fil_id: String, cout: float) -> bool:
	var fil: Fil = fils.get(fil_id)
	if fil == null or fil.etat != Fil.Etat.OUVERT or not fil.ancrable:
		return false
	# Exige une case libre : on ne s'ancre pas la tête pleine.
	if cases_occupees() >= slots:
		return false
	return cout_reel(cout) <= temps_restant


func ancrer_fil(fil_id: String, cout: float, definitif: bool = false) -> bool:
	if not peut_ancrer(fil_id, cout):
		return false

	var fil: Fil = fils[fil_id]
	if not depenser_temps(cout):
		return false

	fil.tension = 0
	if definitif:
		# Réglé, au même titre qu'un imprévu qu'on a fini de gérer : le fil rend
		# sa case, ses tâches quittent le monde, et il ne revient pas.
		fil.etat = Fil.Etat.FERME
		fil_ferme.emit(fil)
		taches_change.emit()
	else:
		fil.etat = Fil.Etat.ANCRE
	fils_change.emit()
	return true


## Lâcher un fil (§6). Il quitte le bandeau et n'existe plus que quelque part
## dans le logement — et pas forcément dans la pièce où vivent ses tâches.
## Le jeu ne dit jamais où : c'est tout l'intérêt.
func _lacher(fil: Fil) -> void:
	fil.etat = Fil.Etat.LACHE
	fil.jours_au_sol = 0
	fil.piece_id = Contenu.piece_au_hasard()
	fil_deborde.emit(fil)


## Renvoie false si la tête est pleine : le fil déborde au lieu de rentrer.
func ouvrir_fil(fil: Fil) -> bool:
	fils[fil.id] = fil
	if cases_occupees() + fil.taille() > slots:
		_lacher(fil)
		fils_change.emit()
		return false
	fil.etat = Fil.Etat.OUVERT
	fils_change.emit()
	return true


## S'asseoir (§11) : dépenser du temps à ne rien faire. Ça n'avance rien, ça ne
## ferme rien, et il faut une case vide dans la tête — pas juste du temps libre.
## C'est la seule chose que le jeu appelle une victoire.
func peut_sasseoir() -> bool:
	return cases_libres() > 0 and cout_reel(reglages.cout_assis) <= temps_restant


func sasseoir() -> bool:
	if not peut_sasseoir():
		return false
	if not depenser_temps(reglages.cout_assis):
		return false
	fois_assis += 1
	_assis_aujourdhui = true
	return true


## Appelé par le canapé chaque fois qu'il s'affiche disponible. Il n'existe que
## dans le salon : le voir vert veut donc dire quelque chose de précis — on
## était dans la pièce, la place était là, et on est reparti.
func signaler_canape_libre() -> void:
	_canape_vu_libre = true


## Changer de pièce (§9). Contrairement à toutes les autres dépenses, celle-ci
## ne se refuse pas : on ne peut pas empêcher quelqu'un de marcher. Le temps
## tombe simplement à zéro, et la journée est finie même si l'horloge tourne.
func changer_de_piece() -> void:
	if temps_restant <= 0.0:
		return
	var avant := temps_restant
	temps_restant = maxf(temps_restant - cout_reel(reglages.cout_piece), 0.0)
	temps_change.emit(temps_restant)
	# Marcher assèche comme le reste, et c'est tout l'intérêt : le prix de boire
	# est le détour, et le détour se paie deux fois — en temps, et en réserve.
	_consommer_corps(avant - temps_restant)


## Ramasser un fil tombé (§6). Gratuit en temps — le prix a déjà été payé, en
## cases et en oubli. Mais il faut de la place, et il revient avec sa tension :
## on ne récupère pas un fil au sol dans l'état où on l'a laissé tomber.
func peut_ramasser(fil_id: String) -> bool:
	var fil: Fil = fils.get(fil_id)
	if fil == null or fil.etat != Fil.Etat.LACHE:
		return false
	return cases_occupees() + fil.taille() <= slots


func ramasser_fil(fil_id: String) -> bool:
	if not peut_ramasser(fil_id):
		return false
	var fil: Fil = fils[fil_id]
	fil.etat = Fil.Etat.OUVERT
	fil.jours_au_sol = 0
	fils_change.emit()
	return true


## Vider sa tête (§5) : la soupape. Ancrer demande du temps *et* une case libre,
## donc les deux ressources manquent au même moment et le joueur en difficulté
## ne peut plus rien faire. Ceci lui rend une case tout de suite pour qu'il
## puisse ancrer — en creusant à côté.
##
## Gratuit en temps, et il faut que ça le reste : une soupape qui demande du
## temps est fermée exactement quand on en a besoin. Le prix est différé, et il
## est lourd (voir `coucher`).
##
## On n'écarte pas un fil ancré : il ne prend déjà aucune case, il n'y a rien à
## gagner. Et on n'écarte pas ce qu'on choisit — on écarte ce qui pèse le plus.
## C'est plus vrai, et ça évite un menu de sélection que le POC refuse (§13).
func fil_a_ecarter() -> Fil:
	var pire: Fil = null
	for fil in fils_ouverts():
		if pire == null or fil.tension > pire.tension:
			pire = fil
	return pire


func peut_vider_tete() -> bool:
	return fil_a_ecarter() != null


func vider_tete() -> bool:
	var fil := fil_a_ecarter()
	if fil == null:
		return false

	fil.etat = Fil.Etat.ECARTE
	fil.jour_retour = jour + reglages.delai_retour
	fil_ecarte.emit(fil)
	fils_change.emit()
	# Ses tâches quittent le monde avec lui : on ne peut pas travailler sur
	# quelque chose auquel on a décidé de ne plus penser.
	taches_change.emit()
	return true


# --- Fin de journée ----------------------------------------------------------

## La soirée (§7, étapes 1 à 4). Tout ce qui se règle sur la journée écoulée :
## ce qu'on laisse traîner enfle, puis les dispositifs usés lâchent, puis les
## échéances tombent sur ce qui reste à découvert, puis ce qui dort au sol
## pourrit. L'ordre compte, les effets se propagent.
##
## C'est l'état obtenu ici que le rêve va lire (§16). Ce découpage n'est donc
## pas une commodité : un prélèvement automatique qui vient de céder ne doit pas
## se présenter comme un mur dans le rêve de la nuit même.
func passer_la_soiree() -> void:
	if finie:
		return

	# 0. Le renoncement se compte. Avoir eu la place et ne pas l'avoir prise
	#    n'est pas la même journée que ne jamais avoir eu le choix.
	if _canape_vu_libre and not _assis_aujourdhui:
		jours_refuses += 1
	_canape_vu_libre = false
	_assis_aujourdhui = false

	# 1. Ce qu'on a laissé traîner enfle. Faire une tâche ne fait pas avancer :
	#    ça empêche juste son fil de grossir — ou son dispositif de lâcher.
	#
	#    Un fil écarté enfle aussi, et sans recours : ses tâches ne sont nulle
	#    part, donc rien ne peut le calmer. C'est ce qui empêche « vider sa
	#    tête » d'être un snooze — ne plus y penser ne le fait pas disparaître,
	#    ça le fait grossir.
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ECARTE:
			fil.tension = mini(fil.tension + fil.tension_par_nuit, Fil.TENSION_SEUIL)
			continue
		if not fil.actif():
			continue
		if fil_neglige(fil):
			fil.tension = mini(fil.tension + fil.tension_par_nuit, Fil.TENSION_SEUIL)
		else:
			fil.tension = maxi(fil.tension - 1, 0)

	# 2. Un dispositif qu'on ne nourrit pas décroche, et le fil remonte
	#    déjà gros. Ancrer supprime la charge, pas le travail.
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ANCRE and fil.tension >= Fil.TENSION_SEUIL:
			fil.etat = Fil.Etat.OUVERT
			fil_decroche.emit(fil)

	# 3. L'échéance ne se négocie pas. Pas fait à temps : c'est par terre.
	#    Un fil encore ancré y échappe — c'est à ça que sert un prélèvement
	#    automatique. Mais si son dispositif vient de lâcher (étape 2), on
	#    découvre le soir même que rien n'a été payé.
	#
	#    Un fil écarté ne s'y soustrait pas non plus, et surtout pas lui : ne
	#    pas y penser le jour où ça devait être fait, c'est exactement comme ça
	#    qu'on rate une échéance. Sinon la soupape deviendrait le moyen le moins
	#    cher de traverser une date butoir.
	for fil: Fil in fils.values():
		if fil.jour_echeance != jour:
			continue
		if fil.etat == Fil.Etat.ECARTE:
			_lacher(fil)
		elif fil.etat == Fil.Etat.OUVERT and fil_neglige(fil):
			_lacher(fil)

	# 4. Un fil oublié au sol ne s'améliore pas.
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.LACHE:
			fil.jours_au_sol += 1
			if fil.jours_au_sol >= 2:
				fil.tension = Fil.TENSION_SEUIL

	# 5. Le corps fait ses comptes (§18). C'est le coucher qui compte les jours,
	#    pas la réserve : être à sec une heure avant d'aller dormir coûte un cran
	#    d'humeur, pas une journée de sursis.
	#
	#    Le repas refroidit d'abord : ce qui était sur la table aujourd'hui y
	#    était pour aujourd'hui. Se coucher sans avoir mangé perd le repas, et
	#    c'est ce qui empêche « j'ai cuisiné lundi » de nourrir toute la semaine.
	var journee_propre := fils_au_sol().is_empty()
	for besoin: Besoin in besoins.values():
		besoin.vieillir()
		if besoin.a_sec():
			besoin.jours_a_sec += 1
			journee_propre = false

	# L'humeur remonte parce que la journée s'est bien passée, jamais parce
	# qu'on a acheté quelque chose. C'est ce qui l'empêche de devenir une jauge
	# à optimiser — et ce qui protège le canapé, qui ne doit rien rapporter.
	if journee_propre and humeur < reglages.humeur_max:
		humeur = minf(humeur + reglages.humeur_remontee_par_jour, reglages.humeur_max)
		humeur_change.emit(humeur)
	besoins_change.emit()


## Ce que la nuit rend quand on ne l'a pas jouée. C'était la règle du §7 ; le
## §16 l'a dégradée au rang de *résumé d'une nuit qu'on n'a pas vue*. Elle sert
## encore, et il faut qu'elle serve : un rêve interrompu, sauté, ou une journée
## qu'on teste sans passer par le lit doivent quand même rendre un nombre de
## cases défendable.
func delta_de_nuit_calculee() -> int:
	var portees := cases_occupees()
	if portees <= reglages.seuil_nuit_calme:
		return 1
	if portees >= reglages.seuil_nuit_charge:
		return -1
	return 0


## Le lendemain (§7, étapes 5 à 8). `delta` est le nombre de cases que la nuit a
## rendu : du rêve s'il a été joué, du barème sinon.
##
## `paisible` dit qu'il n'y avait rien du tout cette nuit-là — ni monstre à
## affronter, ni case occupée. C'est le seul cas qui donne droit au plafond haut,
## et c'est la moitié montante de la spirale : la journée parfaite est la seule
## chose au monde qui agrandit la tête.
##
## Elle ne l'agrandit pas d'un cran, elle la remet à neuf : une nuit vide rend 7
## qu'on soit parti de 6 ou du plancher. Sinon la sortie du bas serait fermée —
## à 4 cases, se coucher la tête vide demande une journée que 4 cases ne
## permettent plus de faire, et il faudrait trois nuits parfaites d'affilée pour
## remonter. La nuit vide *est* la remontée, pas son premier échelon.
##
## La septième case ne vaut que pour la journée qui suit cette nuit-là. Elle
## n'est pas acquise : dès qu'il y a eu quelqu'un à affronter, le plafond
## redevient 6 et la case s'en va, quel qu'ait été le résultat du combat. C'est
## un prêt sur une nuit vide, pas un palier gagné.
##
## Le clamp est ici et nulle part ailleurs. Le rêve propose un nombre, il ne
## décide jamais des bornes — c'est ce qui garantit qu'aucune nuit, si héroïque
## soit-elle, ne peut sortir du monde par le haut.
func se_lever(delta: int, paisible: bool = false) -> void:
	if finie:
		return

	# 5. La nuit se règle sur ce qu'on a emporté au lit — avant que demain
	#    n'apporte ses propres fils.
	# Le plafond du jour, pas celui d'hier : une nuit ordinaire rabote la
	# septième case même si elle s'est bien passée. Il faut une nouvelle nuit
	# vide pour la ravoir. Et la nuit vide ne compte pas ses cases : elle pose
	# le chiffre, `delta` n'a plus rien à dire.
	if paisible:
		slots = reglages.slots_nuit_paisible
	else:
		slots = clampi(slots + delta, reglages.slots_plancher, reglages.slots_plafond)

	jour += 1

	# 6. On peut perdre au réveil : se lever avec une tête plus petite que ce
	#    qu'on porte en fait tomber un. Les fils partent en premier — ce sont eux
	#    qu'on remarque. S'il ne reste que des choses à redemander, on en oublie
	#    une, et personne ne le dit : c'est très exactement comme ça que ça se
	#    passe.
	while cases_occupees() > slots:
		var ouverts := fils_ouverts()
		if not ouverts.is_empty():
			_lacher(ouverts.back())
			continue
		var attentes := relances_en_tete()
		if attentes.is_empty():
			break
		relances.erase(attentes[0])

	# 7. Ce que la journée apporte. Un fil peut déborder dès son arrivée.
	#
	#    Ce qu'on a écarté revient par la même porte, et c'est voulu : ça se
	#    réinsère de force, avant les nouveaux fils, sans demander s'il y a de la
	#    place. S'il n'y en a pas, ça tombe. Le joueur qui a vidé sa tête pour
	#    repousser au lieu d'ancrer perd le fil pour de bon.
	var arrivants: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ECARTE and fil.jour_retour <= jour:
			arrivants.append(fil)
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ENATTENTE and fil.jour_arrivee <= jour:
			arrivants.append(fil)
	for fil in arrivants:
		var revient := fil.etat == Fil.Etat.ECARTE
		# S'il déborde à l'arrivée, `ouvrir_fil` l'a déjà annoncé comme tombé.
		# L'annoncer aussi comme arrivé donnerait à lire deux événements.
		if ouvrir_fil(fil):
			# Un retour se dit autrement qu'une arrivée : le joueur doit
			# reconnaître ce qu'il a mis de côté, sinon il croit à un fil neuf
			# et n'apprend jamais ce que la soupape lui a coûté.
			if revient:
				fil_revient.emit(fil)
			else:
				fil_arrive.emit(fil)

	temps_restant = temps_du_jour(jour)
	jour_change.emit(jour)
	temps_change.emit(temps_restant)
	fils_change.emit()
	taches_change.emit()

	# 8. Les façons dont ça s'arrête, dans l'ordre de ce qui prime. Le corps
	#    passe devant tout : on ne finit pas sa semaine quand on ne se relève
	#    pas, et la tête n'a plus d'importance à ce stade.
	var mortel := besoin_fatal()
	if mortel != null:
		finie = true
		partie_finie.emit(mortel.id)
	elif fils_au_sol().size() >= reglages.fils_au_sol_fatal:
		finie = true
		partie_finie.emit("effondrement")
	elif jour > reglages.jours_semaine:
		finie = true
		partie_finie.emit("semaine")


## Une journée entière sans rêve : la soirée, le barème, le lendemain. C'est le
## §7 tel qu'il était avant que la nuit devienne jouable, et c'est ce qui permet
## de continuer à playtester le jour seul pendant que le rêve se règle.
func coucher() -> void:
	passer_la_soiree()
	se_lever(delta_de_nuit_calculee())
