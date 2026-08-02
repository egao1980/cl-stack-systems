# Import index

Direct unforked third-party deps of current stack systems, plus one-hop
support libs needed to load them. One directory per pin (CI isolation).

| Import | Source | Why |
|--------|--------|-----|
| alexandria | git gitlab.common-lisp.net/alexandria/alexandria | quri |
| babel | github cl-babel/babel | quri |
| cffi | github cffi/cffi | event-backend-*, cl-stack-brotli/zstd |
| chipz | github sharplispers/chipz | http-protocol |
| cl-base64 | github darabi/cl-base64 | cl-mime |
| cl-plus-ssl | github cl-plus-ssl/cl-plus-ssl (`system` → `cl+ssl`; OCI name `cl-plus-ssl`) | cl-stack-ssl |
| cl-ppcre | github edicl/cl-ppcre | cl-mime |
| cl-qprint | github eugeneia/cl-qprint | cl-mime |
| cl-unicode | github edicl/cl-unicode | cl-idna |
| cl-utilities | git gitlab.common-lisp.net/cl-utilities | cl-idna, quri |
| flexi-streams | github edicl/flexi-streams | cl-qprint |
| salza2 | github xach/salza2 | http-protocol |
| split-sequence | github sharplispers/split-sequence | quri |
| trivial-features | github trivial-features/trivial-features | babel, cffi |
| trivial-gray-streams | github trivial-gray-streams/trivial-gray-streams | salza2 |

## Intentionally not here

| System | Reason |
|--------|--------|
| cl-idna, http-protocol, event-*, cl-stack-* | first-party egao1980 |
| quri, cl-mime | forked/patched — workspace checkout |
| cl-mcp, cl-repository | forked tooling |
| rove | test-only |

## Deferred (dexador wave / cl+ssl transitive)

dexador, fast-http, cl-cookie, chunga, trivial-mimes, bordeaux-threads,
usocket, trivial-garbage — add when http-protocol sync backend lands or
when cl+ssl publish needs them explicitly.
