# Sync system

This directory makes DeveloperGuides a **central source of truth** that consumer
repos pull from with one idempotent command. It replaces the old `git subtree`
mechanism, which could only place files under a single prefix and so could not
manage scattered config like `.pre-commit-config.yaml` or CI workflows.

## How it works

[`sync.jl`](sync.jl) reads [`manifest.toml`](manifest.toml) and copies files into
a consumer repo under one of three policies:

| Policy        | Behavior                                                        | Examples |
|:--------------|:----------------------------------------------------------------|:---------|
| `[guides]`    | Mirror the shared markdown into `docs/dev-guides/`, **deleting** stale files there — except `preserve` matches. | `architecture/`, `code-quality/`, … |
| `[[enforce]]` | **Overwrite** the file verbatim on every sync.                  | `.pre-commit-config.yaml`, `.JuliaFormatter.toml`, `.dev/format/Project.toml`, `.github/workflows/julia_formatter.yml` |
| `[[scaffold]]`| **Create only if missing**; the consumer owns it afterward.     | root `AGENTS.md`, `docs/repo_specific_guide.md`, `.github/workflows/sync_dev_guides.yml` |

### Preserving repo-specific edits

Enforced files and the mirror are central's to control — editing them in a
consumer is reverted on the next sync. Subscribers keep repo-specific content in
files the sync never touches:

- **Owned files** (`[[scaffold]]`): root `AGENTS.md` and `docs/repo_specific_guide.md`
  are created once and never overwritten.
- **Preserve patterns** inside the mirror (`[guides].preserve`): files matching
  `*.local.md` or anything under a `local/` directory in `docs/dev-guides/` are
  never overwritten or pruned. Use them to extend a shared guide in place, e.g.
  `docs/dev-guides/code-quality/code_style.local.md`.

Every synced file carries a back-link to this repo: config files have a
"SYNCED — DO NOT EDIT" banner, and the mirror gets a generated
`docs/dev-guides/README.md` (the `[guides].notice` entry) explaining the rules.

### Consumer overrides (`.devguides.toml`)

A consumer may place a `.devguides.toml` at its repo root to adjust the sync.
It is consumer-owned and never synced:

```toml
skip_scaffold = ["docs/repo_specific_guide.md"]  # don't recreate these stubs
preserve = ["*.cloudmicrophysics.local.md"]      # extra mirror preserve globs (additive)
```

This exists mainly to keep **merged/monorepos** sane. Because enforced config is
byte-identical across subscribers, merging two of them produces no conflicts in
those files; the only care needed is around owned content (use distinct,
package-scoped filenames) and avoiding resurrected scaffold stubs (`skip_scaffold`).

The canonical content for enforced config lives in [`managed/`](managed/). Edit
it here — never in a consumer repo, where the next sync would revert it.

Idempotency is by construction: enforced files converge to the source, scaffolds
no-op once present, and the mirror deletes extras, so a second run with the same
source produces zero changes (and `--check` exits 0).

## Running it

```bash
# Apply the sync to the repo in the current directory.
julia /path/to/DeveloperGuides/sync/sync.jl --target .

# Report drift without writing anything (exit 1 if out of sync). Good for CI.
julia /path/to/DeveloperGuides/sync/sync.jl --target . --check
```

A consumer doesn't keep a checkout of DeveloperGuides around: the scheduled
[`sync_dev_guides.yml`](../templates/sync_dev_guides.yml.template) workflow checks
it out on the fly, runs `sync.jl`, and opens a PR only when files changed.

## Changing what is managed

- **Tweak enforced config** (formatter rules, hook set): edit the file under
  [`managed/`](managed/).
- **Promote a new file to enforced/scaffold status**: add it under `managed/` (or
  `templates/` for scaffolds) and add an entry to [`manifest.toml`](manifest.toml).
- **Add or remove a shared guide**: just add/remove the markdown in the category
  directories; the mirror picks it up and deletes removed files in consumers.
