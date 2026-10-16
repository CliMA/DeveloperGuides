# Restraint

Machine-written code fails in a characteristic way: it is **correct and unreadable**. Every branch is handled, every failure anticipated, every invariant checked at three layers, and no reviewer can hold the result in their head. A reviewer facing 700 lines cannot tell which 40 are the feature.

These rules keep the diff small, the mechanisms singular, and the prose scarce. They apply to every change in a CliMA repository, whether a person or an agent wrote it, and they outrank any instinct toward completeness.

> **The test behind every rule below:** could a reviewer who knows the physics read this hunk once, in order, and say yes?

**If you carry away only four, carry these:** the diff is the feature and nothing else (§1); an invariant is enforced in one place (§2); a comment describes the code that is there (§7); search the ecosystem before you write (§13). The rest are corollaries, and the checklist at the end is how they are applied.

**They apply to existing code too.** Every rule is also a license to delete: when you are already editing a file and a rule catches something that is *already there*, removing it is in scope, not scope creep. What is out of scope is going looking. Do not open unrelated files to hunt for violations, and move a cleanup that grows past the change it started from into its own PR.

Several rules sharpen guides that already exist: comments ([code_comments.md](code_comments.md)), docstrings ([documentation_policy.md §3](documentation_policy.md)), naming ([variable_list.md](variable_list.md), [code_style.md §4](code_style.md)), regularization ([numerical_robustness.md](../performance/numerical_robustness.md)), and tests ([testing_and_validation.md](../infrastructure/testing_and_validation.md)). This guide adds the restraint those guides assume.

## 1. The feature is the diff; everything else is scope creep

Before opening a PR, ask what the smallest diff is that delivers the stated change. That diff is the PR. Anything that is not the feature (validation, fallbacks, gap fillers, helper APIs, reformatting of untouched code) is a **separate concern** and belongs in a separate PR, or nowhere.

- A generalization that **deletes** an abstraction is the best possible change. A change that ends net-negative needs no justification.
- If the feature is a net-zero change and the PR is +700, the PR is 95% scaffolding. Drop the scaffolding.
- Lines added to `src/` or `ext/` are a cost paid forever. The bar is not "is this useful?" but "is the package better off carrying this than not?"

**A PR shows only its own change.** Reviewability is a property of the diff GitHub renders, not of the commits you know are yours. Never merge another feature branch into the head of a PR. If the work depends on an unmerged branch of the same repo, base the PR on that branch so the diff shows your commits alone, keep the stack one level deep, and rebase rather than merging sideways.

❌ A five-line fix to a boundary condition, presented as +6000 / −2000 across 100 files because the PR's head merged another feature branch.

✅ Base the PR on that branch. The diff renders five lines and review takes a minute.

❌ The feature lands in the first commit; later commits add hundreds of lines of input validation nobody asked for.

✅ The PR ends with the feature. Validation, if it is genuinely needed, is proposed separately on its merits.

## 2. One invariant, one mechanism

An invariant is enforced in exactly one place. Enforcing it at construction *and* in the kernel *and* through a fallback *and* in a post-processing step does not make it four times as safe. It makes it impossible to tell which mechanism does the work, and it guarantees the four drift apart.

Before adding a check, find where the invariant is already enforced. If a runtime floor already exists, a construction-time check is redundant; if a construction-time check is added, delete the runtime floor. State in one line where the invariant lives, for example: "`q_tot ≥ 0` is enforced by the tracer limiter after each step; nothing downstream re-clips it."

❌ Non-negative moisture enforced four times: a clip inside the tendency, a limiter after the step, a `max(q, 0)` where the thermodynamic state is built, and another in the diagnostics. A bug in the limiter is hidden by the other three.

✅ One limiter, where the state is updated. Downstream code reads a state that is already valid.

## 3. No guards for states the code cannot reach

The shape to watch for: an inner function that checks for input its only caller cannot produce, or a branch that repeats a rejection the public constructor already performed. The check is technically correct, and it never runs.

This is not about regularization. Clipping a mixing ratio that advection leaves slightly negative, or flooring a denominator that vanishes in a dry column, handles a state the physics or round-off can reach, and [numerical_robustness.md](../performance/numerical_robustness.md) says how to do it. This rule is about guards against states no caller can produce. "A user might mutate this field after construction" and "a downstream package might pass the wrong type" are hypotheticals, not requirements. A guard written against one outlives the hypothetical, which usually never arrives, and because such a guard is bloat rather than a bug, nothing ever forces it out again.

