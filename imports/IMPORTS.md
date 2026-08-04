# Import index

**Source-only** packages published to `ghcr.io/egao1980/cl-systems` via the shared
workflow — third-party pins **and** first-party Lisp-only systems. One directory
per pin (CI isolation). No per-repo publish scripts.

**Exclusivity:** do not import upstream `owner/X` while keeping a workspace fork of
`X`. Importing `egao1980/X` (fork or first-party) while developing that repo locally
is OK.

Exception note: `rove` pins **`egao1980/rove`** (parametrize); do **not** also import
`fukamachi/rove`.

Publish one import:

```bash
gh workflow run publish.yml -R egao1980/cl-stack-systems -f import=<name>
```

## First-party / maintained forks (source-only)

| Import | Source | Version @ pin | Why |
|--------|--------|---------------|-----|
| cl-idna | github egao1980/cl-idna `v0.1.0` | 0.1.0 | IDNA; quri |
| cl-mime | github egao1980/cl-mime `89a3292` | 0.5.1 | MIME; http stack |
| cl-stack-http | github egao1980/cl-stack-http `e90da3f` | 0.1.7 | HTTP DX facade |
| cl-stack-jwt | github egao1980/cl-stack-jwt `v0.1.0` | 0.1.0 | JWT |
| cl-stack-oauth2 | github egao1980/cl-stack-oauth2 `v0.1.0` | 0.1.0 | OAuth2 |
| cl-stack-pathlib | github egao1980/cl-stack-pathlib `0811791` | 0.1.1 | pathlib |
| event-protocol | github egao1980/event-protocol `30d9b37` | 0.1.1 | event loop protocol |
| http-backend-async | github egao1980/http-backend-async `ffcea8f` | 0.2.4 | async HTTP backend |
| http-backend-dexador | github egao1980/http-backend-dexador `fadc937` | 0.1.1 | dexador backend |
| http-backend-winhttp | github egao1980/http-backend-winhttp `6876b5e` | 0.1.3 | WinHTTP backend |
| http-encoding-brotli | github egao1980/http-encoding-brotli `8abc3f8` | 0.1.0 | brotli CE |
| http-encoding-chipz | github egao1980/http-encoding-chipz `41db76a` | 0.1.0 | gzip/deflate CE |
| http-encoding-zstd | github egao1980/http-encoding-zstd `38445e3` | 0.1.0 | zstd CE |
| http-protocol | github egao1980/http-protocol `9177f63` | 0.2.3 | HTTP wire protocol |
| quri | github egao1980/quri `v0.7.1` | 0.7.1 | URI (fork) |
| ws-protocol | github egao1980/ws-protocol `0fc015e` | 0.2.2 | WebSocket protocol |
| rove | github egao1980/rove `6ba5b74` (`deftest-parametrize`; upstream [fukamachi/rove#76](https://github.com/fukamachi/rove/pull/76)) | — | stack test runner |

## Third-party

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

## Intentionally not here

| System | Reason |
|--------|--------|
| cl-stack-ssl, cl-stack-brotli, cl-stack-zstd, event-backend-* | **native overlays** — own publish via cl-repository reusable workflow |
| cl-mcp, cl-repository | tooling; not `cl-systems` library pins |

## Deferred (dexador wave / cl+ssl transitive)

dexador, fast-http, cl-cookie, chunga, trivial-mimes, bordeaux-threads,
usocket, trivial-garbage — add when http-protocol sync backend lands or
when cl+ssl publish needs them explicitly.
