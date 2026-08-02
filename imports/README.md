# Imports

One directory per upstream pin. CI discovers `*/qlfile` and publishes each in isolation.

```bash
../scripts/add-import.sh owner/repo v1.2.3
```

Do **not** put unrelated libraries in the same qlfile — that defeats isolation.
