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

### Deux sortes de dispositifs

Décidé à l'implémentation. Un prélèvement automatique **paie vraiment la facture** : une fois en place, il n'y a plus de courrier à ouvrir ni de virement à faire. Un tableau des menus, lui, **ne cuisine pas** — il rappelle, et il s'use si on ne le nourrit pas. On les traitait pareil ; c'est faux.

- **Ancrage d'entretien** (défaut) : le fil passe en `ANCRE`, rend sa case, ses tâches restent dans le monde, sa tension devient l'usure du dispositif. Si on néglige, ça décroche.
- **Ancrage définitif** : le fil est `FERME`. Il rend sa case, ses tâches quittent le monde, son échéance ne s'applique plus, et il ne revient pas. C'est le seul endroit du jeu où quelque chose est vraiment fini.

**Ce n'est pas le retour de l'allègement refusé ci-dessus.** Ce qu'on refusait, c'était de faire *baisser le coût* des tâches d'un fil ancré : ça brouillait Ancrer et Déléguer et ça contredisait la phrase du jeu. Ici il n'y a plus de tâches du tout — c'est tout ou rien, et le dispositif annonce lequel des deux il est avant qu'on paie (`tu n'y touches plus` / `à entretenir`).

**Le définitif se paie plus cher**, sinon aucun autre ancrage ne vaudrait la peine. Le prix est réglable par emplacement dans l'inspecteur, pas en dur dans le code. Départ : 6,0 contre 4,0.

Le seul dispositif définitif du POC est le prélèvement automatique. Le fil des factures arrive jeudi avec une échéance samedi : trois jours pour réunir 6,0 de temps **et** une case libre, ou il tombe. C'est exactement la fenêtre que le §5 décrit — on s'en sort quand ça va encore bien.

**À trancher :** faut-il d'autres dispositifs définitifs ? Un seul sur quatre en fait un moment rare et mémorable ; deux en feraient une stratégie.

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

### Vider sa tête — décidé à l'implémentation

**Le miroir de la salle de bain.** Pas le lit : il n'y a pas de chambre, et le lit servirait de toute façon à finir la journée. La salle de bain est la pièce où l'on va le moins, donc décider de ne plus penser à quelque chose demande de s'être déplacé pour ça — même principe que Sam, le prix est dans le trajet.

**Gratuit en temps, et ça doit le rester.** C'est le seul verbe gratuit du jeu. Une soupape qui coûte du temps est fermée exactement le jour où l'on en a besoin — c'est le défaut qu'on a déjà corrigé une fois sur Déléguer. Le prix est différé : il tombe dans deux nuits et ne se négocie pas.

**On ne choisit pas ce qu'on écarte : le miroir prend le fil le plus tendu.** Plus vrai qu'un menu — on ne lâche pas ce qu'on décide, on lâche ce qui pèse — et ça évite un sélecteur que le POC refuse (§13). Le miroir nomme le fil et la date de retour avant qu'on appuie : le joueur voit ce qu'il va lâcher et peut repartir.

**Le fil enfle pendant qu'il est écarté**, et sans recours : ses tâches ne sont nulle part, donc rien ne peut le calmer. Il revient donc à deux cases, et souvent il tombe en revenant. C'est ce qui empêche le verbe d'être un snooze : *ne plus y penser ne le fait pas disparaître, ça le fait grossir*.

**Une échéance ne s'écarte pas.** Un fil à date butoir écarté tombe le jour dit, comme s'il était resté ouvert. Sinon vider sa tête serait le moyen le moins cher de traverser une échéance — alors que ne pas y penser ce jour-là est très précisément la façon dont on la rate.

**Un fil écarté garde une case dans le bandeau**, après les cases vides, presque noire : il ne pèse rien — pour l'instant — mais il est là, il compte à rebours, et il porte déjà la taille qu'il aura en revenant, jauge de tension comprise. Sans cette case, un fil écarté est indiscernable d'un fil ancré : les deux disparaissent du bandeau, alors qu'ils font l'inverse l'un de l'autre. C'était la première chose qu'on ne comprenait pas en jouant.

**Le miroir parle à la première personne, et dans les mots où on se le dit vraiment :** *« j'm'en bats les couilles de X »*. « Vider sa tête » sonne comme du repos ; c'est le geste le plus violent du jeu, et le seul qu'on s'adresse à soi-même dans une glace.

Chiffre de départ, **non validé** : retour à 2 jours.

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

