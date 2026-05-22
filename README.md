# DeveloperGuides

Shared engineering standards, architectural patterns, and development guidelines for human and AI developers across the [CliMA](https://clima.caltech.edu) ecosystem.

|             |                                        |
|------------:|:---------------------------------------|
| **License** | [![license][license-img]][license-url] |

[license-img]: https://img.shields.io/github/license/CliMA/DeveloperGuides
[license-url]: https://github.com/CliMA/DeveloperGuides/blob/main/LICENSE

## Usage

DeveloperGuides is a **central source of truth** that consumer repos pull from with one idempotent command. A small Julia tool ([`sync/sync.jl`](sync/sync.jl)) mirrors the shared markdown guides into `docs/dev-guides/` **and** enforces shared dev config that lives at scattered paths — `.pre-commit-config.yaml`, `.JuliaFormatter.toml`, the pinned `.dev/format/` formatter env, and the `julia_formatter.yml` CI check. (This replaces the old Git subtree approach, which could only manage files under a single prefix. See [`sync/README.md`](sync/README.md) for the design.)

Each consumer keeps its own root `AGENTS.md` (referencing `docs/dev-guides/AGENTS.md`) plus a repo-specific guide. See [`AGENTS.md`](AGENTS.md) for the full guide index and [`templates/`](templates/) for starter files.

### Subscribe a repo

Run this from the root of the repo you want to subscribe. It is safe to re-run — `mktemp` avoids any clone collision and the sync converges, so a second run reports no changes:

```bash
(DIR=$(mktemp -d); trap 'rm -rf "$DIR"' EXIT
 git clone --depth 1 https://github.com/CliMA/DeveloperGuides "$DIR" \
   && julia "$DIR/sync/sync.jl" --target .)
```

The subshell + `trap` cleans up the temp checkout while still letting a failure (or `--check` drift) propagate through the exit status.

That single command:
- mirrors the shared guides into `docs/dev-guides/` and writes the enforced config files,
- scaffolds a root `AGENTS.md` and a monthly **`.github/workflows/sync_dev_guides.yml`** workflow (only if they don't already exist),

so after you commit the result the repo stays up to date automatically — the scheduled workflow re-runs the sync and opens a PR whenever central changes. To preview without writing anything, append `--check` (exits non-zero if the repo is out of sync):

```bash
(DIR=$(mktemp -d); trap 'rm -rf "$DIR"' EXIT
 git clone --depth 1 https://github.com/CliMA/DeveloperGuides "$DIR" \
   && julia "$DIR/sync/sync.jl" --target . --check)
```

### Enforced vs. owned files

- **Enforced** (overwritten on every sync — edit them *here*, not in the consumer): everything under `docs/dev-guides/`, `.pre-commit-config.yaml`, `.JuliaFormatter.toml`, `.dev/format/Project.toml`, `.github/workflows/julia_formatter.yml`.
- **Scaffolded once** (created if missing, then owned by the consumer — never overwritten): root `AGENTS.md`, `docs/repo_specific_guide.md`, `.github/workflows/sync_dev_guides.yml`.
- **Preserved inside the mirror** (consumer-owned escape hatch): files matching `*.local.md` or anything under a `local/` directory within `docs/dev-guides/` are never overwritten or pruned. Use these for repo-specific extensions to a shared guide (e.g. `docs/dev-guides/code-quality/code_style.local.md`) so your edits survive every sync. Editing an enforced shared guide directly will be reverted on the next sync.

Every synced file says so in its header (config files carry a "SYNCED — DO NOT EDIT" banner; the mirror gets a generated `docs/dev-guides/README.md` notice), each linking back here.

### Consumer overrides (`.devguides.toml`)

A consumer can place a `.devguides.toml` at its repo root to adjust the sync for that repo — skip a scaffold it doesn't want recreated, or add extra `preserve` globs:

```toml
# .devguides.toml — consumer-owned; never synced.
skip_scaffold = ["docs/repo_specific_guide.md"]  # don't (re)create these stubs
preserve = ["*.notes.local.md"]                  # extra mirror preserve globs (additive)
```

(ClimaAtmos uses this to keep its existing `docs/clima_atmos_specific.md` instead of the generic stub.) This is also what keeps consolidation sane if two packages are ever merged into one repo: enforced config is byte-identical across subscribers, so it merges without conflict, and `skip_scaffold` stops orphaned stubs from reappearing.

### Contributing back

Edits to shared guidelines or enforced config belong here, not in the vendored copy inside a consumer repo (the next sync reverts local edits to enforced files). Open PRs against `CliMA/DeveloperGuides`; once merged, the next sync propagates them to every consumer.

## Directory Structure

```text
├── AGENTS.md                  # Master index for AI agents
├── architecture/              # System design, layering, contracts
├── performance/               # GPU, type stability, numerics, AD
├── code-quality/              # Style, docstrings, changelogs
├── infrastructure/            # Testing, device abstraction
├── workflow/                  # Agent autonomy, PR review
└── templates/                 # Starter files for consumer repos
```

## Integration with the CliMA Ecosystem

DeveloperGuides is the central source of truth for engineering standards across [CliMA](https://github.com/CliMA), including:

- [ClimaAtmos](https://github.com/CliMA/ClimaAtmos.jl)
- [ClimaCore](https://github.com/CliMA/ClimaCore.jl)
- [ClimaLand](https://github.com/CliMA/ClimaLand.jl)
- [ClimaOcean](https://github.com/CliMA/ClimaOcean.jl)
- [ClimaCoupler](https://github.com/CliMA/ClimaCoupler.jl)
- [Thermodynamics](https://github.com/CliMA/Thermodynamics.jl)
- [CloudMicrophysics](https://github.com/CliMA/CloudMicrophysics.jl)
- [SurfaceFluxes](https://github.com/CliMA/SurfaceFluxes.jl)
- [ClimaTimeSteppers](https://github.com/CliMA/ClimaTimeSteppers.jl)

## Contributing

- Each guide has a **Self-correction** section: if you discover a guide is stale or missing a pattern, update it directly.
- New guides should be placed in the appropriate category directory and added to [`AGENTS.md`](AGENTS.md).
- Cross-references between guides should use relative paths (e.g., `../performance/gpu_performance.md`).

## Getting Help

For questions or suggestions, open an issue on [GitHub](https://github.com/CliMA/DeveloperGuides/issues).
