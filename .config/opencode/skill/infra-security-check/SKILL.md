---
name: infra-security-check
description: Automatically validates Infrastructure as Code (Terraform/OpenTofu) for security vulnerabilities using Trivy.
license: Apache-2.0
compatibility: opencode
---

## What I do
- Scans Terraform/OpenTofu files for security misconfigurations.
- Identifies HIGH and CRITICAL vulnerabilities.
- Proposes secure alternatives for identified issues.

## When to use me
Use this skill whenever you are about to commit, apply, or refactor Infrastructure as Code (IaC) files (.tf, .tfvars).

## Instructions
1. Run `trivy config . --severity HIGH,CRITICAL --format json`.
2. If vulnerabilities are found, analyze the findings and present them to the user.
3. Suggest the corrected HCL code to mitigate the risk.
4. Stop execution if a critical risk is found until the user acknowledges it.
