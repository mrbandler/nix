---
name: docs-lookup
description: Look up current documentation for a library, framework, SDK or CLI before using or explaining its API. Use when code depends on a third-party package's API, when a version may have changed behavior, or when the user asks how a library works.
---

# Docs lookup

Training data lags releases. Read current docs before you name an API, flag or option.

## Steps

1. Resolve the library ID:
   ```bash
   ctx7 library <name> "<what you need>"
   ```
   Pick the result with the best match on title, reputation and version. A redirect notice gives the new ID; use that.
2. Query one topic per call:
   ```bash
   ctx7 docs <libraryId> "<single topic>"
   ```
   Run a separate query for each distinct concept.
3. Match the version. Read the version the project pins (lock file, `Cargo.toml`, `package.json`, flake input) and prefer docs for that version.
4. If ctx7 has no match, or the result is thin or outdated, fetch the official docs or the pinned source with WebFetch instead.

## Rules

- Cite the library ID or URL for each fact you take from the docs.
- No login is needed. A rate-limit error means: wait, or fall back to step 4.
