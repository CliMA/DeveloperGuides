# DeveloperGuides

Shared engineering standards, architectural patterns, and development guidelines for human and AI developers across the CliMA ecosystem.

## Directory structure

```
├── AGENTS.md                  # Master index for AI agents
├── architecture/              # System design, layering, contracts
├── performance/               # GPU, type stability, numerics, AD
├── code-quality/              # Style, docstrings, changelogs
├── infrastructure/            # Testing, device abstraction
├── workflow/                  # Agent autonomy, PR review
└── templates/                 # Starter files for consumer repos
```

## Usage as a submodule

All CliMA repos should mount this repository at the standardized path `docs/dev-guides/`:

```bash
git submodule add https://github.com/CliMA/DeveloperGuides.git docs/dev-guides
```

The consuming repo keeps its own `AGENTS.md` at the root, which references:
1. `docs/dev-guides/AGENTS.md` — the shared guide index
2. A repo-specific guide (e.g., `docs/agents/clima_atmos_specific.md`)

See [`templates/`](templates/) for starter files.

### Updating the submodule

Consumer repos track `main`. To pull the latest guides:

```bash
git submodule update --remote docs/dev-guides
git add docs/dev-guides
git commit -m "chore: update DeveloperGuides submodule"
```

## Contributing

- Each guide has a **Self-correction** section: if you discover a guide is stale or missing a pattern, update it directly.
- New guides should be placed in the appropriate category directory and added to `AGENTS.md`.
- Cross-references between guides should use relative paths (e.g., `../performance/gpu_performance.md`).
