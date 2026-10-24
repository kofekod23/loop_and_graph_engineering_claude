# claude-code-graph-engineering : graph engineering et boucles d'agents pour Claude Code

🇫🇷 Français | 🇬🇧 [Read in English](README.en.md)

**Skill Claude Code qui transforme une tâche de développement en graphe de contrôle : sous-agents en parallèle, portes de validation, boucles bornées qui itèrent jusqu'à un critère vérifiable, et une mémoire qui s'adapte à chaque projet.**

Point fort : **l'auto-adaptation**. À chaque exécution, la skill apprend les commandes, les conventions et les pièges de votre dépôt, puis les réutilise pour construire un meilleur graphe la fois suivante.

> Projet communautaire, non affilié à Anthropic. "Claude" et "Claude Code" sont des marques d'Anthropic, citées ici pour décrire la compatibilité.

---

## À quoi ça sert

Avec Claude Code, on prompte souvent l'agent pas à pas, dans une seule boucle. Pour une tâche longue (nouvelle fonctionnalité, refactor, correction de bug), c'est fragile : contexte qui gonfle, étapes oubliées, vérification faite par l'agent qui a écrit le code.

Le **graph engineering** remplace cette boucle par un plan défini à l'avance :

- chaque **nœud** est une unité de travail (souvent un sous-agent),
- chaque **arête** est une dépendance ou une condition de passage,
- chaque **porte** peut bloquer la suite (tests rouges, revue négative).

Résultat : un processus reproductible, parallélisé, et vérifié par un agent qui n'a pas écrit le code.

## Ce que fait la skill

1. **Cartographie avant d'agir** : écrit le graphe dans `.graph/plan.md` (nœuds, dépendances, parallélisme, portes) et le soumet à validation si la tâche est coûteuse.
2. **Exécute en parallèle** tous les nœuds dont les dépendances sont satisfaites.
3. **Vérifie par des portes bloquantes** : tests, lint, puis revue indépendante du diff contre la spécification.
4. **Reprend en cas d'échec** avec le motif, limité à 3 passages avant de vous redonner la main.
5. **Étend le graphe en cours de route** si une étape révèle du travail imprévu (graphe dynamique). Au-delà de 2 nœuds ajoutés, ou hors du périmètre prévu, il vous redemande validation.
6. **Fait tourner en boucle les nœuds mécaniques** (faire passer des tests, corriger le lint, passer sous un seuil de performance), avec une commande de vérification et un budget de tours.
7. **Apprend du projet** et enregistre ses enseignements dans `.graph/memoire.md`.

Graphe type :

```
[explore] -> [plan] -> [implémenter] -> [tests] -> [revue] -> [livrer]
                           ^               |          |
                           +---- échec ----+          |
                           +------ corrections -------+
```

## Graphe de boucles : le graphe gouverne, la boucle itère

Un nœud du graphe peut être une `tâche` (un seul passage) ou une `boucle`. Une boucle tourne jusqu'à ce qu'une commande confirme le résultat, par exemple `pytest -q` sans échec. Elle déclare son objectif, sa commande de vérification, son budget de tours (5 par défaut) et la mesure qui montre le progrès.

Elle s'arrête quand le critère est atteint, quand le budget est épuisé, ou après 2 tours sans progrès. L'agent qui travaille dans la boucle n'a pas le droit de modifier les tests ou les seuils pour réussir : si l'un d'eux paraît faux, il sort et vous le signale. Une boucle qui échoue suit l'arête d'échec du graphe, jamais une relance silencieuse.

Pour une tâche récurrente, le graphe entier peut aussi être relancé à intervalle régulier avec `/loop`.

## Auto-adaptation : la mémoire de projet

Le fichier `.graph/memoire.md` est lu au démarrage et enrichi à la clôture (3 à 5 lignes au maximum, uniquement des enseignements vérifiés).

| Section | Contenu |
|---|---|
| Commandes | Comment lancer tests, lint, build dans ce projet |
| Conventions | Nommage, structure, bibliothèques imposées ou interdites |
| Pièges | Erreurs déjà rencontrées et leur cause |
| Graphe éprouvé | Variantes du graphe qui ont bien fonctionné ici |
| Réglages | Seuils propres au projet (reprises, budget des boucles, périmètres de fichiers) |

Elle ne décrit que le projet et ne mentionne jamais l'outil qui l'a rédigée. La skill corrige les lignes devenues fausses plutôt que d'empiler, garde le fichier sous 80 lignes et promeut en règle une leçon qui revient dans plusieurs tâches. Le fichier est versionné avec votre dépôt : toute l'équipe en profite.

