# claude-code-graph-engineering

🇫🇷 Français | 🇬🇧 [Read in English](README.en.md)

**Skill Claude Code qui transforme une tâche de développement en graphe de contrôle : sous-agents en parallèle, portes de validation, et une mémoire qui s'adapte à chaque projet.**

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
5. **Étend le graphe en cours de route** si une étape révèle du travail imprévu (graphe dynamique).
6. **Apprend du projet** et enregistre ses enseignements dans `.graph/memoire.md`.

Graphe type :

```
[explore] -> [plan] -> [implémenter] -> [tests] -> [revue] -> [livrer]
                           ^               |          |
                           +---- échec ----+          |
                           +------ corrections -------+
```

## Auto-adaptation : la mémoire de projet

Le fichier `.graph/memoire.md` est lu au démarrage et enrichi à la clôture (3 à 5 lignes au maximum, uniquement des enseignements vérifiés).

| Section | Contenu |
|---|---|
| Commandes | Comment lancer tests, lint, build dans ce projet |
| Conventions | Nommage, structure, bibliothèques imposées ou interdites |
| Pièges | Erreurs déjà rencontrées et leur cause |
| Graphe éprouvé | Variantes du graphe qui ont bien fonctionné ici |
| Réglages | Seuils propres au projet (reprises, périmètres de fichiers) |

La skill corrige les lignes devenues fausses plutôt que d'empiler, garde le fichier sous 80 lignes et promeut en règle une leçon qui revient dans plusieurs tâches. Le fichier est versionné avec votre dépôt : toute l'équipe en profite.

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

Installation globale (tous vos projets) :

```bash
git clone https://github.com/kofekod23/claude-code-graph-engineering.git
mkdir -p ~/.claude/skills/graph-engineering
cp claude-code-graph-engineering/graph-engineering/SKILL.md ~/.claude/skills/graph-engineering/
```

Installation par projet (versionnée dans le dépôt) :

```bash
mkdir -p .claude/skills/graph-engineering
cp claude-code-graph-engineering/graph-engineering/SKILL.md .claude/skills/graph-engineering/
```

Ajoutez `.graph/plan.md` à votre `.gitignore` (état temporaire) et versionnez `.graph/memoire.md`.

## Utilisation

Dans Claude Code :

```
/graph-engineering ajoute une pagination à l'API des commandes
```

ou en langage naturel :

```
Mode graphe : refactorise le module d'authentification et couvre-le de tests
```

La skill propose le graphe, attend votre validation si nécessaire, puis exécute et termine par : l'état final de chaque nœud, ce qui a été livré, les lignes ajoutées à la mémoire, et un prochain pas utile.

## Git

- Les commits utilisent l'identité Git déjà configurée dans votre dépôt.
- La skill suit les conventions de commit du projet, sinon des messages courts à l'impératif.
- `.graph/plan.md` est ignoré, `.graph/memoire.md` est versionné.

## Questions fréquentes

**Quelle différence avec une simple boucle ou `/goal` ?**
Une boucle retarde les décisions et laisse l'agent improviser à chaque tour. Un graphe les prend à l'avance : l'ordre, le parallélisme et les contrôles sont fixés avant l'exécution.

**Faut-il un framework (LangGraph, etc.) ?**
Non. Les sous-agents de Claude Code jouent le rôle des nœuds, et le plan est un simple fichier Markdown.

**Est-ce utilisable hors Claude Code ?**
La skill est écrite pour Claude Code. Le principe (plan en graphe, portes, mémoire de projet) se transpose à d'autres agents de code, mais ce n'est pas l'objet de ce dépôt.

## Pour aller plus loin

Le 18 juillet 2026, Peter Steinberger, créateur d'OpenClaw, a posé cette question sur X :

> Are we still talking loops or did we shift to graphs yet?
>
> Peter Steinberger ([@steipete](https://x.com/steipete/status/2078277297791189132)), 18 juillet 2026

Elle a lancé un large débat sur les boucles et les graphes pour piloter les agents de code, même si l'expression « graph engineering » circulait déjà avant. Ce dépôt en propose une implémentation légère sous forme de skill.

## Licence

MIT
