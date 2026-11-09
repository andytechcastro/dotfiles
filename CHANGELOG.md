# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Elephant-Goldfish Model (EGM) Adversarial Spec Review Protocol**: Codified adversarial review mechanism in Phase 1.5 across `prompts/subagent_behavior.md`, `prompts/commander_behavior.md`, `AGENTS.md`, and ADR 0003. Subagents act as hostile Goldfish critics enforcing a mandatory 3-section contract:
  - (A) Challenged Assumptions & Unstated Invariants (minimum 1 invariant attacked).
  - (B) Concrete Failure Modes (minimum 2-3 grounded failure cascades with `Trigger -> Failure Cascade -> Blast Radius`).
  - (C) Probing Architectural Questions & Trade-offs (partitioned into C.1 Technical Invariants for RFC and C.2 Product/Risk Decisions escalated to user via `question`).
  - Structured Verdicts: `BLOCKED`, `CHALLENGED`, or `CERTIFIED_WITH_MITIGATIONS` (unconditional approvals prohibited).
- **Anti-Sycophancy Rejection Gate**: Mandated Commander actively reject passive "looks good" or rubber-stamped approvals, demanding an adversarial audit before Phase 2 master planning.
- **Subagent Leaf Execution Hardening**: Enforced explicit runtime denies for child subagent spawning (`action: subagent`, `action: task`) and outbound web search (`action: websearch`) across all technical subagent templates.
- **Native Agent Policy**: Explicitly disabled unspecialized fallback agents (`general`, `build`, `plan`) in `config.json` while pinning `explore` and `title` to `{{MODEL:small_model}}`.
- **ADR 0003**: Accepted formal Architecture Decision Record `docs/adr/0003-elephant-goldfish-adversarial-review-protocol.md`.

### Changed
- Refactored and aligned Phase 1.5 and Phase 4 protocols across technical specialist behaviors (`pe_behavior.md`, `go_architect_behavior.md`, `python_architect_behavior.md`, `frontend_behavior.md`, `qa_behavior.md`, `security_behavior.md`, `doc_behavior.md`).
- Clarified planning authorization boundaries in `behavior.md` and Plannotator constraints in `_installed_capabilities.md` (mandatory Spanish invariant, final plan submissions only).
