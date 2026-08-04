# cl-stack-systems

Manifest repo for **source-only** OCI publish into `ghcr.io/egao1980/cl-systems`.

Covers **unmodified third-party** and **first-party Lisp-only** packages (no native
overlays). Publish is **convention-only**: `imports/<name>/qlfile` + shared
`publish.yml` / `scripts/publish-import.lisp` — **no** per-package `publish-source.lisp`.

Packages with native overlays stay in their own repos and use cl-repository’s
reusable native publish workflow.

Each import is an isolated unit under `imports/<name>/qlfile` so CI never co-loads
incompatible dependency graphs.

## Layout

```text
imports/
  <name>/qlfile     # usually one github/git root pin
```

Example:

```text
# imports/alexandria/qlfile
github alexandria/alexandria v1.4
```

## Adding an import

```bash
./scripts/add-import.sh alexandria/alexandria v1.4
# → imports/alexandria/qlfile
```

Or hand-write `imports/<name>/qlfile`. Prefer pinned tags/SHAs.

### When to use this vs a fork / native repo

| Situation | Action |
|-----------|--------|
| Unmodified third-party (source-only) | Add import here |
| First-party egao1980 **without** natives | Add import here (`github egao1980/<repo> <tag>`) — do **not** add repo-local publish scripts |
| Patches only (still source-only) | Fork to `egao1980`, import the fork pin here |
| Native overlays / grovel / CFFI libs | Own repo + cl-repository native publish workflow |

**Exclusive:** never import upstream `owner/X` while also keeping a workspace fork of `X`.
Importing `egao1980/X` while developing that fork locally is OK.

## CI

`.github/workflows/publish.yml` discovers `imports/*/qlfile` and publishes each in a
separate matrix job (`fail-fast: false`).

```bash
# manual: one import
gh workflow run publish.yml -f import=alexandria
```

## Local publish

Requires SBCL, Quicklisp, git, oras, and `cl-repository-packager` under
`~/.local/share/cl-systems/` (same as other egao1980 publish workflows).

```bash
export OCI_REGISTRY=ghcr.io
export OCI_NAMESPACE=egao1980/cl-systems
export GITHUB_ACTOR=egao1980
export GITHUB_TOKEN=…   # packages:write
export PKG_QLFILE=imports/alexandria/qlfile
sbcl --non-interactive --load scripts/publish-import.lisp
```
