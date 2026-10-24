# claude-code-graph-engineering: graph engineering and agent loops for Claude Code

🇫🇷 [Lire en français](README.md) | 🇬🇧 English

**A Claude Code skill that turns a development task into a control graph: parallel subagents, validation gates, bounded loops that iterate until a checkable goal is met, and a project memory that adapts itself over time.**

Key strength: **self-adaptation**. On every run, the skill learns your repository's commands, conventions and pitfalls, then reuses them to build a better graph next time.

> Community project, not affiliated with Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic, mentioned here to describe compatibility.

---

## What it is for

With Claude Code, you often prompt the agent step by step, inside a single loop. On a long task (new feature, refactor, bug fix) this is fragile: the context keeps growing, steps get forgotten, and the agent that wrote the code also checks it.

**Graph engineering** replaces that loop with a plan defined upfront:

- each **node** is a unit of work (often a subagent),
- each **edge** is a dependency or a condition to move on,
- each **gate** can block what comes next (failing tests, negative review).

The result is a repeatable, parallelized process, verified by an agent that did not write the code.

## What the skill does

1. **Maps before acting**: writes the graph in `.graph/plan.md` (nodes, dependencies, parallelism, gates) and asks for your approval when the task is costly.
2. **Runs in parallel** every node whose dependencies are satisfied.
3. **Checks with blocking gates**: tests, lint, then an independent review of the diff against the spec.
4. **Retries on failure** with the failure reason, capped at 3 passes before handing control back to you.
5. **Extends the graph on the fly** when a step reveals unexpected work (dynamic graph). Past 2 added nodes, or outside the planned scope, it asks for your approval again.
6. **Loops on mechanical nodes** (make tests pass, fix lint, get under a performance threshold), with a check command and a turn budget.
7. **Learns from the project** and stores its lessons in `.graph/memoire.md`.

Typical graph:

```
[explore] -> [plan] -> [implement] -> [tests] -> [review] -> [ship]
                           ^             |          |
                           +--- fail ----+          |
                           +------ fixes -----------+
```

## Graph of loops: the graph governs, the loop iterates

A graph node is either a `task` (a single pass) or a `loop`. A loop runs until a command confirms the result, for example `pytest -q` with no failures. It declares its goal, its check command, its turn budget (5 by default) and the measure that shows progress.

It stops when the goal is met, when the budget runs out, or after 2 turns without progress. The agent working inside the loop may not edit the tests or thresholds to pass: if one of them looks wrong, it exits and tells you. A failed loop follows the graph's failure edge, never a silent restart.

For a recurring task, the whole graph can also be rerun on a schedule with `/loop`.

## Self-adaptation: the project memory

The `.graph/memoire.md` file is read at startup and enriched at the end of each run (3 to 5 lines at most, verified lessons only).

| Section | Content |
|---|---|
| Commands | How to run tests, lint and build in this project |
| Conventions | Naming, structure, required or forbidden libraries |
| Pitfalls | Errors already met and their cause |
| Proven graph | Graph variants that worked well here |
| Settings | Project-specific thresholds (retries, loop budget, overlapping file scopes) |

It only describes the project and never mentions the tool that wrote it. The skill fixes lines that became wrong instead of piling up new ones, keeps the file under 80 lines, and promotes a lesson to a rule when it comes back across several tasks. The file is versioned with your repository, so the whole team benefits.

## Works with any language

The test node detects your stack and runs the right commands. It reads `.graph/memoire.md` first, otherwise it infers from the files present:

| Detected file | Commands |
|---|---|
| `pyproject.toml`, `requirements.txt` | `pytest -q`, `ruff check .`, `mypy` |
| `package.json` | `test`, `lint`, `build` scripts |
| `go.mod` | `go test ./...`, `go vet ./...` |
| `Cargo.toml` | `cargo test`, `cargo clippy` |
| `pom.xml`, `build.gradle` | `mvn test`, `gradle test` |
| `Makefile`, CI | commands found there |

If nothing can be detected, the skill asks for the command once, then remembers it.

## Installation

Clone the repository and run the install script. It copies the skill and the four commands.

For all your projects (into `~/.claude`):

```bash
git clone https://github.com/kofekod23/claude-code-graph-engineering.git
cd claude-code-graph-engineering
./install.sh
```

For a single project (into the current folder's `.claude`, versioned with it):

```bash
cd my-project
/path/to/claude-code-graph-engineering/install.sh --projet
```

Restart Claude Code (or open a new session) so it loads the commands. To update: `git pull`, then run the script again.

Manual install, without the script:

```bash
mkdir -p ~/.claude/skills/graph-engineering ~/.claude/commands
cp graph-engineering/SKILL.md ~/.claude/skills/graph-engineering/
cp commands/*.md ~/.claude/commands/
```

On claude.ai, upload only `graph-engineering/SKILL.md` to your skills. The `/graph...` commands do not exist there, but a message starting with "graphloop" triggers the skill.

In each project, add `.graph/plan.md` to your `.gitignore` (temporary state) and commit `.graph/memoire.md`.

## Usage

| Command | Effect |
|---|---|
| `/graphloop <task>` | Full run: graph, approval if needed, execution, wrap-up |
| `/graphplan <task>` | Builds and shows the graph without running anything |
| `/graphstatus` | Shows the state of nodes and loops (read only) |
| `/graphresume [instruction]` | Resumes where the graph stopped |

Examples:

```
/graphloop add pagination to the orders API
/graphplan refactor the authentication module and cover it with tests
/graphresume
```

Without the commands, a message starting with "graphloop" or mentioning "graph mode" also triggers the skill.

The skill ends with the final state of each node, what was delivered, the lines added to memory, and one useful next step.

## Git

- Commits use the Git identity already configured in your repository.
- No push without your explicit approval.
- The skill follows the project's commit conventions, otherwise short messages in the imperative mood.
- `.graph/plan.md` is ignored, `.graph/memoire.md` is versioned.

## FAQ

**How is this different from a plain loop or `/goal`?**
A loop on its own lets the agent improvise order and checks at each turn. Here, order, parallelism and checks are fixed before execution, and loops only run inside nodes whose success a command can check, within a budget.

**Do I need a framework (LangGraph, etc.)?**
No. Claude Code subagents act as nodes, and the plan is a simple Markdown file.

**Can I use it outside Claude Code?**
The skill is written for Claude Code. The principle (graph plan, gates, project memory) carries over to other coding agents, but that is not the goal of this repository.

## Going further

On July 18, 2026, Peter Steinberger, creator of OpenClaw, asked this on X:

> Are we still talking loops or did we shift to graphs yet?
>
> Peter Steinberger ([@steipete](https://x.com/steipete/status/2078277297791189132)), July 18, 2026

The question started a wide debate about loops and graphs for driving coding agents, although the term "graph engineering" was already in use before. This repository takes both: a graph that governs bounded loops, packaged as a lightweight skill.

## License

MIT
