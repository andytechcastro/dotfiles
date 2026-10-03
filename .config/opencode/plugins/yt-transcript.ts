import { Plugin } from "@opencode/plugin"
import { execFile } from "node:child_process"
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

/**
 * yt_transcript — transcripto de vídeos de YouTube vía el binario local
 * `yt-dlp` (sin descargar el vídeo, sin API de pago). Port V2 con el mismo
 * contrato que run-watch.ts: `Plugin.define` + `ctx.tool.transform` +
 * `editor.add` con JSON Schema plano.
 *
 * Verificado empíricamente contra yt-dlp 2026.08.19:
 *  - Manual Y auto escriben el mismo nombre `<id>.<lang>.json3` (sin sufijo
 *    ".auto"). Si para el lang pedido existen ambos, yt-dlp deduplica y
 *    escribe SOLO el manual → la preferencia manual-es-automática es gratis.
 *  - Lang inexistente → exit 0, sin fichero, WARNING "There are no subtitles
 *    for the requested languages" → hay que hacer --list-subs como feedback.
 *  - 429 (throttling real observado) → exit != 0 con "ERROR: ... HTTP Error
 *    429" en stderr → se surfaceea tal cual con hint de reintento.
 *  - json3: { events: [ { tStartMs, dDurationMs?, segs: [ { utf8 } ] } ] }.
 *    Manual: pocos eventos, segs con "\n" dentro. Auto: eventos con segs de
 *    nivel palabra (los utf8 traen espacios/saltos; se concatenan crudos).
 */

type YtArgs = {
  url: string
  lang?: string
}

const TMP_ROOT = "/tmp/opencode/yt-transcript"
const MAX_TRANSCRIPT_CHARS = 100_000
const MAX_LIST_CHARS = 20_000
const YTDLP_TIMEOUT_MS = 120_000
const YTDLP_MAX_BUFFER = 32 * 1024 * 1024
const YTDLP_STDERR_HINT = 300

/** Ruta preferida (~/.local/bin) con fallback al PATH. */
const resolveYtDlp = (): string => {
  const local = join(homedir(), ".local", "bin", "yt-dlp")
  return existsSync(local) ? local : "yt-dlp"
}

type YtRun = {
  ok: boolean
  aborted: boolean
  code: number
  stdout: string
  stderr: string
}

/** execFile (sin shell → sin interpolación); signal de ToolContext cancela el hijo. */
const runYtDlp = (args: string[], signal?: AbortSignal): Promise<YtRun> =>
  new Promise((resolve) => {
    execFile(
      resolveYtDlp(),
      args,
      { signal, maxBuffer: YTDLP_MAX_BUFFER, timeout: YTDLP_TIMEOUT_MS },
      (err, stdout, stderr) => {
        if (signal?.aborted) {
          resolve({ ok: false, aborted: true, code: 130, stdout, stderr })
          return
        }
        if (err) {
          const e = err as NodeJS.ErrnoException & { code?: number | string }
          // code numérico = exit del proceso; string (ENOENT, ETIMEDOUT…) = fallo de spawn
          const code = typeof e.code === "number" ? e.code : 1
          resolve({ ok: false, aborted: false, code, stdout, stderr: stderr || e.message })
          return
        }
        resolve({ ok: true, aborted: false, code: 0, stdout, stderr })
      },
    )
  })