A **loud failure is better than a silent fallback.** A `NaN` that reaches the prognostic state `Y` is visible in the first diagnostic output; a roughness length silently floored at `1e-5` produces plausible wrong fluxes forever.

- If a guard's docstring has to say "this is a safeguard, not a physical parameter", delete the guard.
- A keyword argument or a ClimaParams entry must express **physics or numerics**: a rate, a length, a tolerance, an iteration count, a search radius. It must not express a defense: a floor, a clamp, or a fallback whose only job is to keep malformed input away from the solver. Never grow a struct, a TOML entry, or a `show` line for one.

❌ `minimum_roughness_length`: a new keyword, struct field, ClimaParams entry, and `show` row, existing only so that a field mutated after validation cannot produce `NaN`.

✅ Validate in the constructor, or let it fail loudly. No new API.

## 4. Don't invent an API to repair damage the same PR caused

If a change makes previously valid data invalid, and the PR then ships a new exported helper to repair that data, the PR has manufactured its own problem. Fix the producer, reuse what exists, or loosen the new constraint.

❌ New validation in a constructor rejects the `NaN` cells that a spatially varying parameter map has outside the model domain, and the same PR adds an exported `fill_parameter_gaps!` with two kernels and a long docstring to undo it.

✅ Mask the map where it is read, or let the consumer ignore cells outside the domain.

## 5. Minimize the number of methods; dispatch is for polymorphism, not for `if`

**Every method is a maintenance cost.** It has to be named, found, kept consistent with its siblings, kept correct under refactoring, and understood by anyone reading any of its callers. If one method does the job, do not define two or three. Prefer widening an existing method to introducing a new one, and prefer no new name at all to a new name that only forwards.

- A method is justified by **behavior that differs by type**, such as dispatch on a `…Model` type to select a parameterization ([code_style.md §4](code_style.md)). A value that differs is an argument.
- A method whose body is a single call to another method, with arguments reordered or a default filled in, should not exist; give the callee the default instead.
- Broadcasting over a ClimaCore `Field` already applies a pointwise function everywhere. Write the pointwise function once and broadcast it, rather than adding methods for `Field`, `AbstractArray`, and scalars.
- If a helper has exactly one call site and no name a physicist would recognize, inline it.
- Count the methods a hunk adds before pushing. Nine new names for one clamp is not thoroughness.

❌ `positive_part(x::Number)`, `positive_part(f::Fields.Field)`, and `positive_part(a::AbstractArray)`: three methods for one pointwise `max`.

✅ The existing pointwise `max(zero(x), x)` (`CloudMicrophysics.Utilities.clamp_to_nonneg`), broadcast where it is used.

❌ `compute_tendency!(Yₜ, Y, p, t) = compute_tendency!(Yₜ, Y, p, t, nothing)`: a forwarding method for a default.

✅ One method, with the default on its last argument.

## 6. No table-driven generalization of a small fixed set

Four things are not a collection. Do not build a registry of `(name, value, predicate, message)` tuples and loop over it to save writing four explicit checks. The table costs more to read, hides the control flow, and its promise that "adding one is a single edit" is usually false the moment anything unpacks it positionally.

Reach for a table at roughly a dozen homogeneous entries that genuinely vary at run time, not before.

❌ A list of `(config_key, default, predicate, message)` tuples, walked by two functions to validate four keys of a YAML config and then destructured positionally.

✅ Four explicit checks, readable top to bottom.

## 7. Comments describe this code, now, and nothing else

[code_comments.md](code_comments.md) is the full guide; this section names the defects restraint is about. A comment must not:

- explain what **another** function does, or what a **caller** or a **kernel elsewhere** would do;
- justify a design decision, compare it to a rejected alternative, or narrate history;
- describe code that **is not there** ("a bare `MethodError` would be thrown on CPU", "the clamp elsewhere would hide this");
- teach the language (`==` vs `===`, how `@inbounds` works, why `Adapt` needs a field order);
- carry a multi-line design memo, or a `TODO` about a different module.

History belongs in the commit message. Design reasoning that genuinely cannot be dropped belongs in the PR description, which reviewers read once, or on a documentation page ([documentation_policy.md §2.1](documentation_policy.md)), where it is maintained as documentation.

❌ A 30-line header on a new parameterization file, comparing it with the two schemes that were considered and rejected.

✅ A few lines saying what the file computes, with a citation. The comparison goes in the PR description or on an Explanation page.

