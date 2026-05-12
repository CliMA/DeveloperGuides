# CliMA Developer Guides — Agent Index

Read this file first. It is the master index for all shared engineering guidelines. Each guide applies across the CliMA ecosystem unless stated otherwise.

If this repo is mounted as a submodule, the consuming repo's own `AGENTS.md` should reference this file and add a pointer to the repo-specific guide.

## Architecture

1. [repo_structure.md](architecture/repo_structure.md) — how to navigate any CliMA Julia package.
2. [architectural_boundaries.md](architecture/architectural_boundaries.md) — layered architecture and boundary rules.
3. [software_design_patterns.md](architecture/software_design_patterns.md) — numbered SDPs: branchless logic, functors, parameter extraction, etc.
4. [cross_repo_contracts.md](architecture/cross_repo_contracts.md) — call-site conventions for ecosystem packages.
5. [dependency_management.md](architecture/dependency_management.md) — runtime vs dev deps, compat bounds.

## Performance

6. [gpu_performance.md](performance/gpu_performance.md) — GPU kernel rules, broadcast patterns, allocation avoidance.
7. [type_stability.md](performance/type_stability.md) — Float32 compatibility, inference checks, struct field rules.
8. [numerical_robustness.md](performance/numerical_robustness.md) — denominator regularization, clamping, NaN/Inf avoidance.
9. [ad_compatibility.md](performance/ad_compatibility.md) — AD-safe patterns for ForwardDiff and Enzyme.

## Code Quality

10. [code_style.md](code-quality/code_style.md) — formatting, variable locality, Git workflow, feature removal.
11. [docstring_standard.md](code-quality/docstring_standard.md) — docstring layout and conventions.
12. [changelog_hygiene.md](code-quality/changelog_hygiene.md) — when and how to write `NEWS.md` entries.

## Infrastructure

13. [testing_and_validation.md](infrastructure/testing_and_validation.md) — type-stability checks, Aqua.jl, allocation regression, AD tests.
14. [clima_comms.md](infrastructure/clima_comms.md) — device-agnostic and MPI-distributed code patterns.

## Workflow

15. [agent_autonomy.md](workflow/agent_autonomy.md) — actions that require explicit user approval.
16. [review.md](workflow/review.md) — PR review instructions and checklist.

## Self-correction

If this index is discovered to be stale or missing a guide, update it.
