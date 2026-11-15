# vendor/antigravity-port — local backport of PR #623 (prompt-signature sanitizer)

Durable copies of the hand-applied patch that neutralizes the OpenCode V2 Code Mode
prompt signature (`tools.opencode.*` → `tools["opencode"].*`) inside
`opencode-antigravity-auth@2.1.2`'s **compiled dist artifact**.

Upstream: `NoeFabris/opencode-antigravity-auth` PR #623 / issue #622 — Google's
`daily-cloudcode-pa.googleapis.com` endpoint returns a deterministic bare 429
`RESOURCE_EXHAUSTED` for any request whose `systemInstruction` contains the literal
`tools.opencode.session_move`; the plugin's quota fallback then masks it as a misleading
403 `SUBSCRIPTION_REQUIRED`.

**This patch is EPHEMERAL by nature**: it lives inside opencode's npm cache and is lost on
a plugin version bump or npm cache GC. Re-apply it (the commands below) whenever
`opencode-antigravity-auth` moves version, or drop it entirely once an npm release
contains upstream PR #623.

## Layout

| Path | Maps to |
|---|---|
| `plugin/transform/prompt-signature.js` | `<installhash>/node_modules/opencode-antigravity-auth/dist/src/plugin/transform/prompt-signature.js` (NEW file added by the port) |
| `plugin/request.js` | `<installhash>/node_modules/opencode-antigravity-auth/dist/src/plugin/request.js` (patched: import + 2 integration call sites) |
| `backup/request.js.registry-original` | pristine pre-port `request.js` as shipped by the registry (rollback source) |
| `backup/HASHES.sha256` | pre-port and post-port sha256 of the live-dist files |

`<installhash>` = the numeric cache dir, currently `1793349514842`:

```text
~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2/<installhash>/node_modules/opencode-antigravity-auth/dist/src
```

Resolve it dynamically — the hash changes on every install (if several hash dirs exist,
apply the port to every one of them):

```bash
DIST=$(ls -d ~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2/*/node_modules/opencode-antigravity-auth/dist/src)
echo "$DIST"   # one line per install hash
```

## Restore (re-apply the port)

```bash
V=~/Proyectos/dotfiles/vendor/antigravity-port

# loop covers every install hash present (usually one)
for D in ~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2/*/node_modules/opencode-antigravity-auth/dist/src; do
  cp -a "$D/plugin/request.js" "/tmp/opencode/request.js.live.$(basename "$D" | cut -d/ -f1).$(date +%s)"  # rollback copy
  cp -a "$V/plugin/transform/prompt-signature.js" "$D/plugin/transform/prompt-signature.js"
  cp -a "$V/plugin/request.js" "$D/plugin/request.js"
  node --check "$D/plugin/request.js" && node --check "$D/plugin/transform/prompt-signature.js"
  sha256sum "$D/plugin/request.js" "$D/plugin/transform/prompt-signature.js"
done
```

Then **`opencode service restart`** — a rebuild/hot reload does not re-register plugin
hooks on live sessions.

Expected post-restore hashes: `request.js = c8f0804342b687ca…`, `prompt-signature.js = 09883828fb30dd92…`
(see `backup/HASHES.sha256`).

## Rollback (back to registry original)

```bash
for D in ~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2/*/node_modules/opencode-antigravity-auth/dist/src; do
  cp -a ~/Proyectos/dotfiles/vendor/antigravity-port/backup/request.js.registry-original "$D/plugin/request.js"
  rm -f "$D/plugin/transform/prompt-signature.js"   # added by the port
done
opencode service restart
```

Verified by drill (2026-11-15, sandbox `/tmp/opencode/rollback-drill`): restoring
`backup/request.js.registry-original` yields sha `1c1c2089e5466be0…` == the pre-port entry
in `backup/HASHES.sha256`, and the file passes `node --check`.

`opencode` also self-heals this: deleting `~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2`
forces a clean re-download of the unpatched package (the 403/429 symptom returns).