❌ A comment above a limiter explaining what "the real fix" in another module would be.

✅ `# ifelse, not ?:, so the kernel stays branch-free on the GPU`

## 8. Docstrings describe, they do not argue

A docstring says what the function does, its arguments, and its units ([documentation_policy.md §3](documentation_policy.md)). It does not defend the function's existence, quantify what would go wrong without it, or send the reader to three other functions to understand it. A back-pointer to the caller is fine ([documentation_policy.md §3.1](documentation_policy.md)); needing a cluster of `@ref`s to siblings to be understood means the abstraction is wrong.

- No "this is a backstop, not a supported regime" framing, and no bulleted rationale lists.
- No tuning advice for a parameter the same docstring calls non-physical.
- Keep the argument list; drop the essay.

❌ Eighteen lines documenting a sponge-layer keyword, of which two describe it and sixteen argue about when it matters, ending in `@ref`s to three sibling helpers.

✅ `` `τ_sponge`: relaxation timescale [s] of the sponge layer. Default: `86400`. ``

## 9. Error messages are one sentence

Name the offending object, say what was required, and stop. An error is not a tutorial: it should not explain the physics, list downstream consequences, quote numbers, or recommend a helper function. Inside GPU kernels, use a static message ([SDP 11](software_design_patterns.md)).

❌ `"surface_roughness has $(count(...)) cells that are not positive (minimum $(minimum(values))). A bad cell either propagates NaN through the similarity profiles into the prognostic state or silently zeroes every turbulent flux there. Fill the gaps first, e.g. with fill_parameter_gaps!."`

✅ `"surface_roughness must be finite and positive, found $(minimum(values))"`

## 10. Test behavior, not scaffolding

Tests pin the physics and the public contract ([testing_and_validation.md](../infrastructure/testing_and_validation.md)): limits, round trips, conservation, comparison to an analytic result. A test that asserts an internal helper's return type, a struct's field layout, or the exact value a fallback produces makes that scaffolding **permanent**: it can no longer be deleted without "breaking tests", which is precisely how machine-written scaffolding becomes permanent.

- Never write a test whose only purpose is to lock in a guard added by the same PR.
- No tautological assertions (`@test !isnothing(constructor(...))`); a constructor returning `nothing` is a bug in itself, not something to assert.
- One clear analytical check beats twenty defensive ones.

❌ Asserting the field order of a parameter struct, or that a constructor returns an object of a given type, when no caller depends on either.

✅ A round trip checked across the valid range, such as temperature → internal energy → temperature, or a conservation check that the global integral of total water changes by exactly the time-integrated surface flux.

## 11. Names come from the variable list, or they are English

No invented decorations. A superscript must mean what it means in the physics, not encode a code-level distinction like "host-side copy" or "values array". In ClimaCore-based repos `ᶜ` and `ᶠ` already mean cell center and cell face ([ecosystem_conventions.md §3](../architecture/ecosystem_conventions.md)), so a `ᶜ` for "clipped" or a `ᵛ` for "values" collides with or dilutes that notation. If a value needs that kind of qualifier, it needs a verbose English name.

Identifiers are **fully math or fully English** ([code_style.md §4](code_style.md)); reserved names are in [variable_list.md](variable_list.md).

❌ `qᵛ`, `ρᵛ`, `Tᶜ` (invented `ᵛ` = "values array", `ᶜ` = "clipped", which reads as "at cell centers")

❌ `Tmin` (math plus truncated English in one identifier), `to_FT` (an ad hoc local closure)

✅ `temperature_values`, `minimum_temperature`, `q_liq`

## 12. Examples show use, not internals

CliMA repos use plain `julia` blocks rather than `jldoctest` ([documentation_policy.md §3.11](documentation_policy.md)). An `# Examples` block shows how to construct and call the object. It does not reach into the result to prove the constructor worked.

❌ An example that builds a full simulation to show that one entry of a cached field equals zero.

✅ An example that constructs the object and calls it, or shows it with `summary`, or no example at all.

## 13. Search before you write; do not reinvent what exists

Before adding a function, search for one that already does the job: in the current repo, in its dependencies, and across the CliMA ecosystem. Reuse it, extend it, or dispatch on it. A second implementation of an existing capability is the most expensive kind of scope creep: the duplicate is correct on the day it lands and diverges from the original forever after.

