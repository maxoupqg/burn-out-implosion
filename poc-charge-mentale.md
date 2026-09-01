# Jeu de charge mentale — doc de POC

Vue de dessus, temps réel doux, ton humoristique et satirique.
Ce document couvre **uniquement le socle** : la vie quotidienne. Travail, sommeil jouable et structure roguelite sont des surcouches, listées en fin de doc.

---

## 1. Ce que le POC doit prouver

Une seule chose :

> Le joueur ressent que **porter** une tâche coûte plus cher que **la faire**.

S'il finit une semaine en disant « j'ai rien foutu et je suis crevé », c'est validé.
S'il joue ça comme un gestionnaire de to-do efficace, c'est raté et il faut revoir les coûts.

**Hors scope du POC :** phase travail, méta-progression entre runs, conjoint avec personnalité, événements aléatoires.

---

## 2. Les deux ressources

| | Quoi | Se dépense | Se régénère |
|---|---|---|---|
| **Temps** | Le compteur de la journée | À chaque action et à chaque déplacement | À chaque nouvelle journée, valeur fixe |
| **Slots** | Les cases de la tête | Occupés en permanence par les fils ouverts | Uniquement en fermant un fil |

Valeurs de départ à tester : **6 slots**, journée = **~10 unités de temps**.

Overcooked ne met la pression que sur le temps. Ici le joueur peut avoir tout son temps disponible et être incapable de réfléchir.

### Le couplage — règle centrale

Les deux ressources ne se compensent pas, mais elles ne sont pas indépendantes. Le couplage est **à sens unique** :

> **Les slots pourrissent le temps. Le temps n'achète jamais de slots.**

Chaque tâche coûte son temps de base **× un multiplicateur de charge**, fonction du nombre de **cases occupées** — pas du nombre de fils, puisqu'un fil négligé en occupe deux (§3).

| Cases occupées | Multiplicateur |
|---|---|
| 0 – 1 | × 1.0 |
| 2 – 3 | × 1.2 |
| 4 | × 1.4 |
| 5 | × 1.6 |
| 6 | × 1.8 |

Formule de travail : `mult = 1.0 + 0.15 × cases_occupées` (à tuner par paliers).

C'est le moteur du burn-out : plus tu portes, moins tu abats, donc plus tu portes. La spirale est mathématique, pas seulement thématique.

Le multiplicateur doit être **affiché en permanence** et changer visiblement quand un fil s'ouvre ou se ferme.

---

## 3. Les trois objets

### Fil
Une préoccupation ouverte. **Occupe un slot tant qu'il est ouvert.**
Un fil n'est pas une tâche : c'est un domaine qui *génère* des tâches.
Exemples : les repas, le linge, la rentrée, la santé du gosse.

Trois états :

- **Ouvert** — dans la tête, occupe un slot, compte dans le multiplicateur. Ses tâches demandent une décision (quand, qui, comment).
- **Ancré** — dans le monde, occupe zéro slot. Ses tâches apparaissent à heure et lieu fixes, sans décision.
- **Lâché** — tombé par terre (voir §6). Occupe zéro slot mais n'est plus dans la tête du joueur non plus.

Un fil ancré **reste visible à l'écran**, accroché à son dispositif dans la pièce. C'est ce qui permet de le renvoyer dans la tête plus tard.

### La tension — pourquoi on fait les tâches

Sans cette règle, le jeu se gagne en ne faisant rien : faire une tâche ne ferme aucun fil, donc ne sert à rien.

Chaque fil ouvert porte une **tension**, un simple compteur :

- Au coucher, si une de ses tâches est restée disponible dans la journée → **tension +1**.
- Si toutes ses tâches étaient à jour → **tension −1**.
- À **tension 2**, le fil **occupe deux cases** au lieu d'une.

Un fil qui enfle fait monter le multiplicateur, et peut faire déborder la tête — donc faire tomber *un autre* fil, qu'on oubliera (§6). Négliger un domaine en fait perdre un autre.

> **On ne fait pas les tâches pour avancer. On les fait pour empêcher que ça empire.**

C'est le sujet du jeu : courir pour rester sur place.