## Stale-cache pin-drift trap (disabled 2026-11-15)

The npm cache also held an unported copy of a *newer* build under the `@latest` spec
(no `prompt-signature.js`, `request.js` sha `366390c8910ec787…`). `opencode.json` pins
`opencode-antigravity-auth@2.1.2`, so it was unused, but if the pin ever drifted to
`@latest` the loaders would silently run the unported build and the 403/429 symptom would
come back with no visible cause. The cache dir was renamed so nothing resolves to it:

```bash
# done:
mv ~/.cache/opencode/npm/opencode-antigravity-auth@latest \
   ~/.cache/opencode/npm/opencode-antigravity-auth@latest_stale_unported
# undo (restore the trap):
mv ~/.cache/opencode/npm/opencode-antigravity-auth@latest_stale_unported \
   ~/.cache/opencode/npm/opencode-antigravity-auth@latest
```

If a fresh `@latest` install is ever wanted, opencode will simply re-download it into a
new `opencode-antigravity-auth@latest/` dir — then re-apply this port to it.

## What the patch does in `request.js`

1. `import { sanitizeOpenCodePromptSignatureInPlace } from "./transform/prompt-signature.js";`
2. **Integration A** — already-wrapped Antigravity body: sanitize runs **after** the
   signed-thinking warmup heuristic and **before** `JSON.stringify`.
   Invariant (FM1): signature-cache lookups key on `hashText(part.text)` of the
   **ORIGINAL** text; rewriting earlier forces a cache miss and a needless warmup
   round-trip. The **wire body must still be serialized sanitized**.
3. **Integration B** — plain (unwrapped) payload: sanitize sits after the heuristic and
   before `JSON.stringify`; already correct, untouched.

`prompt-signature.js` intentionally transforms the **object payload before
`JSON.stringify`**, never the serialized string — post-stringification replacement would
inject unescaped `"` into JSON string literals and corrupt the body.

## Verification harness

Lives in `/tmp/opencode/fm1-ab/` (ephemeral — gone on reboot; copy it into this vendor dir
if you want it durable):

| Script | Purpose |
|---|---|
| `smoke-sanitize.mjs <dist/src>` | direct sanitizer smoke: replacement, idempotence, JSON round-trip, string-shaped `systemInstruction`, `messages[]`, `extra_body`, null-safety, plus the negative control proving the transform must happen **pre**-`JSON.stringify` |
| `fm1-mechanism.mjs` | isolates FM1: primes `cacheSignature(sessionId, ORIGINAL_text, sig)`, shows `hasSignedThinkingInContents` hits before sanitize and **misses after an early sanitize** |
| `fm1-ab.mjs <pre\|post>` / `e2e-wire.mjs <pre\|post>` | end-to-end pre/post equivalence through `prepareAntigravityRequest` (integration A) |

The A/B variants were two throwaway copies of the install tree:

```bash
SRC=~/.cache/opencode/npm/opencode-antigravity-auth@2.1.2/1793349514842
mkdir -p /tmp/opencode/fm1-ab
cp -a "$SRC" /tmp/opencode/fm1-ab/pre && cp -a "$SRC" /tmp/opencode/fm1-ab/post
cp -a /tmp/opencode/dist-backup/request.js.pre-fm1 \
   /tmp/opencode/fm1-ab/pre/node_modules/opencode-antigravity-auth/dist/src/plugin/request.js
# post/ keeps the live (patched) request.js; delete both trees afterwards, they are ~210 MB
# each and /tmp is tmpfs (RAM-backed).
```


## Provenance / status

- Applied by hand to a compiled dist artifact → **out of band, not tracked by the package manager**.
- These repo copies are **untracked until the user commits them** (`vendor/` is new in this session).
- Do **not** edit `~/.cache/opencode/npm/...` by hand for anything else — the whole dir is
  a rebuild target.