**Plancher à 4 slots, plafond au max de base (6)** — sauf nuit paisible, la seule exception, ouverte par le §16.
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

Ce qui reste une fois les trois systèmes du §17 mis de côté. Chaque entrée dit à quel système elle s'accroche : rien ici n'est un système à soi tout seul, et c'est le test qui permet de refuser d'en faire un.

- **Phase travail** *(burn-out)* — verbes réduits à abattre / esquiver. Produit de l'argent, de la flexibilité, et des fils qu'on ramène à la maison.
- **Casse subie des dispositifs** *(burn-out)* — l'usure par négligence est passée dans le socle (§3). Reste à ajouter la casse qu'on ne contrôle pas : vacances, maladie, absence du conjoint.
- **Conjoint** *(burn-out)* — fiabilité qui monte à force de délégations réussies, jusqu'au transfert complet d'un domaine. C'est la suite naturelle de Déléguer, pas une mécanique neuve.
- **Roguelite** *(structure)* — seuls les dispositifs ancrés à fond persistent entre les runs, et ils se dégradent s'ils ne sont pas entretenus. À reconsidérer maintenant que la partie n'est plus bornée à une semaine (§17) : sans fin de run, il n'y a plus de « entre les runs ».
- **Satire** *(habillage)* — tout le vocabulaire d'interface parle en « optimisation », « efficience », « quick wins » pendant que le joueur ramasse.

> **Sortie :** « Phase sommeil jouable » n'est plus une surcouche. C'est le dream system, §16 et §17.

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

Conséquence à tenir : **le plancher est à 4, et le plafond ordinaire à 6.** Une nuit héroïque ne donne pas 8 cases. On ne peut pas gagner sa journée en dormant.

**Une seule porte au-dessus de 6 : la nuit paisible.** Se coucher la tête *entièrement* vide — aucune case occupée, donc aucun monstre à affronter — ne se joue pas. On affiche une ligne et on se réveille à **7**.

Sept **quel que soit le point de départ** : la nuit vide ne compte pas les cases, elle pose le chiffre. Le barème du §7 ne s'applique pas ce matin-là. C'est ce qui garde ouverte la sortie par le bas — à 4 cases, une tête vide demande une journée que 4 cases ne permettent plus de faire, et s'il fallait trois nuits parfaites d'affilée pour remonter, le plancher serait une prison. **La nuit vide est la remontée, pas son premier échelon.**

C'est la moitié montante de la spirale du §17 : mieux dormi, donc plus de place, donc des journées qu'on tient, donc mieux dormi — jusqu'au fil de trop.

Ce n'est pas le butin refusé plus haut : une case n'est pas de la puissance, c'est la seule monnaie que la nuit ait le droit de rendre, et c'est déjà celle du §7. Et ça ne rouvre pas le couplage « bonne journée → nuit facile » : la condition n'est pas *une bonne journée*, c'est **zéro case**, un état que le calendrier des arrivées rend rare ou impossible à volonté. La difficulté d'y accéder est une affaire de contenu, pas de règle.

**La septième case ne vaut que pour la journée suivante.** Elle n'est pas acquise : à la nuit d'après, s'il y a eu quelqu'un à affronter, le plafond redevient 6 et la case s'en va — même si le combat s'est bien passé. C'est un prêt sur une nuit vide, pas un palier gagné, et il faut refaire une journée parfaite pour le reprendre.

C'est ce qui empêche la spirale montante de devenir un cliquet. Sans ça, une seule journée parfaite suffirait à s'installer à 7 pour le reste de la partie, et le §17 y perdrait sa descente : le plafond doit pouvoir remonter, il ne doit pas pouvoir se verrouiller.

### Ce que la journée écrit

L'état des fils au coucher devient la géographie du rêve. Rien n'est tiré au sort tant qu'il reste un fil à traduire.

| État du fil au coucher | Ce qu'il devient dans le rêve |
|---|---|
| **Ancré** | un mur déjà bâti — raccourci, salle sûre, porte qui s'ouvre seule |
| **Ouvert, tension 0** | un couloir neutre, qu'on traverse |
| **Ouvert, tension 2** | le couloir s'allonge, la salle se répète, on repasse au même endroit |
| **Lâché, au sol** | une chose qui poursuit, et **que le joueur ne peut pas nommer** |
| **Réglé / fermé** | absent — il n'a rien laissé derrière lui |

