---
name: infra-security-check
description: >-
  Use this skill before committing, applying or refactoring Infrastructure as
  Code (Terraform/OpenTofu: .tf, .tfvars) — it is the merged replacement of the
  former opencode skill infra-security-check and the /infra-scan command.
  Scans IaC with Trivy for HIGH/CRITICAL misconfigurations, reviews pending git
  changes, and either blocks on critical risk or proposes the HCL fix and a
  Conventional Commits message.
---

# Infra Security Check (Trivy IaC — merged with /infra-scan)

Fusion decision (F3): the old opencode skill and the `/infra-scan` command had
the same semantics (Trivy IaC over the repo + remediation); they ship as ONE
agy skill here. No opencode-only syntax (`!`cmd`` pre-runs, `$1` args) is used.

## Steps

1. Scan the IaC of the current directory:

   ```bash
   trivy config . --severity HIGH,CRITICAL --format table
   ```

   Use `--format json` when findings must be parsed programmatically.
2. Review pending changes for context:

   ```bash
   git status
   ```
3. If findings exist: explain each risk (what breaks, blast radius) and propose
   the corrected HCL (resource-by-resource diff, not vague advice).
4. If a CRITICAL finding exists: STOP — do not proceed to commit/apply until the
   user explicitly acknowledges the risk.
5. If clean: summarize the modified files and propose a professional commit
   message following Conventional Commits.

## Validation

- Exit code 0 with zero HIGH/CRITICAL findings = pass.
- Trivy DB freshness: `trivy --version` prints the DB date; if stale by days,
  run `trivy image --download-db-only` (network) before trusting a clean scan,
  and say so.
