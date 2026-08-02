# cl-stack-systems

Manifest repo for **source-only** republish of third-party Common Lisp libraries into
`ghcr.io/egao1980/cl-systems` — **without forking**.

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

### When to use this vs a fork

| Situation | Action |
|-----------|--------|
| Unmodified third-party Lisp dep | Add import here; publish to `cl-systems` |
| Need patches / own CI / native overlays | Fork into `egao1980` (workspace checkout) |

**Exclusive:** fork ⇒ remove `imports/<name>/` here. Import ⇒ do not also
keep a workspace fork of that library.

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
