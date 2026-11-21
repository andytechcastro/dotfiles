{{INCLUDE:rule-language}}

## Binarios verificados en esta máquina (medidos 2026-11-20, `command -v` + `--version`)

| Binario | Ruta | Versión |
|---|---|---|
| go | /usr/bin/go | go1.27.4 linux/amd64 |
| node | /usr/bin/node | v26.13.1 (TypeScript strip: `node --experimental-strip-types` — sin bun ni deno) |
| trivy | /usr/bin/trivy | 0.76.2 (DB de vulnerabilidades cargada) |
| kubectl | /usr/bin/kubectl | presente |
| agy | /usr/bin/agy | 1.5.12 (auth: la del propietario, no de agente) |
| plannotator | /home/andres/.local/bin/plannotator | presente |

Herramientas de plataforma con ruta horneada: `/home/andres/Proyectos/dotfiles/.config/opencode/tool/`
(`hex_check.go`, `k8s-pod-doctor.ts`, `tofu-scan.ts`) — invocadas por los skills del plugin con
ruta absoluta.

## Presupuestos de prompt (medida en bytes planos tras el flatten de build.sh)

- Límites duros (enforcement en build): `agents/*.md` ≤ 24576 B/file; `rules/*.md` ≤ 6144 B/file.
- Convertible a tokens con ~4 B/token (estimación estable EN/ES, sin tokenizador dependiente):
  24576 B ≈ 6.1k tok · 6144 B ≈ 1.5k tok.
- Presupuesto agregado por agente activo (rules + agent) ≈ 20k tokens ≈ ~80 KB planos: muy por
  encima del peor caso structurally posible (6.1k+1.5k), por lo que las reglas de la SUITE (≈1.6k B)
  consumen ~0.4k tok — margen amplio para bodies de agentes grandes (coach ≈ 8.5k B ≈ 2.1k tok).
- Nota: la cuenta real de tokens de la API puede bajar con la compresión de contexto (squeez); no
  contar con ella — diseñar contra los límites planos de arriba.

## Seguridad de contenido

- Cero secretos, tokens o credenciales en rules y skills: nunca en este repo, nunca en dist/,
  nunca en la copia instalada bajo `~/.gemini/config/plugins/`.
- Este fichero NO define personas ni roles de comportamiento: eso vive en `agents/` (los agents
  del roster). Aquí solo hechos máquina-wide compartidos por todos los agentes.
