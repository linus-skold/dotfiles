# Working rules

## Agents and workflow
- Entry point: `orchestrator` (`claude --agent orchestrator`). It plans, delegates, logs to `tt`, and coordinates verification. It does not edit code.
- Agents: `explorer` is read-only; `implementer` edits and commits only on its assigned branch/worktree; `reviewer` reviews read-only; `test-runner` runs tests. The orchestrator starts `reviewer` and `test-runner` in the review chain, not only through hooks. Workers do not write to `tt`.
- Use the lightest workflow that meets the task's risk and complexity. Do not delegate or create a worktree merely to follow a ritual.
- Use `herdr worktree create` when `herdr` is installed and isolation is useful. Otherwise use Claude's worktree isolation for isolated implementation. Edit in place only when the brief explicitly permits it and the change is low-risk.
- Never force-push, push to `main`/`master`, or run destructive Git/database commands without explicit user confirmation.
- Never commit without explicit user approval, except an implementer may commit on its assigned worktree branch. The orchestrator pushes a finished worktree branch and opens a PR without asking.

## Task selection
- Answer questions directly when the answer is clear from available context. Use `explorer` only when codebase investigation is needed and the relevant files or behavior are not already clear.
- For small, well-specified changes, use one implementer and skip separate exploration and review unless risk warrants them.
- For unfamiliar, multi-file, ambiguous, or high-risk changes, investigate first, define observable acceptance criteria, implement, then verify.
- Prefer the smallest change that meets the request. Do not refactor unrelated code.
- State material assumptions before editing. Ask one focused clarifying question when ambiguity could change the implementation. Workers use `subagent-protocol` with status `blocked`.

## Context and output
- Keep briefs and reports concise. Include only relevant paths, constraints, acceptance criteria, and decisions.
- Read narrowly with `rg`, `git`, and line ranges. Avoid dumping large files or full successful command logs.
- Report verified facts separately from assumptions and unresolved items.
- Verify with the narrowest relevant check. State the command and result; never claim a check passed if it was not run.
- Give the result first. Keep routine communication concise. All agents write prose in ASD-STE100 and load `ste-writing`. Do not change code, paths, commands, command output or quoted text.

## Skills and tools
- `tt-time-logging` (`~/.claude/skills/tt-time-logging/SKILL.md`): follow the full contract when logging time. The hook may inject a short operating card; avoid repeating the full contract in every prompt. Use `/tt-time-logging` when the full contract is needed. The orchestrator logs its own time, also when it starts no workers (analysis and conversation count).
- `graphify` (`~/.claude/skills/graphify/SKILL.md`): when the user types `/graphify`, load and follow the skill before doing anything else.
- For codebase questions, if `graphify-out/graph.json` exists, run `graphify query "<question>"` first. Use `graphify path "<A>" "<B>"` or `graphify explain "<concept>"` for focused relationships. If `graphify-out/wiki/index.md` exists, use it for broad navigation. Read `GRAPH_REPORT.md` only when broad architecture context is needed or focused queries are insufficient.
- After changes are merged into the main repo, run `graphify update .` there if `graphify-out/` exists. Do not run it in a worktree.
- Prefer `bat --color=always --style=numbers --paging=never <file>` for displaying file contents; use `--line-range=N:M` for partial reads. Use `cat` when piping content into other tools.

## Git and delivery
- Use conventional commits for worker commits. Do not add co-author trailers.
- Workers must not commit to, merge into, or push another branch.
- The orchestrator always pushes a finished worktree branch to a new remote branch and opens a PR, without asking. Never force-push. Never push to `main`/`master`.
- The user merges the PR on GitHub. After the user confirms merge, update Graphify in the main repo if applicable and remove the completed worktree.
