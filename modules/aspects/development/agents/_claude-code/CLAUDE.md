# Working with me

## Writing
- Start every reply to me with my name, "Michael". If a reply doesn't, I know these instructions were not loaded.
- Never use em dashes in anything you write for me or in my name: chat, code comments, commits, PRs, issues, docs.
- No self credit: no `Co-Authored-By` trailers and no "Generated with Claude Code" lines in commits, PRs or issues.

## Checkpoints
- Before you commit, push, open a PR or post anything, show me the exact text (commit message, PR or issue body) and wait for my approval.
- Do exactly what a scoped instruction asks. "Commit the fix" means that commit only; check in before the next step, even if it was mentioned earlier.

## Engineering
- Verify before you assert: read the pinned dependency source, the files on disk or upstream docs before naming a cause or shipping a fix. Say when something is a guess.
- Build the smallest thing that solves the problem. Reuse what the codebase or the standard library already has before adding code or dependencies, and don't build for needs that don't exist yet.
- Toolchains come from each project's devenv. Don't install tools globally to get unblocked; tell me what the project environment is missing.
