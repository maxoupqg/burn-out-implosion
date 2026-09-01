class_name Reglages
extends Resource

## Tous les chiffres de l'équilibrage, dans un fichier qu'on ouvre dans
## l'inspecteur.
##
## `partie.gd` dit comment le jeu marche ; ce fichier dit à quel prix. La
## séparation est la même qu'entre `contenu.gd` et les `.tres` de `donnees/` :
## régler une semaine ne doit pas demander d'ouvrir un script. Chaque valeur a
## produit un ressenti précis en playtest — les commentaires disent lequel,
## pour qu'on sache ce qu'on casse en y touchant.
##
## Un seul exemplaire, `res://donnees/reglages.tres`, chargé au démarrage.

@export_group("Temps")
## Budget d'une journée ordinaire.
@export var temps_jour: float = 10.0
## Le dimanche a un budget plus large : c'est la fenêtre d'ancrage, et on y
## arrive cramé (§11).
@export var temps_dimanche: float = 14.0
## Longueur de la run. Au-delà, la semaine est tenue.
@export var jours_semaine: int = 7

@export_group("Cases")
## Taille de la tête au départ, et plafond : une bonne nuit ne rend jamais plus
## de place qu'on n'en avait au premier jour.
@export var slots_base: int = 6
## Et le plancher : même la pire semaine laisse de quoi porter quelque chose.
@export var slots_plancher: int = 4
## Au coucher, porter ce nombre de cases ou moins rend une case le lendemain.
@export var seuil_nuit_calme: int = 2
## En porter autant ou plus en coûte une.
@export var seuil_nuit_charge: int = 5
## Multiplicateur de charge (§2), indexé par le nombre de cases occupées. Au
## delà de la dernière valeur, c'est la dernière qui s'applique.
##
## Le couplage à sens unique du jeu tient entièrement dans ce tableau : les
## cases pourrissent le temps, le temps n'achète jamais de cases. Le rendre
## plat rendrait la surcharge indolore et le POC sans objet.
@export var paliers_multiplicateur: PackedFloat32Array = PackedFloat32Array(
	[1.0, 1.0, 1.2, 1.2, 1.4, 1.6, 1.8]
)

@export_group("Coûts")
## S'asseoir coûte du temps et ne produit rien. C'est là tout l'intérêt (§11).
## Le chiffre qui a produit l'hésitation devant le canapé : ne pas y toucher
## sans nouveau playtest.
@export var cout_assis: float = 3.0
## Changer de pièce (§9). Petit, mais payé au tarif du jour : c'est ce qui rend
## la dispersion chère sans jamais l'interdire.
@export var cout_piece: float = 0.5
## Déléguer ne coûte quasiment rien en temps (§4) : le prix est ailleurs, dans
## la relance qu'il faudra aller faire et dans la case qu'elle gèle.
@export var cout_delegation: float = 0.5
## Relancer coûte moins que déléguer, et il faut que ça reste vrai : la somme
## des deux est le seuil au-dessus duquel une tâche vaut la peine d'être passée
## à quelqu'un. À 0,75, on délègue ce qui coûte cher et on fait soi-même le
## reste. Pas zéro : sinon on finirait la journée à court de temps en ramassant
## quand même toutes ses relances gratuitement.
@export var cout_relance: float = 0.25

@export_group("Délais")
## On ne court pas derrière quelqu'un dans l'heure. La relance tombe le
## lendemain — c'est ce décalage qui fait de la délégation un emprunt.
@export var delai_relance: int = 1
## Vider sa tête (§5) : la soupape. Deux nuits de répit, pas une de plus — assez
## pour dégager la place et ancrer autre chose, trop peu pour en faire une
## habitude. Le fil revient à cette date qu'on ait fait de la place ou non.
@export var delai_retour: int = 2

@export_group("Fin de partie")
## Autant de fils au sol en même temps : on ne sait même plus ce qu'on a lâché.
@export var fils_au_sol_fatal: int = 3

@export_group("Monde")
## Il n'y a qu'une autre personne dans le POC. Son nom est ici et pas sur la
## scène : le bandeau doit pouvoir le dire sans que le salon soit chargé.
@export var nom_delegataire: String = "Sam"


## Ce que coûte réellement une action, au tarif du jour.
func multiplicateur(cases_occupees: int) -> float:
	if paliers_multiplicateur.is_empty():
		return 1.0
	var i := clampi(cases_occupees, 0, paliers_multiplicateur.size() - 1)
	return paliers_multiplicateur[i]
