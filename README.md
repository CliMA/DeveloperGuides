# DeveloperGuides

Shared engineering standards, architectural patterns, and development guidelines for human and AI developers across the [CliMA](https://clima.caltech.edu) ecosystem.

|                              |                                                  |
|-----------------------------:|:-------------------------------------------------|
| **License**                  | [![license][license-img]][license-url]            |

[license-img]: https://img.shields.io/github/license/CliMA/DeveloperGuides
[license-url]: https://github.com/CliMA/DeveloperGuides/blob/main/LICENSE

### Usage

DeveloperGuides is included as a **Git subtree** in CliMA repositories at the standardized path `docs/dev-guides/`. To add the subtree to a new consumer repo:

```bash
git subtree add --prefix docs/dev-guides \
    https://github.com/CliMA/DeveloperGuides.git main --squash
```

> [!NOTE]
> DeveloperGuides ships its own `AGENTS.md`, `LICENSE`, and `README.md` at the repo root.
> These will conflict with the consumer repo's own root files during `git subtree add`.
> Resolve by keeping the consumer repo's versions:
> ```bash
> git checkout --ours AGENTS.md LICENSE README.md
> git add AGENTS.md LICENSE README.md
> git rebase --continue   # or: GIT_EDITOR=true git rebase --continue
> ```

The consuming repo keeps its own `AGENTS.md` at the root, which references:

1. `docs/dev-guides/AGENTS.md` — the shared guide index
2. A repo-specific guide (e.g., `docs/clima_atmos_specific.md`)

See [`templates/`](templates/) for ready-to-copy starter files: an `AGENTS.md` skeleton, a repo-specific guide skeleton, and a GitHub Actions workflow (`update_dev_guides.yml.template`) that automates the monthly subtree sync.

### Updating

Consumer repos track `main`. To pull the latest guides manually:

```bash
git subtree pull --prefix docs/dev-guides \
    https://github.com/CliMA/DeveloperGuides.git main --squash \
    -m "chore: sync dev guides from central repo"
```

Most consumer repos automate this with a scheduled GitHub Action (`.github/workflows/update_dev_guides.yml`) that runs the subtree pull monthly and opens a PR if there are changes. See [ClimaAtmos.jl PR #4482](https://github.com/CliMA/ClimaAtmos.jl/pull/4482) for the reference setup.

### Contributing back

Edits to shared guidelines belong here, not in the vendored copy inside a consumer repo. Open PRs against `CliMA/DeveloperGuides`; once merged, the next subtree pull propagates them to every consumer.

### 🏗️ **Architecture**

- [**Repo Structure**](architecture/repo_structure.md) — how to navigate any CliMA Julia package.
- [**Ecosystem Conventions**](architecture/ecosystem_conventions.md) — module aliases, state layout (`Y`/`Yₜ`/`p`), `ᶜ`/`ᶠ` notation, CI, reproducibility, diagnostics.
- [**Architectural Boundaries**](architecture/architectural_boundaries.md) — layered architecture and boundary rules.
- [**Software Design Patterns**](architecture/software_design_patterns.md) — numbered SDPs: branchless logic, functors, parameter extraction, etc.
- [**Cross-Repo Contracts**](architecture/cross_repo_contracts.md) — call-site conventions for ecosystem packages.
- [**Dependency Management**](architecture/dependency_management.md) — runtime vs dev deps, compat bounds.

### ⚡ **Performance**

- [**GPU Performance**](performance/gpu_performance.md) — GPU kernel rules, broadcast patterns, allocation avoidance.
- [**Type Stability**](performance/type_stability.md) — Float32 compatibility, inference checks, struct field rules.
- [**Numerical Robustness**](performance/numerical_robustness.md) — denominator regularization, clamping, NaN/Inf avoidance.
- [**AD Compatibility**](performance/ad_compatibility.md) — AD-safe patterns for ForwardDiff and Enzyme.
- [**Allocation Debugging**](performance/allocation_debugging.md) — locating heap allocations with `Profile.Allocs`, JET, flame graphs.

### 🔧 **Code Quality**

- [**Code Style**](code-quality/code_style.md) — formatting, variable locality, Git workflow, feature removal, naming conventions.
- [**Documentation Policy**](code-quality/documentation_policy.md) — docstrings, repository-level docs, minimally viable documentation.
- [**Changelogs and Versioning**](code-quality/changelogs_and_versions.md) — `NEWS.md` format, SemVer rules, and the release/tagging flow.
- [**Variable List**](code-quality/variable_list.md) — standardized CliMA variable naming conventions.

### 🧪 **Infrastructure**

- [**Testing and Validation**](infrastructure/testing_and_validation.md) — type-stability checks, Aqua.jl, allocation regression, AD tests.
- [**ClimaComms**](infrastructure/clima_comms.md) — device-agnostic and MPI-distributed code patterns.

### 🤝 **Workflow**

- [**Onboarding**](workflow/onboarding.md) — install Julia, clone a CliMA repo, set up Revise/Infiltrator/JuliaFormatter, first PR loop.
- [**Agent Autonomy**](workflow/agent_autonomy.md) — actions that require explicit user approval.
- [**Debugging**](workflow/debugging.md) — interactive recipes for numerical instabilities, dispatch surprises, and `Field` plotting.
- [**PR Review**](workflow/review.md) — review instructions and checklist.
- [**CI Triage**](workflow/ci_triage.md) — checklist for "passes locally, fails on CI" failure modes.

## Directory Structure

```
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
