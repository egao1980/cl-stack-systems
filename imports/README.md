# Imports

One directory per upstream pin. CI discovers `*/qlfile` and publishes each in isolation.

```bash
../scripts/add-import.sh owner/repo v1.2.3
```

See [IMPORTS.md](IMPORTS.md) for the current stack-seeded set.

Optional sibling files:

| File | Purpose |
|------|---------|
| `system` | ASDF system name when it differs from the directory (e.g. `cl-plus-ssl` → `cl+ssl`) |
| `version` | Force OCI tag when the `.asd` omits `:version` (e.g. `trivial-utf-8`) |

Do **not** put unrelated libraries in the same qlfile — that defeats isolation.
