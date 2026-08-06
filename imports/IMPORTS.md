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
| adopt | github sjl/adopt `v1.3.0` | cli-backend-adopt |
| alexandria | git gitlab.common-lisp.net/alexandria/alexandria | quri |
| bobbin | github sjl/bobbin `v1.0.1` | clingon, adopt |
| clingon | github dnaeon/clingon `v0.7.0` | cli-backend-clingon |
| cl-reexport | github takagi/cl-reexport `03ad7a0` | clingon |
| babel | github cl-babel/babel | quri |
| blackbird | github orthecreedence/blackbird `1ec17c5` | http-protocol, ws-protocol |
| bordeaux-threads | github sionescu/bordeaux-threads `v0.9.4` → OCI `0.9.4` (bt2 API) | concurrency default (#95); global-vars + trivial-garbage |
| cffi | github cffi/cffi `v0.24.1` → OCI `0.24.1` (asd has no `:version`; publish forces pin) | event-backend-*, cl-stack-brotli/zstd, http-backend-winhttp |
| chipz | github sharplispers/chipz | http-protocol |
| cl-cookie | github fukamachi/cl-cookie `355f9c1` | http-protocol |
| chunga | github edicl/chunga `v1.1.9` → OCI `1.1.9` | hunchentoot |
| cl-fad | github edicl/cl-fad `3f4d32d` → OCI `0.7.6` | hunchentoot |
| clack | github fukamachi/clack `9435762` → OCI `2.1.0` | http-server-protocol app layer |
| clack-handler-hunchentoot | github fukamachi/clack `9435762` → OCI `0.5.0` | default server backend |
| clack-handler-woo | github fukamachi/woo `2ef0d22` | Woo Clack handler (Unix) |
| clack-socket | github fukamachi/clack `9435762` → OCI `0.2.0` | clack-handler-hunchentoot |
| hunchentoot | github edicl/hunchentoot `v1.3.1` → OCI `1.3.1` | http-server default (Windows+) |
| ironclad | github sharplispers/ironclad `v0.61` → OCI `0.61` | lack-util |
| lack | github fukamachi/lack `35d8b0a` → OCI `0.3.0` | Clack middleware builder |
| log4cl | github sharplispers/log4cl `v1.1.2` | log-backend-log4cl |
| lack-component | github fukamachi/lack `35d8b0a` → OCI `0.2.0` | lack |
| lack-middleware-backtrace | github fukamachi/lack `35d8b0a` → OCI `0.2.0` | clack |
| lack-util | github fukamachi/lack `35d8b0a` → OCI `0.2.0` | lack / clack |
| lev | github fukamachi/lev `b43e700` | woo (libev bindings) |
| md5 | github pmai/md5 `906593f` → OCI `2.0.4` | hunchentoot |
| rfc2388 | github jdz/rfc2388 `591bcf7` → OCI `1.5` | hunchentoot multipart |
| trivial-backtrace | github gwkkwg/trivial-backtrace `7f90b4a` → OCI `1.1.0` | hunchentoot |
| usocket | github usocket/usocket `v0.8.9` → OCI `0.8.9` | hunchentoot, clack |
| woo | github fukamachi/woo `2ef0d22` → OCI `0.12.0` | http-server Unix backend |
| closer-mop | git codeberg.org/pcostanza/closer-mop `f17d7fb` → OCI `1.0.0` | jzon / com.inuoe.jzon (GitHub upstream gone) |
| com.inuoe.jzon | github Zulu-Inuoe/jzon `v1.1.4` / `99b19fb` → OCI `1.1.4` | [`json-protocol`](https://github.com/egao1980/json-protocol) default backend |
| documentation-utils | git codeberg.org/shinmera/documentation-utils `cd5b506` → OCI `1.2.0` | float-features |
| float-features | git codeberg.org/shinmera/float-features `136a908` → OCI `1.1.0` | jzon (non-ECL) |
| cl-base64 | github darabi/cl-base64 | cl-mime |
| local-time | github dlowe-net/local-time `59d93f7` | cl-cookie |
| proc-parse | github fukamachi/proc-parse `3afe2b7` | cl-cookie |
| vom | github orthecreedence/vom `303c3f6` | blackbird; log-backend-vom |
| with-user-abort | github compufox/with-user-abort `a3db02e` | clingon |
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
| dbi / cl-dbi / dbd-sqlite3 / dbd-postgres | github fukamachi/cl-dbi `2f4f8b4` → OCI `0.11.1` (dbd-* revision-tagged) | [`sql-protocol`](https://github.com/egao1980/sql-protocol) connectivity |
| sqlite | github TeMPOraL/cl-sqlite `0.2.1` → OCI `0.2.1` | dbd-sqlite3 |
| iterate | git gitlab.common-lisp.net/iterate/iterate `d27d7ff` → OCI `1.6.0` | sqlite, trivia.balland2006 |
| cl-postgres | github marijnh/Postmodern `v1.33.12` → **OCI `1.33.12` published** | dbd-postgres |
| uax-15 | github sabracrolleton/uax-15 `v0.1.3` → OCI `0.1.3` | cl-postgres |
| sxql | github fukamachi/sxql `72c1c8c` → OCI `0.1.0` | sql-query / mito |
| trivia (+ balland2006 / trivial / level0–2) | github guicho271828/trivia `4383dd8` | sxql, mito |
| type-i | github guicho271828/type-i `4407a68` | trivia.balland2006 |
| lisp-namespace | github guicho271828/lisp-namespace `699fccb` | trivia.level2, type-i |
| introspect-environment | github Bike/introspect-environment `69a50ac` | type-i |
| trivial-cltl2 | github Zulu-Inuoe/trivial-cltl2 `2ada872` → OCI `0.1.1` | trivia.level2 |
| cl-package-locks | github elliottjohnson/cl-package-locks `96a358e` → OCI `0.0.2` | sxql, mito |
| mito / mito-core / mito-migration / lack-middleware-mito | github fukamachi/mito `8b9e53d` → OCI `0.2.0` | sql-orm |
| dissect | github Shinmera/dissect `43b42a3` → OCI `1.0.0` | mito-core |
| esrap | github scymtym/esrap `release-0.18` → **OCI `0.18` published** | mito-migration |
| trivial-with-current-source-form | github scymtym/trivial-with-current-source-form `d00f7ab` | esrap |
| uuid | github dardoria/uuid `f0052f3` → OCI `2012.12.26` | mito-core |
| trivial-utf-8 | git gitlab.common-lisp.net/trivial-utf-8 `3cd943e` (pre-mgl-pax) → **OCI `0.1.0` published** | uuid; pin avoids mgl-pax-bootstrap |

## Intentionally not here

| System | Reason |
|--------|--------|
| First-party Lisp systems (`http-protocol`, backends, `ws-protocol`, encodings, `cl-stack-*`, `cl-mime`, `cl-idna`, `quri`, `event-protocol`, `sql-protocol`, `rove`, …) | Publish from the **owning** `egao1980/<repo>` (`publish-checkout.yml`) |
| cl-stack-ssl, cl-stack-brotli, cl-stack-zstd, event-backend-* | **native overlays** — own publish via cl-repository reusable workflow |
| cl-mcp, cl-repository | tooling; not `cl-systems` library pins |

## Deferred (dexador wave / cl+ssl transitive)

dexador, fast-http, trivial-mimes — add when http-protocol sync backend
lands or when cl+ssl publish needs them explicitly.

Natives for SQL (libsqlite3 / libpq) — system packages in CI until overlays.

`mgl-pax` / full doc tooling — not imported; `trivial-utf-8` pinned to pre-bootstrap commit.