**L'ancré écarte et retient, il ne tue pas.** La première version balayait ce qui l'entourait, et gagnait la nuit d'un seul appui : tous les monstres convergent sur le rêveur, donc n'importe quel effet centré là les attrape tous — ce n'était pas un rayon mal réglé, c'était structurel. Un dispositif ne fait pas le travail à ta place, il fait qu'il y a moins à faire d'un coup. Ce qu'il achète est du temps et de la place ; la nuit reste entièrement à jouer à la main. La chose sans nom y échappe : un dispositif ne règle pas ce qu'on a laissé tomber, il faut aller le ramasser dans la journée.

La ligne qui compte est celle du fil lâché. Le §6 l'a effacé du bandeau : le joueur ne l'a **plus en mémoire**, au sens propre. Il le retrouve la nuit sans savoir ce que c'est. C'est le §6 rendu littéral, et ça ne coûte aucune mécanique nouvelle.

**Corollaire de portée :** le procédural n'a presque rien à générer. La journée a déjà écrit le plan. Ce qui reste à produire, c'est de la variation d'habillage, pas de la conception de niveau.

### Ce qu'on ne construit pas

- **Pas d'inventaire, pas d'items, pas de stats.** Dès qu'un objet rapporté modifie le coût d'une tâche, on a rouvert les deux couplages refusés plus haut.
- **Pas de run longue.** La nuit dure des minutes, pas un quart d'heure. Le risque n°1 de ce genre de jeu à deux moitiés — Moonlighter, Cult of the Lamb — c'est que la moitié spectaculaire dévore l'autre et transforme la gestion en corvée. Ici la journée est le jeu ; la nuit en est la conséquence.
- **Pas de mort définitive dans le rêve.** Rater sa nuit, c'est se lever avec une case en moins. C'est déjà lourd. L'effondrement reste ce qu'il est au §11 : trois fils au sol, en plein jour.

### Condition d'entrée

Ne pas commencer avant que **le jour tienne seul**.

1. ~~**Déléguer** (§4) — l'axe symétrique d'Ancrer, la seconde vraie décision du jeu.~~ Fait, deux playtests, deux refontes du coût.
2. ~~**Vider sa tête** (§5) — la soupape.~~ Fait.
3. ~~Une semaine rejouée avec les six verbes.~~ **Fait. Le jour tient.**

**La condition est remplie.** Semaine bouclée, 7 jours tenus, deux assises, canapé refusé cinq jours sur sept. Les courses tenues par dispositif, les factures réglées par prélèvement automatique, l'imprévu géré jusqu'au bout. Et surtout : **les six verbes ont tous servi, et il a fallu les six.** Aucun n'est mort, aucun n'est dominant.

Deux choses que cette run confirme et qu'il ne faut pas casser en touchant à autre chose :

- **Le renoncement reste dominant.** Cinq refus contre deux assises. Le §11 tablait sur l'impossibilité de se reposer ; c'est le renoncement calculé qui produit la sensation, et il survit à l'arrivée des quatre nouveaux verbes. C'était le risque principal — donner plus d'outils au joueur aurait pu rendre le repos facile. Ça ne l'a pas fait.
- **Trois fils sur cinq neutralisés, et le joueur ne s'est quand même assis que deux fois.** Le jeu ne se gagne pas en supprimant des fils : ça libère juste assez de place pour continuer.

La nuit jouable devient donc un projet à part entière.

---

## 17. Les trois systèmes

Le POC a prouvé un système. Le jeu en aura trois, et les nommer n'est pas du rangement : la frontière entre eux **est** une règle de design, et c'est elle qui empêche le jeu de devenir un simulateur de gestion générique où tout se vaut.

| Système | Ce qu'il porte | État |
|---|---|---|
| **Burn-out system** | Temps, cases, les six verbes, les fils et les tâches | Fait — §1 à §11 |
| **Dream system** | La nuit jouée. Écrite par la journée, ne rend que des cases | Spécifié — §16 |
| **Survival system** | Faim, soif, humeur | Les trois sont faits ; reste à les régler au playtest |

### La règle qui sépare charge et survie

> **La charge est dans la tête. La survie est dans le corps.**
> **Un besoin de survie ne prend jamais de case.**

Personne n'a une case occupée par « il faut que je mange ». On a faim, c'est tout. La conséquence est double, et elle vaut d'être écrite :

- **On ne peut pas ancrer la faim.** Aucun des six verbes ne mord sur le survival system. Pas de dispositif, pas de délégation, pas de « je m'en bats les couilles » — ce sont deux pressions qui ne se négocient pas l'une contre l'autre.
- **Le survival system n'a pas de fils.** Il ne produit ni tension, ni échéance, ni débordement. S'il en produisait, ce serait du burn-out system avec un autre nom, et la distinction n'aurait servi à rien.

