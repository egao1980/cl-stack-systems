# Import index

**Third-party / unmodified** source-only packages published to
`ghcr.io/egao1980/cl-systems` via the shared workflow. One directory per pin
(CI isolation). No per-repo publish scripts.

**First-party `egao1980/<repo>` packages are not imported here.** Package write
on GHCR is tied to the owning GitHub repo — publish those from the owning repo
(`publish-checkout.yml` or native reusable workflow). Routing them through
`cl-stack-systems` yields `permission_denied: write_package`.

**Exclusivity:** do not import upstream `owner/X` while keeping a workspace fork of
`X`.

Publish one import:

```bash
gh workflow run publish.yml -R egao1980/cl-stack-systems -f import=<name>
```

## Third-party

| Import | Source | Why |
|--------|--------|-----|
| alexandria | git gitlab.common-lisp.net/alexandria/alexandria | quri |
| babel | github cl-babel/babel | quri |
| blackbird | github orthecreedence/blackbird `1ec17c5` | http-protocol, ws-protocol |
| bordeaux-threads | github sionescu/bordeaux-threads `v0.9.4` → OCI `0.9.4` (bt2 API) | concurrency default (#95); global-vars + trivial-garbage |
| cffi | github cffi/cffi `v0.24.1` → OCI `0.24.1` (asd has no `:version`; publish forces pin) | event-backend-*, cl-stack-brotli/zstd, http-backend-winhttp |
| chipz | github sharplispers/chipz | http-protocol |
| cl-cookie | github fukamachi/cl-cookie `355f9c1` | http-protocol |
| closer-mop | git codeberg.org/pcostanza/closer-mop `f17d7fb` → OCI `1.0.0` | jzon / com.inuoe.jzon (GitHub upstream gone) |
| com.inuoe.jzon | github Zulu-Inuoe/jzon `v1.1.4` / `99b19fb` → OCI `1.1.4` | [`json-protocol`](https://github.com/egao1980/json-protocol) default backend |
| documentation-utils | git codeberg.org/shinmera/documentation-utils `cd5b506` → OCI `1.2.0` | float-features |
| float-features | git codeberg.org/shinmera/float-features `136a908` → OCI `1.1.0` | jzon (non-ECL) |
| cl-base64 | github darabi/cl-base64 | cl-mime |
| local-time | github dlowe-net/local-time `59d93f7` | cl-cookie |
| proc-parse | github fukamachi/proc-parse `3afe2b7` | cl-cookie |
| vom | github orthecreedence/vom `303c3f6` | blackbird |
| cl-plus-ssl | github cl-plus-ssl/cl-plus-ssl (`system` → `cl+ssl`; OCI name `cl-plus-ssl`) | cl-stack-ssl |
| cl-ppcre | github edicl/cl-ppcre | cl-mime |
| cl-qprint | github eugeneia/cl-qprint | cl-mime |
| cl-unicode | github edicl/cl-unicode | cl-idna |
| cl-utilities | git gitlab.common-lisp.net/cl-utilities | cl-idna, quri |
| flexi-streams | github edicl/flexi-streams | cl-qprint |
| global-vars | github lmj/global-vars `c749f32` → OCI `1.0.0` | bordeaux-threads |
| jose | github fukamachi/jose `345d8cf67ea7` → **OCI `0.1.0` published** | [`cl-stack-jwt`](https://github.com/egao1980/cl-stack-jwt) **0.1.0**; runtime QL-fallback for ironclad/cl-json/assoc-utils/trivial-utf-8 until those are imported |
| salza2 | github xach/salza2 | http-protocol |
| split-sequence | github sharplispers/split-sequence | quri |
| tomlet | github fukamachi/tomlet `f55bf85` → OCI `0.1.0` | [`cl-stack-config`](https://github.com/egao1980/cl-stack-config) TOML parser (#99) |
| trivial-features | github trivial-features/trivial-features | babel, cffi, float-features, bordeaux-threads |
| trivial-garbage | github trivial-garbage/trivial-garbage `v0.21` → OCI `0.21` | bordeaux-threads |
| trivial-gray-streams | github trivial-gray-streams/trivial-gray-streams | salza2, yason |
| trivial-indent | git codeberg.org/shinmera/trivial-indent `5905ac0` → OCI `1.0.0` | documentation-utils |
| yason | github phmarek/yason `0c84b29` → OCI `0.8.3` | json-backend-yason alternate |

## Intentionally not here

| System | Reason |
|--------|--------|
| First-party Lisp systems (`http-protocol`, backends, `ws-protocol`, encodings, `cl-stack-*`, `cl-mime`, `cl-idna`, `quri`, `event-protocol`, `rove`, …) | Publish from the **owning** `egao1980/<repo>` (`publish-checkout.yml`) |
| cl-stack-ssl, cl-stack-brotli, cl-stack-zstd, event-backend-* | **native overlays** — own publish via cl-repository reusable workflow |
| cl-mcp, cl-repository | tooling; not `cl-systems` library pins |

## Deferred (dexador wave / cl+ssl transitive)

dexador, fast-http, chunga, trivial-mimes, usocket — add when
http-protocol sync backend lands or when cl+ssl publish needs them explicitly.