/** Acepta URL http(s) o ID desnudo de 11 chars; nada que empiece por "-" (inyección de flags). */
const normalizeUrl = (raw: string): string | null => {
  const s = String(raw ?? "").trim()
  if (/^[A-Za-z0-9_-]{11}$/.test(s)) return `https://www.youtube.com/watch?v=${s}`
  if (/^https?:\/\//i.test(s)) return s
  return null
}

const videoId = (url: string): string => {
  const m = url.match(/(?:v=|youtu\.be\/)([A-Za-z0-9_-]{11})/)
  return m ? m[1] : url.slice(0, 40)
}

/** Codes de lang / patrones yt-dlp: letras, dígitos, . _ - * , (regex y listas). */
const LANG_RE = /^[A-Za-z0-9._*\-,]{1,60}$/

const stamp = (ms: number): string => {
  const total = Math.max(0, Math.floor(ms / 1000))
  const mm = String(Math.floor(total / 60)).padStart(2, "0")
  const ss = String(total % 60).padStart(2, "0")
  return `[${mm}:${ss}]`
}

type Json3Doc = {
  events?: Array<{ tStartMs?: number; segs?: Array<{ utf8?: string }> }>
}

/** json3 → texto plano: un evento = una línea con sello [mm:ss]. */
const buildTranscript = (doc: Json3Doc): string => {
  const lines: string[] = []
  let prev = ""
  for (const ev of doc.events ?? []) {
    // Los segs se concatenan CRUDOS: en auto-subs de nivel palabra los utf8 ya
    // traen los espacios/saltos de línea; en manual un solo seg lleva "\n".
    const raw = (ev.segs ?? []).map((s) => s.utf8 ?? "").join("")
    const text = raw.replace(/\r?\n/g, " ").replace(/\s+/g, " ").trim()
    if (!text) continue
    if (/^\[?(music|♪+|\(silence\))\]?$/i.test(text)) continue
    if (text === prev) continue // artefacto de ventana deslizante en auto-subs
    prev = text
    lines.push(typeof ev.tStartMs === "number" ? `${stamp(ev.tStartMs)} ${text}` : text)
  }
  return lines.join("\n")
}

/**
 * Selección del .json3 a parsear. Un lang exacto → un fichero (verificado).
 * Con patrones (lang="en.*,de") puede haber varios: preferir coincidencia
 * exacta `.<lang>.json3`; si no, el más reciente por mtime. La preferencia
 * manual-vs-auto YA la aplica yt-dlp al escribir (mismo nombre, gana manual).
 */
const pickJson3 = (dir: string, lang: string): string | null => {
  let names: string[]
  try {
    names = readdirSync(dir)
  } catch {
    return null
  }
  const files = names.filter((n) => n.endsWith(".json3"))
  if (files.length === 0) return null
  if (files.length === 1) return join(dir, files[0])
  const exact = files.filter((n) => n.endsWith(`.${lang}.json3`))
  const pool = exact.length > 0 ? exact : files
  let best = pool[0]
  let bestM = -1
  for (const f of pool) {
    try {
      const m = statSync(join(dir, f)).mtimeMs
      if (m > bestM) {
        bestM = m
        best = f
      }
    } catch {
      /* stat racing: siguiente */
    }
  }
  return join(dir, best)
}

const cap = (s: string, n: number): string =>
  s.length > n ? `${s.slice(0, n)}\n…(lista truncada a ${n} chars)` : s

const textResult = (text: string, metadata?: Record<string, unknown>) => ({
  content: [{ type: "text" as const, text }],
  ...(metadata ? { metadata } : {}),
})

const errorText = (r: YtRun): string => {
  const msg = (r.stderr || r.stdout || "error desconocido").trim().slice(0, YTDLP_STDERR_HINT)
  return (
    `yt-dlp falló (exit=${r.code}): ${msg}\n` +
    `Nota: YouTube throttles aggressive polling; retry later (429/rate-limit, ` +
    `"Sign in to confirm" o red).`
  )
}

export default Plugin.define({
  id: "yt-transcript",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "yt_transcript",
        description:
          "Obtiene el transcripto/subtítulos de un vídeo de YouTube vía yt-dlp (sin descarga, sin API). lang='list' para ver idiomas disponibles.",
        input: {
          type: "object",
          properties: {
            url: {
              type: "string",
              description: "YouTube video URL or ID",
            },
            lang: {
              type: "string",
              description:
                "Subtitle language code, default 'en'; 'list' returns available languages",
            },
          },
          required: ["url"],
          additionalProperties: false,
        },
        execute: async (raw, tctx) => {
          const args = raw as YtArgs
          const url = normalizeUrl(args.url)
          if (!url) {
            return textResult(
              "URL inválida. Necesito una URL http(s) de YouTube o un ID de vídeo de 11 caracteres.",
            )
          }
          const lang = String(args.lang ?? "en").trim()
          const signal = tctx?.signal

          // ── modo lista: tabla cruda de --list-subs ─────────────────────
          if (lang === "list") {
            const r = await runYtDlp(["--list-subs", url], signal)
            if (r.aborted) return textResult("Cancelado (AbortSignal).")
            if (!r.ok) return textResult(errorText(r))
            return textResult(cap(r.stdout || r.stderr, MAX_LIST_CHARS), { url, mode: "list" })
          }
          if (!LANG_RE.test(lang)) {
            return textResult(
              `lang inválido: "${lang.slice(0, 60)}". Códigos tipo "es", "pt-BR" o patrones tipo "en.*".`,
            )
          }

          // ── fetch de subtitles a tmp dir efímero por llamada ───────────
          mkdirSync(TMP_ROOT, { recursive: true })
          const dir = mkdtempSync(join(TMP_ROOT, "run-"))
          try {
            const r = await runYtDlp(
              [
                "--sub-format",
                "json3",
                "--skip-download",
                "--write-subs",
                "--write-auto-subs",
                "--sub-langs",
                lang,
                "-o",
                join(dir, "%(id)s"),
                url,
              ],
              signal,
            )
            if (r.aborted) return textResult("Cancelado (AbortSignal).")
            if (!r.ok) return textResult(errorText(r))

            const file = pickJson3(dir, lang)
            if (!file) {
              // exit 0 sin json3 = el lang pedido no existe → devolver la carta real
              const ls = await runYtDlp(["--list-subs", url], signal)
              const avail = ls.ok
                ? cap(ls.stdout || ls.stderr || "(sin salida)", MAX_LIST_CHARS)
                : `(no se pudo listar: ${errorText(ls)})`
              return textResult(`No hay subtítulos '${lang}' para ${videoId(url)}. Disponibles:\n${avail}`)
            }

            let doc: Json3Doc
            try {
              doc = JSON.parse(readFileSync(file, "utf8")) as Json3Doc
            } catch (e) {
              return textResult(
                `json3 ilegible (${e instanceof Error ? e.message : String(e)}). Archivo: ${file}`,
              )
            }
            const transcript = buildTranscript(doc)
            if (!transcript) {
              return textResult(`Subtítulos '${lang}' vacíos para ${videoId(url)} (sin líneas legibles).`)
            }
            let out = transcript
            if (out.length > MAX_TRANSCRIPT_CHARS) {
              out =
                out.slice(0, MAX_TRANSCRIPT_CHARS) +
                `\n\n(truncated at ${MAX_TRANSCRIPT_CHARS} of ${transcript.length} chars)`
            }
            return textResult(out, {
              id: videoId(url),
              lang,
              chars: out.length,
              total: transcript.length,
            })
          } finally {
            try {
              rmSync(dir, { recursive: true, force: true })
            } catch {
              /* best effort: TMP_ROOT es efímero */
            }
          }
        },
      })
    })

    console.log(`[yt-transcript] cargado (bin=${resolveYtDlp()}, tmp=${TMP_ROOT})`)
  },
})