**Un fil ancré accumule de la tension lui aussi.** Elle ne le fait pas enfler — il n'occupe plus de case — elle **use son dispositif**. À tension 2, le dispositif décroche : le fil remonte dans la tête, et il remonte déjà gros (deux cases).

> **Ancrer ne supprime pas le travail. Ça supprime la charge.**

Le dispositif se souvient à ta place, il ne cuisine pas. Le temps reste dû, seule la case est rendue — c'est la seule conversion que le jeu autorise entre les deux ressources, et elle ne va que dans ce sens.

La récompense positive d'un ancrage n'a pas besoin d'être écrite : la tête étant plus légère, le multiplicateur baisse, donc *toutes* les tâches coûtent moins cher — y compris celles du fil qu'on vient d'ancrer.

**Écarté :** faire s'empiler plusieurs exemplaires d'une tâche non faite. Ça ne fait que reporter un coût en temps, donc ça rend le rattrapage possible — or le propos, c'est qu'on ne rattrape pas.

### Tâche
L'unité concrète, exécutable dans une pièce. Coûte du temps.
Chaque tâche a une **récurrence** (tous les jours, 2 jours, semaine…) : la faire ne ferme pas son fil, elle repousse juste sa prochaine apparition.

### Dispositif
L'objet posé dans une pièce qui porte un fil ancré.
Tableau blanc, calendrier mural, panier d'entrée, pilulier, commande récurrente.
Visible, physique, cassable.

---

## 4. Les actions

| Action | Effet sur la tâche | Effet sur le fil | Coût |
|---|---|---|---|
| **Faire** | Résolue, revient selon sa récurrence | Reste ouvert | Temps × multiplicateur |
| **Déléguer** | Résolue | Reste ouvert **et génère une tâche « relancer »** | Quasi zéro temps |
| **Ancrer** | Les tâches continuent d'exister | **Se ferme** — libère le slot | Beaucoup de temps + **exige un slot libre** |
| **Vider sa tête** | Aucun | Sort de la tête, revient **de force** sous 2 jours | Temps minime |
| **S'asseoir** | Aucun | Aucun | Temps + **exige un slot vide** |
| *Ne rien faire* | Reste en attente | Reste ouvert, **sa tension monte** | Gratuit en temps, ruineux en cases |

**Point de vigilance :** déléguer doit coûter **en slots, pas en temps**. Si le joueur peut déléguer sans conséquence mentale, tout le propos du jeu tombe. La tâche « relancer » est non délégable et revient tant qu'elle n'est pas faite.

**Déléguer et Ancrer sont exactement opposés sur les deux axes**, et ça doit le rester :

| | Agit sur | Coût en temps | Coût en cases |
|---|---|---|---|
| **Déléguer** | une *instance* de tâche | quasi zéro | cher — génère « relancer » |
| **Ancrer** | le *fil* entier | très cher | **rend** une case |

Déléguer achète du temps avec de la charge ; ancrer achète de la charge avec du temps. Le joueur choisit laquelle de ses deux ressources il saigne.

**Refusé — l'ancrage ne doit pas alléger le travail.** Ni remise de temps sur les tâches du fil ancré, ni récurrence allongée. Deux raisons : ça contredit la seule phrase que le jeu affirme (*« Ancrer ne supprime pas le travail, ça supprime la charge »*), et ça fait empiéter Ancrer sur la niche de Déléguer — qui deviendrait alors une version pauvre et temporaire du même effet, donc morte.

La récompense de l'ancrage existe déjà et elle est globale : une case rendue en permanence, donc un multiplicateur plus bas, donc **toutes** les actions du jeu raccourcies, y compris les tâches du fil ancré. On a acheté un actif ; les tâches qui restent sont son entretien. Si l'ancrage ne se *sent* pas assez, c'est un problème de retour sensoriel (§10), pas de mécanique.

### La relance vit sur quelqu'un

Décidé à l'implémentation. La relance **ne s'affiche pas sur le meuble** : elle s'affiche sur la personne à qui on a délégué, et cette personne est quelque part dans le logement. Le trajet fait partie du prix — c'est ce qui empêche déléguer d'être un bouton.