Ce que le survival system a le droit de faire, c'est **mordre sur les deux ressources existantes** : pas mangé → moins de temps demain ; mal dormi → moins de cases demain. Il n'ajoute pas de troisième ressource. C'est ce qui le garde petit.

### Les trois besoins

**Faim.** Le seul qui ferme une boucle déjà ouverte : « faire à manger » était une tâche qui ne produisait rien, le repas disparaissait et il ne restait que le lave-vaisselle. Avec la faim, le repas a une destination.

> **Fait le 2026-09-17.** Les plaques ouvrent l'accès, l'assiette le consomme, la table le referme — trois meubles, trois gestes, et le repas périme à la nuit. Le détail est plus bas, dans « Ce qu'une tâche laisse derrière elle ».

**Soif.** Le meilleur des trois, et pour une raison contre-intuitive : **boire ne coûte presque rien, et c'est exactement pour ça que ça marche.** Le joueur va sauter l'action la moins chère du jeu, tous les jours, et s'en apercevoir le soir. « J'ai pas bu de la journée » est un symptôme de surcharge plus juste que la faim, parce qu'il ne s'explique par aucun manque de temps.

> **Condition :** la soif reste quasi gratuite. Dès qu'elle coûte du vrai temps, c'est de la faim en plus petit, et elle ne prouve plus rien.

**Le paragraphe ci-dessus se contredisait, et voici par où.** Il affirme que le joueur « va sauter l'action la moins chère du jeu ». Il n'en a aucune raison : si boire est gratuit et que ne pas boire est puni, un joueur correct boit systématiquement, et la soif devient le clic obligatoire le plus ennuyeux du jeu. Pour qu'on la saute, il faut qu'elle coûte quelque chose — mais pas du temps, sinon c'est de la faim en plus petit.

> **Le prix de boire n'est pas le verre, c'est le détour.** Le geste coûte zéro. Mais il faut être à la cuisine, donc il coûte un changement de pièce, facturé au tarif du jour par le §9. C'est gratuit quand tout va bien, et cher exactement le jour où l'on est dispersé. Aucun chiffre nouveau : le multiplicateur fait déjà tout le travail.

**Comment elle se compte.** La réserve n'est pas une horloge, c'est **un capital de temps** : douze unités sur une journée qui en fait quinze. Elle descend en agissant, pas en dormant — une journée de course assèche, une journée molle non. Le joueur doit donc passer boire une fois dans la journée, sans que le jeu lui dise jamais quand.

**Et à sec.** Rien ne se déclenche avant zéro. Une fois la réserve vide, chaque unité de temps consommée coûte un cran d'humeur, donc une unité de temps demain — et le corps a **trois jours** pour être réapprovisionné avant que la partie s'arrête. C'est la seconde fin du jeu, à côté de l'effondrement, et la seule qui ne vienne pas de la tête.

**Humeur.** Elle ne se remplit pas, elle **se constate**. Ce n'est pas un besoin, c'est le résultat de la façon dont on a joué.

> **Elle mord sur le temps, et sur rien d'autre.** Dix crans ; chaque cran perdu retire une unité au budget du lendemain.
>
> C'est le seul emplacement libre, et il faut qu'il le reste. Lui faire coûter des **cases** ferait doublon avec la nuit, qui ne sait produire que ça (§16) — le dream system n'aurait plus de monnaie à lui. Lui faire **grossir les fils** ferait doublon avec la tension : `Fil.taille()` passe déjà un fil négligé à deux cases (§4, §6), et deux causes pour un même effet rendent les deux illisibles. D'où la règle : **la tension coûte des cases, la nuit en rend, l'humeur coûte du temps.** Une monnaie par système, aucun recouvrement.

**Ce qui la fait descendre, aujourd'hui : rien d'autre que le corps à sec.** Chaque unité de temps consommée la réserve vide coûte un cran. Le seuil ne se déclenche qu'à zéro, donc **un joueur qui passe boire ne perdra jamais un seul cran** — ce système ne mord que la négligence, et il mord fort quand elle arrive. Les fils au sol et les échéances ratées ne l'entament pas encore : c'est un branchement de plus, pas une conséquence du besoin.

**Ce qui la fait remonter : une journée sans faute** — aucune réserve à sec au coucher, aucun fil par terre. Deux crans, réglables.

