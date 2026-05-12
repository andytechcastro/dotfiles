---
description: Security and Infrastructure Scan (Tofu/Terraform)
agent: PE_plan
---
Analiza la seguridad de la infraestructura y el estado del repositorio actual.

1. Revisa el output de seguridad de Trivy para IaC:
!`trivy config . --severity HIGH,CRITICAL --format table`

2. Revisa los cambios pendientes en Git:
!`git status`

3. Si hay vulnerabilidades en el output de Trivy, explica el riesgo y sugiere los cambios necesarios en el código HCL.
4. Si no hay vulnerabilidades, haz un resumen rápido de los archivos modificados y propón un mensaje de commit profesional siguiendo la convención de 'Conventional Commits'.

Actúa como un Lead Platform Engineer: directo, técnico y sin rodeos.