## Compatible avec tous les langages

Le nœud de tests détecte la stack et lance les bonnes commandes. Il lit d'abord `.graph/memoire.md`, sinon déduit des fichiers présents :

| Fichier détecté | Commandes |
|---|---|
| `pyproject.toml`, `requirements.txt` | `pytest -q`, `ruff check .`, `mypy` |
| `package.json` | scripts `test`, `lint`, `build` |
| `go.mod` | `go test ./...`, `go vet ./...` |
| `Cargo.toml` | `cargo test`, `cargo clippy` |
| `pom.xml`, `build.gradle` | `mvn test`, `gradle test` |
| `Makefile`, CI | commandes qui y figurent |

Si rien n'est détectable, la skill demande la commande une fois, puis la mémorise.

## Installation

Clonez le dépôt puis lancez le script d'installation. Il copie la skill et les quatre commandes.

Pour tous vos projets (dans `~/.claude`) :

```bash
git clone https://github.com/kofekod23/claude-code-graph-engineering.git
cd claude-code-graph-engineering
./install.sh
```

Pour un seul projet (dans le `.claude` du dossier courant, versionné avec lui) :

```bash
cd mon-projet
/chemin/vers/claude-code-graph-engineering/install.sh --projet
```

Redémarrez Claude Code (ou ouvrez une nouvelle session) pour qu'il charge les commandes. Pour mettre à jour : `git pull`, puis relancez le script.

Installation manuelle, sans script :

```bash
mkdir -p ~/.claude/skills/graph-engineering ~/.claude/commands
cp graph-engineering/SKILL.md ~/.claude/skills/graph-engineering/
cp commands/*.md ~/.claude/commands/
```

Sur claude.ai, téléversez seulement `graph-engineering/SKILL.md` dans vos skills. Les commandes `/graph...` n'y existent pas, mais un message qui commence par « graphloop » déclenche la skill.

Dans chaque projet, ajoutez `.graph/plan.md` à votre `.gitignore` (état temporaire) et versionnez `.graph/memoire.md`.

## Utilisation

| Commande | Effet |
|---|---|
| `/graphloop <tâche>` | Déroulé complet : graphe, validation si besoin, exécution, clôture |
| `/graphplan <tâche>` | Construit et montre le graphe, sans rien exécuter |
| `/graphstatus` | Affiche l'état des nœuds et des boucles (lecture seule) |
| `/graphresume [consigne]` | Reprend là où le graphe s'est arrêté |

Exemples :

```
/graphloop ajoute une pagination à l'API des commandes
/graphplan refactorise le module d'authentification et couvre-le de tests
/graphresume
```

Sans les commandes, un message qui commence par « graphloop » ou parle de « mode graphe » déclenche aussi la skill.

La skill termine par l'état final de chaque nœud, ce qui a été livré, les lignes ajoutées à la mémoire et un prochain pas utile.

## Git

- Les commits utilisent l'identité Git déjà configurée dans votre dépôt.
- Aucun push sans votre accord explicite.
- La skill suit les conventions de commit du projet, sinon des messages courts à l'impératif.
- `.graph/plan.md` est ignoré, `.graph/memoire.md` est versionné.

## Questions fréquentes

**Quelle différence avec une simple boucle ou `/goal` ?**
Une boucle seule laisse l'agent improviser l'ordre et les contrôles à chaque tour. Ici, l'ordre, le parallélisme et les contrôles sont fixés avant l'exécution, et les boucles ne servent qu'à l'intérieur des nœuds dont la réussite se vérifie par une commande, avec un budget.

**Faut-il un framework (LangGraph, etc.) ?**
Non. Les sous-agents de Claude Code jouent le rôle des nœuds, et le plan est un simple fichier Markdown.

**Est-ce utilisable hors Claude Code ?**
La skill est écrite pour Claude Code. Le principe (plan en graphe, portes, mémoire de projet) se transpose à d'autres agents de code, mais ce n'est pas l'objet de ce dépôt.

## Pour aller plus loin

Le 18 juillet 2026, Peter Steinberger, créateur d'OpenClaw, a posé cette question sur X :

> Are we still talking loops or did we shift to graphs yet?
>
> Peter Steinberger ([@steipete](https://x.com/steipete/status/2078277297791189132)), 18 juillet 2026

Elle a lancé un large débat sur les boucles et les graphes pour piloter les agents de code, même si l'expression « graph engineering » circulait déjà avant. Ce dépôt prend les deux : un graphe qui encadre des boucles bornées, sous forme de skill légère.

## Licence

MIT
