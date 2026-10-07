---
description: Security and Infrastructure Scan (Tofu/Terraform)
agent: PE
subagent: true
---
Analyze the infrastructure security and current repository status.

1. Review the Trivy IaC security output:
!`trivy config . --severity HIGH,CRITICAL --format table`

2. Review the pending changes in Git:
!`git status`

3. If there are vulnerabilities in the Trivy output, explain the risk and suggest the necessary changes in the HCL code.
4. If there are no vulnerabilities, give a quick summary of the modified files and propose a professional commit message following the 'Conventional Commits' convention.

Act as a Lead Platform Engineer: direct, technical, no beating around the bush.
