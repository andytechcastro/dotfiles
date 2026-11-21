---
name: hexagonal-architect
description: >-
  Use this skill when Go files are created or modified in a project that has
  Hexagonal/Clean Architecture layers (folders like internal/domain,
  internal/usecase, internal/adapter, internal/infrastructure). It enforces
  dependency direction by detecting forbidden imports between layers.
---

# Hexagonal Architect (Go import-boundary enforcement)

Verifies that the domain and use-case layers never import infrastructure code,
and guides the refactor when a violation appears.

## Steps

1. From the ROOT of the Go module being worked on (not from the plugin repo), run:

   ```bash
   go run /home/andres/Proyectos/dotfiles/.config/opencode/tool/hex_check.go
   ```

   The tool scans the current working tree, so the absolute path to the tool is
   fine while the cwd must be the target project root.
2. If violations are reported: name the exact hexagonal principle broken
   (dependency inversion: domain must not depend on adapters/infrastructure).
3. Propose the concrete decoupling: define the port (interface) in the
   `usecase`/`domain` layer, implement it in the adapter layer, inject at the
   composition root (`cmd/` or `registry/`).
4. Re-run step 1 until it exits clean. A failing hex check fails the task.

## Notes

- Conditional path: if the target project ships its own validator
  (`.config/opencode/tool/hex_check.go` or `tool/hexagonal-validator.ts` inside
  that repo), prefer the local copy — the baked absolute path is the fallback
  and works from any project root.
- New in-repo copies of Go skills for OTHER machines do not exist yet: this
  skill is machine-specific by design (roster vivo dotfiles).
