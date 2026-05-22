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
DIR=$(mktemp -d) && \
  git clone --depth 1 https://github.com/CliMA/DeveloperGuides "$DIR" && \
  julia "$DIR/sync/sync.jl" --target . ; \
  rm -rf "$DIR"
```

That single command:
- mirrors the shared guides into `docs/dev-guides/` and writes the enforced config files,
- scaffolds a root `AGENTS.md` and a monthly **`.github/workflows/sync_dev_guides.yml`** workflow (only if they don't already exist),

so after you commit the result the repo stays up to date automatically — the scheduled workflow re-runs the sync and opens a PR whenever central changes. To preview without writing anything, append `--check` (exits non-zero if the repo is out of sync):

```bash
DIR=$(mktemp -d) && git clone --depth 1 https://github.com/CliMA/DeveloperGuides "$DIR" && \
  julia "$DIR/sync/sync.jl" --target . --check ; rm -rf "$DIR"
```

### Enforced vs. owned files

- **Enforced** (overwritten on every sync — edit them *here*, not in the consumer): everything under `docs/dev-guides/`, `.pre-commit-config.yaml`, `.JuliaFormatter.toml`, `.dev/format/Project.toml`, `.github/workflows/julia_formatter.yml`.
- **Scaffolded once** (created if missing, then owned by the consumer — never overwritten): root `AGENTS.md`, `docs/repo_specific_guide.md`, `.github/workflows/sync_dev_guides.yml`.
- **Preserved inside the mirror** (consumer-owned escape hatch): files matching `*.local.md` or anything under a `local/` directory within `docs/dev-guides/` are never overwritten or pruned. Use these for repo-specific extensions to a shared guide (e.g. `docs/dev-guides/code-quality/code_style.local.md`) so your edits survive every sync. Editing an enforced shared guide directly will be reverted on the next sync.

Every synced file says so in its header (config files carry a "SYNCED — DO NOT EDIT" banner; the mirror gets a generated `docs/dev-guides/README.md` notice), each linking back here.

### Merging repos (e.g. CloudMicrophysics → ClimaAtmos)

The sync is designed so consolidating two subscribers is painless:

- **Enforced config is byte-identical across all subscribers**, so the merged repo has no conflicts in `.pre-commit-config.yaml`, `.JuliaFormatter.toml`, `.dev/format/`, or `julia_formatter.yml` — they're the same central copy.
- **Keep each package's repo-specific content in distinct files.** Give the absorbed package its own guide (`docs/cloudmicrophysics_specific.md`) and link both from the root `AGENTS.md`. For local guide extensions, use package-scoped names like `code_style.cloudmicrophysics.local.md` (still matched by the `*.local.md` preserve rule).
- **Opt out of resurrecting stubs.** If the merged repo deletes the generic `docs/repo_specific_guide.md`, add a consumer-owned `.devguides.toml` at the repo root so the sync doesn't recreate it:

  ```toml
  # .devguides.toml — consumer-owned; never synced.
  skip_scaffold = ["docs/repo_specific_guide.md"]  # don't recreate these stubs
  preserve = ["*.cloudmicrophysics.local.md"]      # extra mirror preserve globs (additive)
  ```

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
