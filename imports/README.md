# Imports

One directory per upstream pin. CI discovers `*/qlfile` and publishes each in isolation.

```bash
../scripts/add-import.sh owner/repo v1.2.3
```

See [IMPORTS.md](IMPORTS.md) for the current stack-seeded set.

Optional sibling `system` file: ASDF system name when it differs from the
directory name (e.g. `cl-plus-ssl/system` → `cl+ssl`).

Do **not** put unrelated libraries in the same qlfile — that defeats isolation.
