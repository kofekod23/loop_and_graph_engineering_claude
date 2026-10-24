---
description: Reprendre l'exécution du graphe là où elle s'est arrêtée
argument-hint: [consigne facultative]
---

Reprends l'exécution du graphe décrit dans `.graph/plan.md` selon les règles de la skill graph-engineering. Consigne supplémentaire éventuelle : $ARGUMENTS

Ne refais pas les nœuds `ok`. Repars des nœuds `en cours` ou `échec`, puis enchaîne les nœuds dont les dépendances sont satisfaites. Une boucle reprend avec le budget qui lui reste, jamais avec un budget remis à zéro sans mon accord.

Si `.graph/plan.md` n'existe pas, dis-le et propose `/graphplan`.
