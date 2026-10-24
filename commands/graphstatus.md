---
description: Afficher l'état du graphe en cours (lecture seule)
---

Lis `.graph/plan.md` sans rien modifier et affiche en quelques lignes : chaque nœud avec son type et son état, le tour en cours et la dernière mesure des nœuds `boucle`, les portes franchies ou bloquantes, et le prochain nœud exécutable.

Si `.graph/plan.md` n'existe pas, dis-le et propose `/graphloop` ou `/graphplan`.