> **La remontée se dimensionne sur la descente, pas à l'intuition.** Une journée entière jouée à sec coûte jusqu'à dix crans. À un cran rendu par jour, une seule étourderie condamnerait dix journées, jouées amputées, donc tenues de plus en plus mal : un cliquet, et la spirale ne remonte plus jamais. Le jeu est censé tourner dans les deux sens.

> **Refusé : une jauge de divertissement.** S'asseoir *est* déjà le divertissement, et c'est le cœur validé du jeu (§16, condition d'entrée) : « j'avais la place, j'ai calculé, j'ai renoncé ». Une jauge qui réclame du repos transforme le renoncement en faute et punit mécaniquement le seul geste que deux playtests ont validé.
>
> **Le jour où l'interface dit « va te divertir », le verbe est mort.** L'humeur donne un prix visible au renoncement ; elle ne le condamne jamais, et elle n'interdit rien.

### Ce que le corps affiche

Deux zones, qui redisent la règle par leur position et sans une ligne de texte :

- **La tête**, en haut — temps, cases. Ce qui se négocie.
- **Le corps**, en bas — les besoins, et l'humeur. Ce qui ne se négocie pas.

**Des jauges, et assumées.** Une version antérieure de cette section les refusait au motif que l'humeur « se lit sur le personnage » et qu'une jauge en ferait une chose à optimiser. Tranché le 2026-09-17 : ce sera une jauge. Trois raisons, dans l'ordre de leur poids.

1. **Le corps peut tuer.** Trois jours sans boire arrête la partie. Une fin annoncée est une règle ; une fin découverte au moment où elle tombe est un piège. Le décompte s'affiche donc chaque matin, sur la jauge et dans le bandeau.
2. **Le seul reproche du playtest externe est déjà « on ne voit pas ».** Le jeu tient, mais ce qu'il faut faire n'est pas lisible, faute de retours visuels. Ajouter un compteur mortel invisible irait droit dans le défaut connu.
3. **L'humeur dit ce qu'elle coûte, en chiffres.** « Humeur 7/10 — −3 de temps ». Une jauge qui descend sans dire à quoi elle sert n'est qu'une décoration inquiétante.

Le visage viendra **en plus**, pas à la place. Et la crainte d'origine tient toujours, mais elle ne portait pas sur la jauge : elle portait sur ce qui remplit l'humeur. C'est réglé autrement, ci-dessous.

> **Refusé, et ça n'a pas bougé : s'asseoir ne remonte pas l'humeur.** S'asseoir est le divertissement, et c'est le cœur validé du jeu (§16, condition d'entrée) : « j'avais la place, j'ai calculé, j'ai renoncé ». Si le canapé rendait de l'humeur, et l'humeur du temps, **s'asseoir deviendrait rentable** — « ça n'avance rien, ça ne ferme rien » s'effondrerait, et avec lui le renoncement calculé que deux playtests ont produit.
>
> **Le jour où l'interface dit « va te divertir », le verbe est mort.** L'humeur ne s'achète nulle part : elle remonte parce que la journée s'est bien passée, jamais parce qu'on a payé pour.

### Ce qu'une tâche laisse derrière elle

Le §18 disait que « faire à manger » est une tâche qui ne produit rien. Elle peut désormais produire : **une tâche ouvre ou ferme l'accès à un besoin.** Cuisiner met un repas sur la table, débarrasser l'enlève. Le besoin, lui, continue de se vider pendant ce temps-là — c'est ce qui donne un prix à l'oubli de cuisiner.

> **Ça ne nourrit pas, ça rend le geste possible.** Cuisiner ne remplit aucune réserve. Le repas est là, il reste à le manger, et manger se paie à son meuble comme boire. Deux gestes, deux détours. Sinon la tâche deviendrait un moyen détourné de recharger le corps sans se déplacer, et le prix-détour du §18 tomberait.

**Écrit comme une liste d'effets, pas comme un cas particulier.** Chaque `TacheDef` porte une liste d'`EffetTache`, posée dans l'inspecteur. `EffetBesoin` est le premier du genre : il ouvre ou il ferme un besoin. Les suivants s'écriront à côté, sans rouvrir la boucle qui résout les tâches — `Partie` ne sait pas ce que fait un effet, seulement qu'il faut l'appliquer.

**Ce qui s'ouvre finit par se refermer.** Un besoin porte un délai de péremption en jours, compté au coucher. Zéro pour la soif — le robinet ne se referme jamais. Un pour le repas : ce qui était sur la table aujourd'hui y était pour aujourd'hui. Sans ce compteur, cuisiner lundi nourrirait toute la semaine, et la faim sortirait du jeu au deuxième jour.

