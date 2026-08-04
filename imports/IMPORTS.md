# Import index

**Source-only** packages published to `ghcr.io/egao1980/cl-systems` via the shared
workflow — third-party pins **and** first-party Lisp-only systems. One directory
per pin (CI isolation). No per-repo publish scripts.

**Exclusivity:** do not import upstream `owner/X` while keeping a workspace fork of
`X`. Importing `egao1980/X` (fork or first-party) while developing that repo locally
is OK.

Exception note: `rove` pins **`egao1980/rove`** (parametrize); do **not** also import
`fukamachi/rove`.

| Import | Source | Why |
|--------|--------|-----|
| alexandria | git gitlab.common-lisp.net/alexandria/alexandria | quri |
| babel | github cl-babel/babel | quri |
| cffi | github cffi/cffi `v0.24.1` → OCI `0.24.1` (asd has no `:version`; publish forces pin) | event-backend-*, cl-stack-brotli/zstd, http-backend-winhttp |
| chipz | github sharplispers/chipz | http-protocol |
| cl-base64 | github darabi/cl-base64 | cl-mime |
| cl-plus-ssl | github cl-plus-ssl/cl-plus-ssl (`system` → `cl+ssl`; OCI name `cl-plus-ssl`) | cl-stack-ssl |
| cl-ppcre | github edicl/cl-ppcre | cl-mime |
| cl-qprint | github eugeneia/cl-qprint | cl-mime |
| cl-unicode | github edicl/cl-unicode | cl-idna |
| cl-utilities | git gitlab.common-lisp.net/cl-utilities | cl-idna, quri |
| flexi-streams | github edicl/flexi-streams | cl-qprint |
| jose | github fukamachi/jose `345d8cf67ea7` → **OCI `0.1.0` published** | [`cl-stack-jwt`](https://github.com/egao1980/cl-stack-jwt) **0.1.0**; runtime QL-fallback for ironclad/cl-json/assoc-utils/trivial-utf-8 until those are imported |
| salza2 | github xach/salza2 | http-protocol |
| split-sequence | github sharplispers/split-sequence | quri |
| trivial-features | github trivial-features/trivial-features | babel, cffi |
| trivial-gray-streams | github trivial-gray-streams/trivial-gray-streams | salza2 |
| rove | github egao1980/rove `6ba5b74` (`deftest-parametrize`; upstream [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76)) | stack test runner / corpus tables |

## Intentionally not here (yet / never)

| System | Reason |
|--------|--------|
| cl-stack-ssl, cl-stack-brotli, cl-stack-zstd, event-backend-* | **native overlays** — own publish via cl-repository reusable workflow |
| cl-mcp, cl-repository | tooling; not `cl-systems` library pins |
| http-protocol, event-protocol, cl-stack-*, cl-idna, quri, cl-mime, … | **migrate:** source-only first-party/forks should gain `imports/<name>/qlfile` here and drop per-repo `publish-source.lisp` |

## Deferred (dexador wave / cl+ssl transitive)

dexador, fast-http, cl-cookie, chunga, trivial-mimes, bordeaux-threads,
usocket, trivial-garbage — add when http-protocol sync backend lands or
when cl+ssl publish needs them explicitly.
