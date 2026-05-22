#!/usr/bin/env julia
#
# sync.jl — idempotently sync CliMA shared guides + dev config into a consumer
# repo. Stdlib only (no Pkg deps); runs on any Julia >= 1.6.
#
# Usage (run from anywhere; the script's own location is the source of truth):
#
#   julia /path/to/DeveloperGuides/sync/sync.jl [--target DIR] [--check] [--quiet]
#
#   --target DIR   Consumer repo root to sync into (default: current directory).
#   --check        Report drift without writing anything; exit 1 if the target
#                  is out of sync, 0 if already in sync. Useful in CI.
#   --quiet        Suppress the per-file log; only print the summary.
#
# What it does, driven by sync/manifest.toml:
#   * [guides]    mirrors the shared markdown guides into docs/dev-guides,
#                 deleting any stale files there.
#   * [[enforce]] overwrites each listed file verbatim (centrally enforced).
#   * [[scaffold]] creates each listed file only if it is missing.
#
# Idempotent by construction: enforced files converge to the source, scaffolds
# no-op once present, and the mirror deletes extras — so a second run with the
# same source produces zero changes.

module DevGuidesSync

import TOML

const SYNC_DIR = @__DIR__
const SOURCE_ROOT = normpath(joinpath(SYNC_DIR, ".."))
const REPO_URL = "https://github.com/CliMA/DeveloperGuides"

# Banner written to the root of the guides mirror so anyone browsing the synced
# files knows they are generated and where to edit instead.
notice_text() = """
<!-- AUTO-SYNCED FROM CliMA/DeveloperGuides — DO NOT EDIT BY HAND -->

# Shared developer guides (synced)

Every file in this directory is mirrored verbatim from
[CliMA/DeveloperGuides]($REPO_URL) by the `sync_dev_guides.yml` workflow.
**Edits made here are overwritten on the next sync.**

- To change a shared guide, open a PR against [CliMA/DeveloperGuides]($REPO_URL).
- To add repo-specific notes that *survive* syncing, create a `*.local.md` file
  or a `local/` subdirectory here (e.g. `code-quality/code_style.local.md`).
  Those are never overwritten or deleted.

Content this repository owns lives in the root `AGENTS.md` and
`docs/repo_specific_guide.md`.
"""

struct Action
    kind::Symbol   # :create | :update | :delete | :unchanged | :skip
    dst::String    # path relative to the target root, for reporting
end

changed(a::Action) = a.kind in (:create, :update, :delete)

function parse_args(argv)
    target = "."
    check = false
    quiet = false
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--target"
            i += 1
            i <= length(argv) || error("--target requires a value")
            target = argv[i]
        elseif startswith(a, "--target=")
            target = split(a, "="; limit = 2)[2]
        elseif a == "--check"
            check = true
        elseif a == "--quiet"
            quiet = true
        elseif a in ("-h", "--help")
            println(read(@__FILE__, String) |> _help_text)
            exit(0)
        else
            error("Unknown argument: $a (try --help)")
        end
        i += 1
    end
    return (; target = abspath(expanduser(target)), check, quiet)
end

# Extract the leading comment block as help text.
function _help_text(src)
    lines = String[]
    for line in split(src, '\n')
        startswith(line, "#") || (isempty(strip(line)) ? continue : break)
        push!(lines, replace(line, r"^# ?" => ""))
    end
    return join(lines, '\n')
end

# Copy src_abs -> dst_abs. `overwrite=false` means scaffold (create if absent).
# Returns an Action; only writes when `apply` is true and content differs.
function copy_file(src_abs, dst_abs, rel; apply, overwrite)
    content = read(src_abs)
    if isfile(dst_abs)
        if !overwrite
            return Action(:skip, rel)              # scaffold: already present
        end
        read(dst_abs) == content && return Action(:unchanged, rel)
        if apply
            mkpath(dirname(dst_abs))
            write(dst_abs, content)
        end
        return Action(:update, rel)
    else
        if apply
            mkpath(dirname(dst_abs))
            write(dst_abs, content)
        end
        return Action(:create, rel)
    end
end

# Write generated (in-memory) content to dst_abs, overwriting if it differs.
function write_generated(content, dst_abs, rel; apply)
    bytes = codeunits(content)
    if isfile(dst_abs) && read(dst_abs) == bytes
        return Action(:unchanged, rel)
    end
    kind = isfile(dst_abs) ? :update : :create
    if apply
        mkpath(dirname(dst_abs))
        write(dst_abs, content)
    end
    return Action(kind, rel)
end