Places to look first include ClimaCore (`Quadratures`, `Operators`, `Spaces`, DSS), ClimaComms (devices and contexts), ClimaUtilities (`TimeVaryingInputs`, `SpaceVaryingInputs`, regridding), ClimaParams, ClimaDiagnostics, ClimaAnalysis, the physics libraries (Thermodynamics, SurfaceFluxes, CloudMicrophysics), and RootSolvers.jl.

- If an existing function is close but not exact, **widen it**: add a method, a keyword argument, or relax a type annotation. A near-copy under a new name is never the answer.
- If you cannot find it, say where you looked. "I searched ClimaUtilities and ClimaCore for time interpolation of forcing data and found `TimeVaryingInputs`" is a reviewable claim; silence is not.
- If the existing implementation lives in a package that is not yet a dependency, adding it is a `[deps]` change that needs approval ([agent_autonomy.md](../workflow/agent_autonomy.md)). Say so, and let the author weigh the dependency against the duplicate.
- Prefer a dependency's public API. Reusing an internal function ([dependency_management.md §6](../architecture/dependency_management.md)) is a coupling to note in the PR, and a reason to propose making it public upstream.
- The same holds for patterns, not only functions: device-agnostic arrays through ClimaComms, parameters through ClimaParams, output through ClimaDiagnostics, broadcasting over `Field`s, `Adapt` rules, and `show` methods. Follow the way the codebase already does it.

❌ A model file hand-writes a bisection for a saturation adjustment, Lagrange interpolation to an off-node point, and linear time interpolation of a NetCDF forcing file.

✅ RootSolvers.jl, `ClimaCore.Quadratures.interpolation_matrix`, and `ClimaUtilities.TimeVaryingInputs`.

❌ A new saturation vapor pressure formula inside a land-surface module.

✅ `Thermodynamics.saturation_vapor_pressure`, called with the model's thermodynamics parameters ([cross_repo_contracts.md](../architecture/cross_repo_contracts.md)).

## Mandatory self-review

**Agents: run the checklist below over every change you make, before you present it.** Not at PR time, but at the end of every edit, every time. People should run it before requesting review.

1. **Read your own diff** (`git diff`, or `git diff --stat` first if it is large; see [code_comments.md §8](code_comments.md) for which diff you are reading). Review what you actually wrote, not what you remember intending. The checklist is answered from the diff, never from memory.
2. **Answer all fourteen questions.** Every **yes** is a defect you introduced. There is no "yes, but it is justified here"; that judgment is exactly the one that produced the drift.
3. **Cut before presenting.** Removing your own scaffolding is local, reversible work and needs no permission ([agent_autonomy.md](../workflow/agent_autonomy.md)). Do not ask "should I remove the validation?"; remove it, and say that you did.
4. **Report the result in one line**, for example: *"Self-review: cut the `minimum_roughness_length` guard (Q3) and two forwarding methods (Q5); 41 lines removed."* If the checklist caught nothing, say *"Self-review: clean."* Never claim clean without having read the diff.
5. **Never edit this guide to pass the checklist.** If a rule seems wrong for the case at hand, say so to the PR author and let them decide; changes to the guide go through the canonical [CliMA/DeveloperGuides](https://github.com/CliMA/DeveloperGuides) repo.

For a three-line edit this takes seconds. For a large one, it is the difference between review and no review.

## The checklist

Any **yes** means cut before presenting.

1. Is the diff more than ~2× the size of the change described in the title?
2. Is any invariant enforced in more than one place?
3. Does any new code guard against a state that no caller can produce?
4. Does the PR add an API to repair damage the PR itself caused?
5. How many methods does the diff add, and could any of them be one method, an argument, or nothing? (Three or more one-liners implementing a single `ifelse`, or a method that only forwards to another, is a yes.)
6. Is there a table, registry, or predicate list covering fewer than ~12 fixed entries?
7. Does any comment explain what another function, module, kernel, or test does, or describe code that is not there?
8. Does any docstring argue for the function's existence, or need a cluster of `@ref`s to siblings to be understood?
9. Is any error message longer than one sentence?
10. Does any test pin an internal helper, a field layout, or a fallback value?
11. Does any identifier carry an invented sub- or superscript, or mix math with English?
12. Is there a new keyword argument or ClimaParams entry that is a floor, clamp, or fallback guarding against malformed input, rather than physics or numerics?
13. Does the diff contain anything a reader would not expect from the title, including another branch merged into the head?
14. Does the diff reimplement something that already exists in the CliMA ecosystem or its dependencies, or add a new name where a new method on an existing function would do?

## Self-correction

If this guide is discovered to be stale or missing a pattern, update it.
