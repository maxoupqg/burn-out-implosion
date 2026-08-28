extends Node

## État global de la run. Autoload : accessible partout via `Partie`.
##
## Porte les deux ressources (§2), le calendrier de la semaine (§11) et le
## calcul de nuit (§7). Le contenu, lui, vit dans `contenu.gd`.

const SLOTS_BASE := 6
const SLOTS_PLANCHER := 4
const TEMPS_JOUR := 10.0
## Le dimanche a un budget plus large : c'est la fenêtre d'ancrage, et on y
## arrive cramé (§11).
const TEMPS_DIMANCHE := 14.0
const JOURS_SEMAINE := 7
## Ancrer coûte cher, et il faut une case libre : les deux ressources
## s'effondrent au même moment (§5). On s'en sort quand ça va encore bien.
const COUT_ANCRAGE := 4.0
## S'asseoir coûte du temps et ne produit rien. C'est là tout l'intérêt (§11).
const COUT_ASSIS := 3.0
## Changer de pièce (§9). Petit, mais payé au tarif du jour : c'est ce qui rend
## la dispersion chère sans jamais l'interdire.
const COUT_PIECE := 0.5
## Trois fils au sol en même temps : on ne sait même plus ce qu'on a lâché.
const FILS_AU_SOL_FATAL := 3

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
## La run est terminée. `raison` vaut "effondrement" ou "semaine".
signal partie_finie(raison: String)

var jour: int = 1
var temps_restant: float = TEMPS_JOUR
var slots: int = SLOTS_BASE
## Nombre de fois où l'on a réussi à ne rien faire. C'est le score.
var fois_assis: int = 0
var finie: bool = false

## id -> Fil
var fils: Dictionary = {}
## id -> Tache
var taches: Dictionary = {}


func _ready() -> void:
	reinitialiser()


## Reconstruit une semaine neuve. Indispensable au redémarrage : recharger la
## scène ne touche pas à un autoload, et les anciens Fil traînent leur tension.
func reinitialiser() -> void:
	jour = 1
	temps_restant = temps_du_jour(jour)
	slots = SLOTS_BASE
	fois_assis = 0
	finie = false

	fils.clear()
	taches.clear()
	for fil in Contenu.fils():
		fils[fil.id] = fil
	for tache in Contenu.taches():
		taches[tache.id] = tache


# --- Lecture -----------------------------------------------------------------

func temps_du_jour(j: int) -> float:
	return TEMPS_DIMANCHE if j >= JOURS_SEMAINE else TEMPS_JOUR


func fils_ouverts() -> Array[Fil]:
	var ouverts: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.OUVERT:
			ouverts.append(fil)
	return ouverts


func fils_au_sol() -> Array[Fil]:
	var tombes: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.LACHE:
			tombes.append(fil)
	return tombes


## Cases réellement occupées dans la tête : un fil négligé en prend deux.
func cases_occupees() -> int:
	var total := 0
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


## Une tâche n'existe dans le monde que si son fil est là. Tant que « Les
## courses » n'est pas arrivé, sa liste n'est pas à faire.
func tache_active(tache: Tache) -> bool:
	if tache == null or not tache.est_disponible(jour):
		return false
	var fil: Fil = fils.get(tache.fil_id)
	return fil != null and fil.actif()


## Un fil est négligé tant qu'une de ses tâches attend encore aujourd'hui.
## Se coucher là-dessus fera monter sa tension.
func fil_neglige(fil: Fil) -> bool:
	for tache in taches_du_fil(fil.id):
		if tache.est_disponible(jour):
			return true
	return false


## Multiplicateur de charge (§2). Le couplage à sens unique : les cases
## pourrissent le temps, le temps n'achète jamais de cases.
func multiplicateur() -> float:
	var n := cases_occupees()
	if n <= 1:
		return 1.0
	if n <= 3:
		return 1.2
	if n == 4:
		return 1.4
	if n == 5:
		return 1.6
	return 1.8


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

	if tache.une_seule_fois():
		tache.terminee = true
	else:
		tache.disponible_le = jour + tache.recurrence_jours

	taches_change.emit()
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
	fil.etat = Fil.Etat.FERME
	fil_ferme.emit(fil)
	fils_change.emit()


