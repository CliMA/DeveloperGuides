# Architectural Boundaries

This guide defines the layered architecture used across CliMA model repositories and the rules that keep boundaries clean. Each repo's `*_specific.md` (linked from [AGENTS.md](../AGENTS.md)) maps these layers to its concrete directories.

## 1. Core Computation vs. Orchestration

CliMA packages enforce a strict boundary between stateless mathematical/physical logic and stateful orchestration.

```
┌─────────────────────────────────────────────────────┐
│  Stateless Core                                     │
│  Pure functions, mathematical laws, algorithms.     │
│  (e.g., phase equilibrium, RK stage updates)        │
└────────────────────┬────────────────────────────────┘
                     │ results (scalars / NamedTuples)
┌────────────────────▼────────────────────────────────┐
│  Orchestration / Infrastructure                     │
│  State arrays, caching, broadcasting, and IO.       │
│  (e.g., ClimaCore.Fields, memory allocation)        │
└─────────────────────────────────────────────────────┘
```

**Rule**: The stateless core should only operate on primitive types, tuples, and parameter containers. It must **never** know about the simulation's spatial grid, field types (like `ClimaCore.Field`), or parallelization strategy. If a file defines a mathematical or physical relationship, it must not contain memory allocation or broadcasting logic. All array broadcasting and state management belong in the orchestration layer.

## 2. Parameter container design

- Containers should be focused on the specific physical or mathematical domain they serve.
- Do not add "zombie" forward-compatibility fields to support not-yet-refactored callers; refactor the callers instead.
- Exclude diagnostic or calibration parameters from physics containers; pass them explicitly from the infrastructure layer.

## 3. Avoid hidden field dependencies

Do not access internal or undocumented fields of a sub-package's parameter struct directly (for example, `cm2p.internal_field`). Use the documented public accessor or the primary parameter source.

This makes physics refactors in sub-packages safe without cascading breakage in the model.

Bad:

```julia
# Brittle: depends on internal field names of a microphysics struct
w_sed = cm2p.rtv + cm2p.ctv
```

Preferred:

```julia
# Robust: access from the primary, stable parameter source
w_sed = cmc.Ch2022.rain + cmc.stokes.liquid
```

## 4. Module import rules

Inside `src/`, do not add local `using` or `import` patterns between submodules. See [SDP 2](software_design_patterns.md). Prefer explicit qualification or project-established module patterns.

## Self-correction

If this guide is discovered to be stale or missing a pattern, update it.