**Une relance en attente occupe une case dans la tête.** C'est tout le coût du verbe, et il est exactement là où le tableau ci-dessus le promettait. *« Il faut que je pense à lui redemander »* n'est pas du travail restant : c'est une place prise. Elle s'affiche dans le bandeau, à côté des fils, avec le nom de ce qu'on a délégué.

Conséquences directes :

1. **Déléguer exige une case libre**, comme ancrer et comme s'asseoir. Déléguer est l'outil de celui qui manque de *temps*, jamais de celui qui manque de *place*. On ne se décharge pas sur quelqu'un la tête déjà pleine.
2. **La relance tombe le lendemain**, pas le jour même. Sans ce décalage, on annule sa délégation dans la foulée et le verbe ne coûte plus rien. La case, elle, est prise tout de suite.
3. **Un fil temporaire ne se clôt pas tant qu'une relance traîne.** Sinon on solde un imprévu en le passant à quelqu'un sans jamais savoir si ça a été fait.

> **Refusé — la relance ne doit pas faire monter la tension du fil.** Essayé, et faux. La tension dit *« le travail n'a pas été fait »* ; or une tâche déléguée a été faite. En la comptant comme un manquement, on faisait décrocher les dispositifs des fils qu'on venait d'ancrer : le joueur qui déléguait, ancrait *et* relançait consciencieusement perdait quand même son fil, sans lever disponible. Punir le jeu correct est la pire faute possible. Le prix de la délégation est en cases, et nulle part ailleurs.

Les relances d'un fil tombé par terre dorment jusqu'à ce qu'on le ramasse : le jeu ne dit jamais ce qu'on a lâché (§6), et ce n'est pas à l'autre de nous le rappeler. Et si l'on se réveille avec une tête trop petite alors qu'on ne portait plus que des relances, on en oublie une sans que rien ne le signale — c'est très exactement comme ça que ça se passe.

### Relancer, c'est redemander — pas cocher

Corrigé au playtest, et c'est le joueur qui a raison. Version initiale : relancer soldait la relance, la case se libérait, et si la tâche revenait le lendemain il fallait la refaire ou la redéléguer. Autrement dit relancer voulait dire *« vérifié, il l'a fait »* — une écriture comptable, pas une action.

Mais on ne va pas voir quelqu'un pour vérifier ce qu'il a déjà fait. **On y va pour qu'il le refasse.** Donc relancer re-délègue : la tâche repart chez lui, et la relance retombe le lendemain. La délégation cesse d'être un coup ponctuel et devient un **arrangement durable** — ce qui rend enfin littéralement vraie la phrase du tableau : *déléguer achète du temps avec de la charge*. On paie 0,25 par jour, indéfiniment, et une case reste gelée tant que ça dure.

**La sortie est unique et elle se mérite : venir le voir un jour où il n'y a rien à refaire.** Si la tâche n'est pas disponible au moment de la relance, l'arrangement s'arrête et la case se libère.

Pour une tâche à récurrence longue, ça arrive tout seul un jour creux. Pour une tâche quotidienne, il n'y a qu'un moyen : **la faire soi-même une fois, puis aller le lui dire.** On paie le plein tarif de la tâche pour récupérer sa case. C'est exactement le bon geste — reprendre la charge coûte plus cher que de l'avoir gardée, et c'est pour ça qu'on ne la reprend pas. Ça évite aussi qu'une tâche d'imprévu déléguée garde son fil ouvert pour toujours via une relance qui se renouvelle toute seule.

**Ne pas relancer est le pire coup du jeu, et le meuble doit le dire.** Une relance ignorée ne pourrit pas et ne s'efface pas : la case reste gelée indéfiniment — même si on ancre le fil — pendant que la tâche revient sur son meuble plein tarif, comme si de rien n'était. On paie donc les deux. C'est juste, mais c'était un piège muet : rien à l'écran ne reliait la case du bandeau et la tâche de la pièce. Le meuble affiche maintenant `déjà chez Sam — va le relancer`, et déléguer une seconde fois une tâche déjà partie est refusé — redemander, c'est relancer, et ça se fait devant lui.