## Ancrer (§4) : ferme le fil et libère ses cases. Ses tâches continuent
## d'exister — le dispositif se souvient à ta place, il ne fait pas le boulot.
func peut_ancrer(fil_id: String) -> bool:
	var fil: Fil = fils.get(fil_id)
	if fil == null or fil.etat != Fil.Etat.OUVERT or not fil.ancrable:
		return false
	# Exige une case libre : on ne s'ancre pas la tête pleine.
	if cases_occupees() >= slots:
		return false
	return cout_reel(COUT_ANCRAGE) <= temps_restant


func ancrer_fil(fil_id: String) -> bool:
	if not peut_ancrer(fil_id):
		return false

	var fil: Fil = fils[fil_id]
	if not depenser_temps(COUT_ANCRAGE):
		return false

	fil.etat = Fil.Etat.ANCRE
	fil.tension = 0
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
	return cases_libres() > 0 and cout_reel(COUT_ASSIS) <= temps_restant


func sasseoir() -> bool:
	if not peut_sasseoir():
		return false
	if not depenser_temps(COUT_ASSIS):
		return false
	fois_assis += 1
	return true


## Changer de pièce (§9). Contrairement à toutes les autres dépenses, celle-ci
## ne se refuse pas : on ne peut pas empêcher quelqu'un de marcher. Le temps
## tombe simplement à zéro, et la journée est finie même si l'horloge tourne.
func changer_de_piece() -> void:
	if temps_restant <= 0.0:
		return
	temps_restant = maxf(temps_restant - cout_reel(COUT_PIECE), 0.0)
	temps_change.emit(temps_restant)


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


# --- Fin de journée ----------------------------------------------------------

## Fin de journée (§7). La nuit n'est pas une scène, c'est ce calcul :
## le nombre de fils portés au coucher fixe la taille de la tête du lendemain.
##
## L'ordre compte, les effets se propagent : ce qu'on laisse traîner enfle,
## puis les dispositifs usés lâchent, puis les échéances tombent sur ce qui
## reste à découvert, puis la nuit se règle sur ce qu'on emporte au lit — et
## seulement après, demain arrive.
func coucher() -> void:
	if finie:
		return

	# 1. Ce qu'on a laissé traîner enfle. Faire une tâche ne fait pas avancer :
	#    ça empêche juste son fil de grossir — ou son dispositif de lâcher.
	for fil: Fil in fils.values():
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
	for fil: Fil in fils.values():
		if fil.jour_echeance != jour or fil.etat != Fil.Etat.OUVERT:
			continue
		if fil_neglige(fil):
			_lacher(fil)

	# 4. Un fil oublié au sol ne s'améliore pas.
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.LACHE:
			fil.jours_au_sol += 1
			if fil.jours_au_sol >= 2:
				fil.tension = Fil.TENSION_SEUIL

	# 5. La nuit se règle sur ce qu'on emporte au lit — avant que demain
	#    n'apporte ses propres fils.
	var portees := cases_occupees()
	var delta := 0
	if portees <= 2:
		delta = 1
	elif portees >= 5:
		delta = -1
	slots = clampi(slots + delta, SLOTS_PLANCHER, SLOTS_BASE)

	jour += 1

	# 6. On peut perdre au réveil : se lever avec une tête plus petite que ce
	#    qu'on porte en fait tomber un.
	while cases_occupees() > slots:
		_lacher(fils_ouverts().back())

	# 7. Ce que la journée apporte. Un fil peut déborder dès son arrivée.
	var arrivants: Array[Fil] = []
	for fil: Fil in fils.values():
		if fil.etat == Fil.Etat.ENATTENTE and fil.jour_arrivee <= jour:
			arrivants.append(fil)
	for fil in arrivants:
		# S'il déborde à l'arrivée, `ouvrir_fil` l'a déjà annoncé comme tombé.
		# L'annoncer aussi comme arrivé donnerait à lire deux événements.
		if ouvrir_fil(fil):
			fil_arrive.emit(fil)

	temps_restant = temps_du_jour(jour)
	jour_change.emit(jour)
	temps_change.emit(temps_restant)
	fils_change.emit()
	taches_change.emit()

	# 8. Les deux façons dont ça s'arrête. L'effondrement passe devant : si on
	#    s'écroule le dimanche soir, on s'est quand même écroulé.
	if fils_au_sol().size() >= FILS_AU_SOL_FATAL:
		finie = true
		partie_finie.emit("effondrement")
	elif jour > JOURS_SEMAINE:
		finie = true
		partie_finie.emit("semaine")
