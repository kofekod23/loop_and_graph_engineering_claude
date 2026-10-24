---
name: graph-engineering
description: Orchestrer une tâche de développement (tout langage) comme un graphe de contrôle (nœuds, arêtes, portes de validation) avec des sous-agents. À utiliser quand l'utilisateur dit "graph engineering", "mode graphe", "graphe de contrôle", ou veut qu'une tâche complexe (feature, refactor, correction de bug) soit découpée en étapes dépendantes, parallélisées et vérifiées plutôt que traitée dans une seule boucle.
---

# Graph engineering (graphe de contrôle)

Principe : une boucle retarde les décisions, un graphe les prend à l'avance.
On ne prompte plus l'agent pas à pas. On définit un graphe orienté dont chaque
nœud est une unité de travail (souvent un sous-agent) et chaque arête une
dépendance ou une condition de passage. Le graphe est la procédure (SOP) que
l'agent doit suivre pour obtenir un résultat fiable.

## Mémoire du projet (perfectionnement continu)

Le fichier `.graph/memoire.md` capitalise ce qui est propre au projet en cours. Il est versionné avec le dépôt.

Au démarrage : le lire s'il existe, et en tenir compte pour construire le graphe. S'il n'existe pas, le créer avec les sections ci-dessous après la première exécution.

Sections :
- Commandes : comment lancer tests, lint, build, serveur dans ce projet.
- Conventions : nommage, structure des dossiers, bibliothèques imposées ou interdites.
- Pièges : erreurs déjà rencontrées et leur cause (ex. "le test X dépend d'une variable d'environnement Y").
- Graphe éprouvé : variantes du graphe type qui ont bien fonctionné ici (nœuds ajoutés, ordre, parallélisme sûr ou risqué).
- Réglages : seuils propres au projet (nombre de reprises utile, périmètres de fichiers qui se recoupent).

À la clôture : ajouter au plus 3 à 5 lignes, uniquement des enseignements vérifiés pendant l'exécution (échec corrigé, commande confirmée, nœud devenu utile). Pas de journal de bord, pas de doublon. Si une ligne existante est devenue fausse, la corriger plutôt que d'en ajouter une autre. Garder le fichier sous 80 lignes en fusionnant les entrées voisines.

Quand une leçon revient dans plusieurs tâches, la promouvoir en règle dans la section Conventions ou Graphe éprouvé.

## Étape 0 : construire le graphe avant d'agir

Avant toute modification de code, lire `.graph/memoire.md`, puis écrire le graphe dans `.graph/plan.md` :

- Nœuds : id, objectif, entrées, sorties attendues, critère de réussite.
- Arêtes : `A -> B` (B dépend de A), `A -> B | si échec` (branche de reprise).
- Parallélisme : marquer les nœuds sans dépendance commune comme `//`.
- Portes (gates) : points où un nœud de vérification peut bloquer la suite.

Montrer le graphe à l'utilisateur sous forme compacte (liste ou Mermaid) et
attendre sa validation si la tâche est coûteuse ou irréversible.

## Graphe type pour livrer un changement de code

```
[explore] -> [plan] -> [implémenter] -> [tests] -> [revue] -> [livrer]
                           ^               |          |
                           +---- échec ----+          |
                           +------ corrections -------+
```

Nœuds :

1. explore : lecture seule (Explore). Cartographie modules, imports, tests existants. Sortie : résumé de 15 lignes max.
2. plan : découpe en tâches indépendantes. Sortie : liste de nœuds d'implémentation avec fichiers concernés.
3. implémenter : un sous-agent par tâche indépendante, en parallèle, chacun dans son périmètre de fichiers (worktree si les fichiers se recoupent).
4. tests : détecter la stack puis lancer les commandes du projet. Priorité à celles listées dans `.graph/memoire.md`, sinon déduire des fichiers présents :
   - `pyproject.toml`, `requirements.txt` : `pytest -q`, puis `ruff check .` et `mypy` si configurés
   - `package.json` : scripts `test`, `lint`, `build` (npm, pnpm ou yarn selon le lockfile)
   - `go.mod` : `go test ./...` et `go vet ./...`
   - `Cargo.toml` : `cargo test` et `cargo clippy`
   - `pom.xml`, `build.gradle` : `mvn test` ou `gradle test`
   - `Makefile`, CI (`.github/workflows`) : reprendre les commandes qui y figurent
   Si rien n'est détectable, demander la commande à l'utilisateur, puis l'enregistrer dans la mémoire. Sortie : verdict binaire + log court.
5. revue : sous-agent distinct, qui n'a pas vu l'implémentation, compare le diff à la spec du nœud plan.
6. livrer : commit puis push, voir règles Git.

## Règles d'exécution

- Un nœud = une responsabilité. Si un nœud grossit, le scinder.
- Chaque nœud ne reçoit que les sorties de ses prédécesseurs (contexte minimal).
- Lancer en parallèle tous les nœuds dont les dépendances sont satisfaites, dans un seul message d'appels d'agents.
- Les portes sont bloquantes : tests rouges ou revue négative renvoient vers le nœud implémenter avec le motif d'échec. Maximum 3 passages par arête de reprise, puis s'arrêter et demander à l'utilisateur.
- Graphe dynamique : si un nœud révèle du travail imprévu, ajouter des nœuds au plan, mettre à jour `.graph/plan.md` et le dire en une ligne.
- Tenir à jour l'état de chaque nœud dans `.graph/plan.md` : `todo`, `en cours`, `ok`, `échec`.
- Utiliser la liste de tâches de l'agent comme miroir du graphe (une tâche par nœud, même état).
- Ne jamais élargir le périmètre d'un nœud sans l'avoir noté dans le plan.

## Git

- Committer avec l'identité Git déjà configurée dans le dépôt, sans la modifier.
- Respecter les conventions de commit du projet (voir `.graph/memoire.md`), sinon messages courts à l'impératif.
- Ajouter `.graph/plan.md` au `.gitignore` (état temporaire), mais versionner `.graph/memoire.md`.

## Style

- Respecter le langage, les conventions et les outils déjà en place dans le projet. Ne pas introduire de nouvelle dépendance sans le noter dans le plan.
- Rédiger dans la langue du projet.

## Clôture

Terminer par : le graphe final avec l'état de chaque nœud, ce qui a été livré, les lignes ajoutées à `.graph/memoire.md`, et un seul prochain pas utile.