**À surveiller au playtest :** relancer coûte 0,25 *par jour désormais*, plus la case gelée, plus le trajet. Pour « faire à manger » (2,0/jour) l'arrangement est très rentable — c'est voulu, mais si déléguer les repas devient la réponse évidente à toute la partie, c'est le prix quotidien qu'il faut monter, pas le prix d'entrée.

**La somme des deux coûts est un seuil, et le meuble doit l'afficher en entier.** Déléguer 0,5 puis relancer 0,25 fait 0,75 : en dessous, déléguer est une perte sèche. Vider le lave-vaisselle coûte 1,0 — le déléguer ne fait gagner qu'un quart d'unité *par jour*, et coûte en plus une case gelée et un trajet quotidien. C'est la bonne réponse : *on délègue ce qui coûte cher et ce qui revient souvent, on fait soi-même le petit*. Mais le joueur doit pouvoir faire ce calcul **avant**, pas le découvrir le lendemain. D'où l'étiquette : `F  déléguer   0,6 puis 0,3/jour`.

Relancer n'est pas gratuit en temps, et ne doit pas le devenir : sinon on termine ses journées à zéro et on ramasse quand même toutes ses relances en se promenant.

Chiffres de départ, **non validés** : déléguer 0,5 ; relancer 0,25 ; délai 1 jour. Le temps ne fait presque rien ici ; ce qui se règle, c'est le nombre de cases qu'on accepte de geler.

**À trancher :**
- Une relance par tâche déléguée, ou une seule qui solde tout un fil ? Aujourd'hui : une par tâche, et le PNJ les sert une par une.
- Le PNJ est au salon, la pièce centrale. Le trajet est donc court depuis partout. Si déléguer se révèle trop confortable, c'est le premier levier à bouger — avant de toucher aux coûts.

### S'asseoir

C'est la condition de victoire, rendue jouable. Le joueur doit **décider** de se reposer et le payer en temps. Ça ne produit rien, ça ne débloque rien.
Si la victoire était automatique en fin de journée, le joueur gagnerait par accident sans comprendre pourquoi.

---

## 5. Le frein à l'ancrage

Ancrer demande **du temps et un slot libre** — les deux ressources s'effondrent au même moment.

Conséquence recherchée : le joueur en difficulté ne *peut pas* s'en sortir. On s'en sort en ancrant quand ça va encore bien.

Deux soupapes empêchent le softlock :

1. **Fils à échéance** — certains fils se ferment tout seuls à date (la rentrée, les impôts). Ils ouvrent des fenêtres que le bon joueur apprend à guetter.
2. **Vider sa tête** — libère une case maintenant contre un retour du fil sous deux jours. Permet de se dégager la place pour ancrer, en creusant à côté.

**Vider sa tête n'est pas un snooze.** Au retour, le fil se réinsère de force : s'il n'y a pas de place, il tombe (§6). Le joueur qui s'en sert pour repousser au lieu d'ancrer perd le fil pour de bon.

---

## 6. Le débordement et l'oubli

Il n'y a **jamais** de file d'attente de fils. La tête est pleine ou elle ne l'est pas.

Quand un fil doit s'ouvrir alors qu'il n'y a plus de slot libre, il ne rentre pas : **il tombe**.

Un fil lâché :

- **disparaît du HUD-tête.** Le joueur ne l'a plus en mémoire — au sens propre, il n'est plus affiché nulle part.
- **existe encore physiquement**, posé au sol dans **une pièce tirée au hasard** — pas forcément celle où vivent ses tâches. La charge mentale ne range pas ce qu'elle laisse tomber. On ne le retrouve qu'en repassant devant, et une seule pièce est visible à la fois (§9) : c'est ce qui rend l'oubli réel plutôt que décoratif.
- **reste au même endroit** d'une visite à l'autre. Revenir le chercher ne voudrait rien dire si le tas se déplaçait.
- **escalade** au bout de 2 jours au sol : le linge pas fait devient « plus rien de propre », qui est un fil **non ancrable** (§7).