**Déléguer produit l'effet sur-le-champ.** Sam cuisine immédiatement ; le repas est sur la table à la seconde où on lui a demandé. La relance, elle, est une affaire de lendemain.

> **Essayé et retiré le 2026-09-17 : faire attendre l'effet jusqu'à la relance.** C'était censé produire « Sam devait cuisiner, on n'a pas relancé, ce soir on n'a pas mangé ». Ça a produit autre chose : un monde incohérent. Une tâche a deux moitiés — elle **débloque des tâches filles**, et elle **change le monde**. Ne différer que la seconde faisait apparaître « débarrasser la table » alors que l'assiette était vide. **Les deux moitiés d'une même tâche tombent au même instant, ou le décor se met à mentir.**
>
> Le scénario de la délégation ratée reviendra par un Sam qui traîne, pas par un effet qu'on retient. Ce n'est pas la même chose : un délégataire lent est une conséquence lisible, un effet suspendu est un décalage invisible entre ce que le monde montre et ce qu'il contient.

> **L'impasse existe, et elle est assumée (tranché le 2026-09-17).** Un besoin fermé au départ dépend d'une tâche pour s'ouvrir. Si son fil est écarté, il revient au bout de deux jours ; s'il tombe par terre, il n'a **aucune date de retour** et il faut aller le chercher dans le logement, que le jeu ne désigne jamais. Perdre le fil `repas` peut donc tuer. Aucune porte de secours n'a été posée : l'alerte du matin prévient trois jours à l'avance, et c'est tout ce que le joueur aura.

### La semaine n'est plus la fin

Les sept jours du §11 sont un échafaudage de POC, pas le jeu. La partie est longue : on ne survit pas à une semaine, on garde quelqu'un en vie.

**Ce que ça déplace :** la descente de 6 à 4 cases était l'arc complet d'une semaine. En partie longue, elle est finie en dix jours, et rester cloué au plancher pour toujours ferait du jeu un compte à rebours vers un état stable et sans issue. **La spirale doit être remontable.**

**Décidé — d'où vient la remontée :** du contenu, pas d'une mécanique de plus. D'autres fils, d'autres tâches, d'autres échéances, d'autres coûts, écrits à la main par-dessus le socle. Les cinq fils actuels sont un jeu de test, pas un équilibrage : raisonner sur eux comme s'ils étaient le jeu mène à inventer des systèmes pour résoudre des problèmes qui n'existent que dans le jeu de test. Et le dream system est déjà la voie de remontée mécanique — il ne lui en faut pas une seconde.

### Ordre de construction

1. **Dream system.** Spécifié, débloqué, et c'est lui qui rend la partie longue tenable.
2. **Contenu** — les fils, tâches et échéances qui font une partie longue.
3. **Survival system.** En dernier : il demande de retoucher le contenu des fils, donc il vient après que ce contenu existe.

**Cet ordre a été enfreint le 2026-09-17, et le survival system est passé en premier.** D'abord la soif, parce qu'elle est le seul des trois besoins qui ne demande aucun contenu : un point d'eau, une réserve, une jauge. Puis la faim le même jour, une fois qu'il est apparu que la dépendance au contenu tenait en trois `.tres` et deux meubles — et qu'écrire le branchement tâche → besoin était de toute façon le seul moyen de savoir s'il tenait.

- **La faim** avait besoin de tâches « faire à manger », d'un repas qui a une destination et d'une délégation qui rate. Les trois existent. Ce qui reste à faire est du réglage, pas de la conception : les chiffres du `.tres` n'ont jamais été joués.
- **L'humeur** existe désormais, mais elle ne se nourrit que du corps. Qu'elle descende aussi sur les fils au sol et les échéances ratées demande une partie longue pour avoir quelque chose à observer — sur sept jours de test, elle n'a rien à constater.

**Le dream system, lui, reste ouvert**, et ce n'est pas la soif qui le refermera : le verbe de la nuit n'est toujours pas tranché.

**À trancher, et c'est le seul point ouvert du §16 :** *que fait le joueur dans le rêve ?* La section dit ce qu'on en rapporte, ce qu'on n'y met pas et comment la carte s'écrit à partir des fils — elle ne dit jamais le verbe. Marcher, fuir, chercher, ouvrir. Rien ne peut commencer avant ça.