# Mirror the shared guides into target/<dst>, deleting any file there that the
# source no longer provides.
function sync_guides(spec, target, extra_preserve; apply)
    actions = Action[]
    dst_root = joinpath(target, spec["dst"])
    owned = Set{String}()  # paths relative to dst_root that the source provides

    function take(src_abs, rel_under_dst)
        push!(owned, normpath(rel_under_dst))
        push!(
            actions,
            copy_file(
                src_abs,
                joinpath(dst_root, rel_under_dst),
                joinpath(spec["dst"], rel_under_dst);
                apply,
                overwrite = true,
            ),
        )
    end

    for dir in get(spec, "dirs", String[])
        src_dir = joinpath(SOURCE_ROOT, dir)
        isdir(src_dir) || error("guides dir not found in source: $dir")
        for (root, _, files) in walkdir(src_dir), fn in files
            src_abs = joinpath(root, fn)
            take(src_abs, relpath(src_abs, SOURCE_ROOT))
        end
    end
    for f in get(spec, "files", String[])
        src_abs = joinpath(SOURCE_ROOT, f)
        isfile(src_abs) || error("guides file not found in source: $f")
        take(src_abs, f)
    end

    # Generated "do not edit" banner at the mirror root (owned, so never pruned;
    # overwritten each sync so the link/instructions stay current).
    if haskey(spec, "notice")
        push!(owned, normpath(spec["notice"]))
        push!(actions, write_generated(
            notice_text(), joinpath(dst_root, spec["notice"]),
            joinpath(spec["dst"], spec["notice"]); apply))
    end

    # Delete extras under dst_root (collect first, then remove), but never touch
    # consumer-owned files matched by `preserve` — those are repo-specific.
    preserve = vcat(get(spec, "preserve", String[]), extra_preserve)
    if isdir(dst_root)
        stale = String[]
        for (root, _, files) in walkdir(dst_root), fn in files
            dst_abs = joinpath(root, fn)
            rel = normpath(relpath(dst_abs, dst_root))
            rel in owned && continue
            if is_preserved(rel, preserve)
                push!(actions, Action(:skip, relpath(dst_abs, target)))
            else
                push!(stale, dst_abs)
            end
        end
        for dst_abs in stale
            apply && rm(dst_abs)
            push!(actions, Action(:delete, relpath(dst_abs, target)))
        end
        apply && prune_empty_dirs(dst_root)
    end
    return actions
end

# Match a consumer path (relative to the mirror root) against preserve patterns:
#   "name/"   a directory segment anywhere in the path (e.g. "local/")
#   "*suffix" a filename/path suffix (e.g. "*.local.md")
#   other     an exact relative path
function is_preserved(rel, patterns)
    rel = replace(rel, '\\' => '/')
    for p in patterns
        if endswith(p, "/")
            occursin("/" * rstrip(p, '/') * "/", "/" * rel) && return true
        elseif startswith(p, "*")
            endswith(rel, p[2:end]) && return true
        elseif rel == p
            return true
        end
    end
    return false
end

function prune_empty_dirs(root)
    isdir(root) || return
    for (dir, _, _) in sort!(collect(walkdir(root)); by = first, rev = true)
        dir == root && continue
        isempty(readdir(dir)) && rm(dir)
    end
end

function run(argv = ARGS)
    opts = parse_args(argv)
    isdir(opts.target) || error("target is not a directory: $(opts.target)")
    manifest = TOML.parsefile(joinpath(SYNC_DIR, "manifest.toml"))

    overrides = load_overrides(opts.target)

    actions = Action[]
    haskey(manifest, "guides") && append!(
        actions,
        sync_guides(manifest["guides"], opts.target, overrides.preserve; apply = !opts.check),
    )

    for e in get(manifest, "enforce", Dict[])
        src_abs = joinpath(SOURCE_ROOT, e["src"])
        isfile(src_abs) || error("enforced source missing: $(e["src"])")
        push!(
            actions,
            copy_file(src_abs, joinpath(opts.target, e["dst"]), e["dst"];
                apply = !opts.check, overwrite = true),
        )
    end
    for s in get(manifest, "scaffold", Dict[])
        # A merged/monorepo consumer can opt out of resurrecting a scaffold stub
        # it deleted, via skip_scaffold in .devguides.toml.
        if s["dst"] in overrides.skip_scaffold
            push!(actions, Action(:skip, s["dst"]))
            continue
        end
        src_abs = joinpath(SOURCE_ROOT, s["src"])
        isfile(src_abs) || error("scaffold source missing: $(s["src"])")
        push!(
            actions,
            copy_file(src_abs, joinpath(opts.target, s["dst"]), s["dst"];
                apply = !opts.check, overwrite = false),
        )
    end

    report(actions, opts)
    return opts.check && any(changed, actions) ? 1 : 0
end

# Optional consumer-owned overrides, read from `.devguides.toml` at the target
# root. This file is never synced — it belongs to the consumer — and exists to
# keep merged/monorepos sane:
#   skip_scaffold = ["docs/repo_specific_guide.md"]  # don't recreate these stubs
#   preserve      = ["*.atmos.md"]                   # extra mirror preserve globs
function load_overrides(target)
    path = joinpath(target, ".devguides.toml")
    isfile(path) || return (; skip_scaffold = String[], preserve = String[])
    cfg = TOML.parsefile(path)
    return (;
        skip_scaffold = String.(get(cfg, "skip_scaffold", String[])),
        preserve = String.(get(cfg, "preserve", String[])),
    )
end

function report(actions, opts)
    glyph = Dict(
        :create => "＋ create  ",
        :update => "～ update  ",
        :delete => "－ delete  ",
        :unchanged => "  ok      ",
        :skip => "  keep    ",
    )
    if !opts.quiet
        for a in actions
            (opts.check && !changed(a)) && continue
            println(glyph[a.kind], a.dst)
        end
    end
    counts = Dict(k => count(a -> a.kind === k, actions) for k in keys(glyph))
    sha = source_sha()
    src = "CliMA/DeveloperGuides" * (isempty(sha) ? "" : "@" * sha[1:min(end, 7)])
    verb = opts.check ? "drift vs" : "synced from"
    println(
        "\n$verb $src: ",
        "$(counts[:create]) created, $(counts[:update]) updated, ",
        "$(counts[:delete]) deleted, $(counts[:skip]) kept, ",
        "$(counts[:unchanged]) unchanged.",
    )
    if opts.check && any(changed, actions)
        println("Out of sync — run without --check to apply.")
    end
end

function source_sha()
    try
        cmd = pipeline(`git -C $SOURCE_ROOT rev-parse HEAD`; stderr = devnull)
        return strip(read(cmd, String))
    catch
        return ""
    end
end

end # module

if abspath(PROGRAM_FILE) == (@__FILE__)
    exit(DevGuidesSync.run())
end