C'est le cœur de la sensation d'oubli : la charge mentale ne prévient pas qu'elle a lâché quelque chose. Elle le lâche, point. Et c'est ce qui donne sa vraie raison d'être au déplacement — on marche pour retrouver ce qu'on a oublié.

Ramasser un fil lâché est gratuit en temps mais **exige un slot libre**.

**Effondrement : 3 fils lâchés simultanément au sol.**

---

## 7. La nuit

Pas de phase de sommeil jouable dans le POC. La nuit est un **calcul**, pas une scène.

Le nombre de **cases occupées au moment du coucher** détermine la taille de la tête du lendemain :

| Cases occupées au coucher | Nuit | Effet |
|---|---|---|
| 0 – 2 | calme | **+1 slot** demain (jusqu'au max) |
| 3 – 4 | correcte | inchangé |
| 5 et + | agitée | **−1 slot** demain |

**Plancher à 4 slots, plafond au max de base (6).**
Le plancher évite la falaise : c'est un élastique qui tire fort, pas une mort programmée.

Deux effets recherchés :

- **L'heure du coucher devient une décision.** Ma dernière unité de temps : une tâche de plus, ou fermer un fil pour dormir correctement ?
- **On peut perdre au réveil.** Se lever à 5 slots avec 6 fils dedans fait tomber un fil avant même d'avoir joué.

L'énergie n'est pas une troisième ressource. C'est ce calcul. Le multiplicateur punit *dans* la journée (en temps), la nuit punit *entre* les journées (en capacité) — deux axes distincts, jamais cumulés sur la même jauge.

Affichage : une seule ligne à l'écran de coucher. *« Nuit agitée — 5 cases demain. »*

---

## 8. Les fils non ancrables

Un dispositif ne marche que sur du prévisible.

- **Ancrables :** repas, linge, courses, factures, ménage, administratif.
- **Non ancrables :** le gosse malade, le parent qui vieillit, l'ami qui va mal, l'humeur de quelqu'un dans la maison.

**Non ancrable ne veut pas dire inclôturable.** Ça veut dire : *aucun dispositif ne le porte à ta place*. Il n'y a pas de tableau au mur pour un enfant qui a de la fièvre — on paie en personne, en temps, tout de suite.

Un fil non ancrable est donc **temporaire** : il arrive sans prévenir, avec ses propres tâches, et il **se ferme quand elles sont faites**. Ses tâches sont *one-shot* — elles ne reviennent pas. Elles sont chères, parce que le temps est la seule sortie.

Et il **enfle deux fois plus vite** : une seule nuit d'inattention et il occupe déjà deux cases. On ne remet pas un imprévu à demain.

**Le plancher incompressible n'est pas « ce fil-là reste pour toujours », c'est « il y en aura un autre la semaine prochaine ».** C'est ce qui rend la victoire du §11 atteignable sans la rendre confortable : on peut finir une semaine la tête vide, on ne peut pas empêcher la suivante de commencer.

---

## 9. Les pièces

Le déplacement est ce qui donne son prix au temps, et ce qui permet de retrouver les fils lâchés.

**Une pièce à la fois, une scène par pièce.** On ne voit jamais le logement en entier. Ce n'est pas une contrainte technique, c'est la condition du §6 : tant que tout tient sur un écran, un fil au sol reste sous les yeux et n'est donc jamais vraiment oublié. Quitter la pièce doit faire disparaître ce qu'on y laisse.

**Topologie — plan réel, pièces adjacentes :**

```
Cuisine  ↔  Salon  ↔  Salle de bain / buanderie
```

Il n'y a pas de menu de destinations. Aller de la cuisine à la salle de bain se paie **deux fois**, parce qu'on traverse le salon. La géographie devient donc une donnée de planification : le salon est central et bon marché, les deux bouts sont chers l'un pour l'autre.

*(L'Épicerie — hors domicile, déplacement long — reste au programme mais n'est pas construite.)*

**On franchit une porte en marchant.** Pas de touche, pas de confirmation. On entre dans l'encadrement, le décor change, on ressort de l'autre côté. Le prix est écrit sur la porte, et il suit le multiplicateur.

**Changer de pièce coûte 0,5 unité, au tarif du jour.** Petit en soi, mais payé au multiplicateur comme tout le reste : à ×1.8 la traversée vaut presque une tâche. C'est ce qui rend la **dispersion** chère sans jamais l'interdire — le joueur saturé fait des allers-retours débiles, et le jeu les lui facture.

Deux règles qui vont avec :

- **Les seuils ne se facturent pas.** Seule une pièce *nouvellement atteinte* se paie, et le joueur réapparaît assez loin de la porte pour ne pas la redéclencher. On ne perd pas de temps à hésiter dans un couloir.
- **Ça ne se refuse jamais.** Contrairement à toutes les autres dépenses, on ne peut pas empêcher quelqu'un de marcher. Le temps tombe simplement à zéro, et la journée est finie même si l'horloge tourne encore.

**Un imprévu éclate exprès dans les trois pièces.** Les tâches du fil « Le petit est malade » sont réparties une par pièce : le jour où il tombe, la journée n'est plus qu'un trajet. C'est la traduction spatiale de « l'urgence mange tout ».

Chaque pièce a un nombre limité d'emplacements de dispositifs. La cuisine sature vite.
Un dispositif dans la mauvaise pièce ne fonctionne pas — le calendrier au garage, personne ne le regarde.

---

## 10. Lisibilité — fil vs tâche sans tutoriel

La règle s'enseigne par la position à l'écran, pas par du texte.

- **Les fils vivent dans le HUD-tête**, bandeau permanent en haut de l'écran.
- **Les tâches vivent dans le monde**, accrochées aux objets des pièces.
- **Ancrer**, c'est attraper un fil dans le bandeau et aller le poser physiquement sur un dispositif. Le geste descend le fil de la tête vers le monde.
- **Lâcher**, c'est le même trajet subi : le fil tombe du bandeau au sol.

Le joueur doit comprendre « ce qui est en haut me coûte, ce qui est en bas m'attend » sans qu'on le lui dise.

**Prévoir le triomphe.** Le risque n°1 du jeu, c'est qu'il ne soit que déprimant. Un ancrage réussi doit être une célébration franche : le fil quitte la tête, le multiplicateur redescend visiblement, l'ambiance sonore se dégage d'un cran. Le plaisir est dans le contraste.

---

## 11. Boucle et fin de partie

**Journée :** compteur de temps → déplacements et actions → coucher.
**Semaine :** lundi → dimanche. Le dimanche a un budget temps plus large : c'est la fenêtre d'ancrage, et le joueur y arrive cramé.

### Le calendrier

Les fils n'arrivent pas tous le lundi. Chacun a un **jour d'arrivée**, et la semaine est écrite pour monter : deux fils lundi, un de plus mardi, un de plus mercredi, et jeudi l'imprévu.

**La météo** annonce les arrivées deux à trois jours à l'avance, sous le bandeau. Elle sert à créer le regret : *« j'avais vu venir les factures, j'ai quand même rien préparé »*. L'imprévu, lui, n'y figure jamais — c'est sa définition.

Certains fils ont une **échéance**. Pas fait à temps : le fil part au sol le soir même, et compte pour l'effondrement. C'est ce qui donne un prix à la procrastination autre qu'une case en plus.

**Un fil ancré échappe à son échéance** — c'est exactement à ça que sert un prélèvement automatique. Mais si son dispositif a lâché la même nuit faute d'entretien, on découvre le soir même que rien n'a été payé. L'ancrage protège tant qu'on l'entretient, pas au-delà.

**Trois issues :**

- **Effondrement** — 3 fils lâchés simultanément au sol. La run s'arrête là.
- **Survie** — la semaine passe. Dimanche soir, on fait les comptes.

**S'asseoir n'est pas une fin, c'est un compteur.** Dépenser du temps à ne rien faire, avec une **case vide** dans la tête — pas juste du temps libre : de la place. Ça n'avance rien, ça ne ferme rien. La semaine continue, et l'écran de fin dit combien de fois on y est arrivé. Le résultat le plus courant est zéro, et c'est le propos.

---

## 12. À trancher

Deux mécaniques retenues comme prometteuses mais **non validées**. À implémenter seulement si le socle tourne.

### Interruption
Pendant l'exécution d'une tâche, un fil ouvert vient taper sur l'épaule : un pop à acquitter d'un clic.
Fréquence **proportionnelle au nombre de fils ouverts**, jamais aléatoire punitif. Coût quasi nul, juste agaçant.
But : faire passer la charge par les doigts du joueur au lieu de la lui montrer en chiffre.
Risque : devient vite insupportable. À doser ou à couper.

### Batching
Enchaîner deux tâches dans la même pièce, ou du même fil, rend la seconde moins chère.
But : créer une compétence de joueur, et rendre l'inefficacité *observable* — un joueur saturé n'anticipe plus et fait des allers-retours débiles.
Risque : ajoute une couche d'optimisation qui pourrait détourner du propos.

---

## 13. Périmètre du POC v0

Réduit au strict nécessaire pour répondre à la question 1 du playtest. Cinq minutes de jeu suffisent.

- **3 jours**, pas une semaine
- **3 pièces**, pas d'épicerie
- **5 fils**, dont 1 non ancrable
- **Emplacements de dispositif typés** — chaque emplacement n'accepte qu'un fil précis, ce qui supprime tout menu de sélection et encode la contrainte de pièce (§9). La sélection libre n'aura de sens qu'à partir de 5 fils.
- Pas de récurrence hebdomadaire, uniquement quotidienne
- Pas d'interruption, pas de batching

Tout le reste est de la plomberie qu'on ne construit pas avant de savoir si le cœur marche.

---

## 14. À valider en playtest

1. Est-ce que la saturation des slots se *ressent*, ou est-ce que ça reste un chiffre ?
2. Est-ce que le joueur délègue puis regrette ? (si non, la tâche « relancer » est trop douce)
3. Est-ce que la première réussite d'un ancrage produit un soulagement net ?
4. Est-ce que 6 slots est le bon chiffre ? Tester 5 et 7.
5. Le joueur comprend-il seul la différence entre fil et tâche, sans texte explicatif ?
6. Est-ce que retrouver un fil lâché par terre produit le « merde, j'avais oublié » recherché ?
7. Est-ce que le multiplicateur est lisible pendant qu'on joue, ou seulement après coup ?
8. Est-ce que voir un fil enfler à deux cases fait mal ? Est-ce que le joueur comprend seul que c'est lui qui l'a laissé grossir ?

---

## 15. Surcouches, plus tard

- **Phase travail** — verbes réduits à abattre / esquiver. Produit de l'argent, de la flexibilité, et des fils qu'on ramène à la maison.
- **Phase sommeil jouable** — la nuit devient une scène au lieu d'un calcul. Assez grosse pour avoir sa propre section : voir §16.
- **Casse subie des dispositifs** — l'usure par négligence est passée dans le socle (§3). Reste à ajouter la casse qu'on ne contrôle pas : vacances, maladie, absence du conjoint.
- **Conjoint** — fiabilité qui monte à force de délégations réussies, jusqu'au transfert complet d'un domaine.
- **Roguelite** — seuls les dispositifs ancrés à fond persistent entre les runs, et ils se dégradent s'ils ne sont pas entretenus.
- **Satire** — tout le vocabulaire d'interface parle en « optimisation », « efficience », « quick wins » pendant que le joueur ramasse.

---

## 16. La nuit jouable — le monde des rêves

**Décidé : on le fera.** Pas maintenant, et à condition d'entrée (fin de section).

### Le problème que ça résout

Un simulateur de charge, aussi juste soit-il, ne retient personne très longtemps. Le jour ne propose qu'une seule couleur d'émotion : la pression. Il manque une **ambivalence** — un endroit où le joueur ait envie d'aller, et qui rende la journée intéressante *autrement* que par la culpabilité.

La nuit est le seul espace disponible, et elle est déjà écrite : le §7 fait un calcul là où il pourrait y avoir une scène.

### Les deux couplages refusés

Le réflexe est de faire dépendre la difficulté nocturne de la qualité de la journée, et de rapporter du butin. Les deux sens possibles sont mauvais, et il n'y a pas de dosage entre eux :

- **Bonne journée → nuit facile → bon butin → meilleure journée.** Renforcement positif. Thématiquement parfait, la spirale est le sujet. Mécaniquement, la semaine se décide mardi et on joue trois jours une partie déjà perdue.
- **Mauvaise journée → nuit dure → meilleur butin.** Risque/récompense classique, et ça **inverse le propos** : se coucher saturé devient rentable, le joueur farme la surcharge. Le §1 est mort.

**Donc : pas de butin.** Le problème ne vient pas du réglage, il vient de la nature de ce que la nuit rend.

### La règle centrale

> **La journée n'ajuste pas la difficulté de la nuit. Elle écrit le niveau.**
> **On n'en rapporte pas de la puissance. On en rapporte des cases.**

Le rêve n'a pas d'économie propre : ni objets, ni statistiques, ni monnaie. Son unique sortie est la taille de la tête du lendemain — exactement la variable que le §7 calcule aujourd'hui dans un tableau.

> **Le §16 ne s'ajoute pas au §7. Il le remplace.** Le barème « 0–2 cases → +1 slot » devient le *résumé* d'une nuit qu'on n'a pas jouée, pas une règle parallèle.

Conséquence à tenir : **le plancher à 4 et le plafond à 6 restent le plafond du monde.** Une nuit héroïque ne donne pas 8 cases. On ne peut pas gagner sa journée en dormant.

### Ce que la journée écrit

L'état des fils au coucher devient la géographie du rêve. Rien n'est tiré au sort tant qu'il reste un fil à traduire.

| État du fil au coucher | Ce qu'il devient dans le rêve |
|---|---|
| **Ancré** | un mur déjà bâti — raccourci, salle sûre, porte qui s'ouvre seule |
| **Ouvert, tension 0** | un couloir neutre, qu'on traverse |
| **Ouvert, tension 2** | le couloir s'allonge, la salle se répète, on repasse au même endroit |
| **Lâché, au sol** | une chose qui poursuit, et **que le joueur ne peut pas nommer** |
| **Réglé / fermé** | absent — il n'a rien laissé derrière lui |

La ligne qui compte est celle du fil lâché. Le §6 l'a effacé du bandeau : le joueur ne l'a **plus en mémoire**, au sens propre. Il le retrouve la nuit sans savoir ce que c'est. C'est le §6 rendu littéral, et ça ne coûte aucune mécanique nouvelle.

**Corollaire de portée :** le procédural n'a presque rien à générer. La journée a déjà écrit le plan. Ce qui reste à produire, c'est de la variation d'habillage, pas de la conception de niveau.

### Ce qu'on ne construit pas

- **Pas d'inventaire, pas d'items, pas de stats.** Dès qu'un objet rapporté modifie le coût d'une tâche, on a rouvert les deux couplages refusés plus haut.
- **Pas de run longue.** La nuit dure des minutes, pas un quart d'heure. Le risque n°1 de ce genre de jeu à deux moitiés — Moonlighter, Cult of the Lamb — c'est que la moitié spectaculaire dévore l'autre et transforme la gestion en corvée. Ici la journée est le jeu ; la nuit en est la conséquence.
- **Pas de mort définitive dans le rêve.** Rater sa nuit, c'est se lever avec une case en moins. C'est déjà lourd. L'effondrement reste ce qu'il est au §11 : trois fils au sol, en plein jour.

### Condition d'entrée

Ne pas commencer avant que **le jour tienne seul**. Le POC actuel ne prouve rien contre lui : il tourne avec 2 verbes sur 6 et un contenu volontairement réduit (§13).

À faire d'abord, dans l'ordre :

1. **Déléguer** (§4) — l'axe symétrique d'Ancrer, la seconde vraie décision du jeu, non implémentée.
2. **Vider sa tête** (§5) — la soupape, non implémentée.
3. Une semaine rejouée avec les six verbes.

Si le jour tient 40 minutes avec ça, la nuit devient un projet à part entière. S'il ne les tient pas, aucun donjon ne l'aurait sauvé — il aurait juste caché le problème sous du contenu.
