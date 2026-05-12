---
name: hexagonal-architect
description: Enforces Hexagonal Architecture rules in Go projects. Proactively checks for forbidden imports between layers.
license: Apache-2.0
---

## What I do
- Monitors Go code changes to ensure Domain and Usecase layers remain pure.
- Uses `hexagonal-validator` to detect dependency violations.
- Guides the developer on how to decouple code when a violation is found (e.g., using interfaces/dependency inversion).

## When to use me
Use this skill whenever Go files are modified in a project that contains folders like `internal/domain`, `internal/usecase`, or `internal/infrastructure`.

## Instructions
1. If Go files are edited, run `hexagonal-validator`.
2. If violations are reported, explain the Hexagonal Architecture principle being broken.
3. Suggest a refactor (e.g., "Define an interface in the usecase layer and implement it in infrastructure") to fix the dependency direction.
