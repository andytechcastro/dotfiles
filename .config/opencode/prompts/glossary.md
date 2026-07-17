# Architecture Glossary

Use these terms consistently. Don't reinvent definitions in each agent.

## Clean Architecture
Uncle Bob's layered model: Entities (business rules) → Use Cases (application rules) → Interface Adapters → Frameworks & Drivers. **Dependency rule**: dependencies point INWARD. Outer layers know inner; inner knows nothing of outer.

## Hexagonal Architecture (Ports & Adapters)
Same dependency rule as Clean Arch, framed differently. **Driving adapters** (REST, CLI, gRPC) call **ports** (interfaces defined by the domain). **Driven adapters** (DB, message queue, external API) IMPLEMENT the ports. Domain core is the hexagon — has no outward dependencies.

## Screaming Architecture
The directory structure of a NEW project should SCREAM what the system does (its business domain), not what framework it uses. e.g., `internal/billing/`, `internal/claims/` — not `internal/controllers/`, `internal/models/`. Uncle Bob's principle.

## Package by Feature (Vertical Slice)
Files grouped by BUSINESS FEATURE, not technical role. `internal/users/handler.go`, `internal/users/service.go`, `internal/users/repository.go`, `internal/users/model.go`. High cohesion within feature, low coupling between features.

## Package by Layer (Classic Clean Arch)
Files grouped by TECHNICAL ROLE. `internal/handler/users.go`, `internal/usecase/users.go`, `internal/adapter/users_repo.go`, `internal/domain/user.go`. Clear separation, but features scattered across folders.

## 12-Factor App
Methodology for SaaS apps. Twelve rules: codebase, dependencies, config, backing services, build/release/run, processes, port binding, concurrency, disposability, dev/prod parity, logs, admin processes. https://12factor.net

## Driving vs Driven Adapters
- **Driving adapter**: initiates action (REST handler calls use case). "Calls the domain."
- **Driven adapter**: reacts to domain requests (repository impl called by use case). "Called by the domain."

## God Node
In a knowledge graph (e.g., graphify), a node with very high connectivity — usually a sign of over-centralization (a file/type/function that everything depends on). Fix by splitting responsibilities.
