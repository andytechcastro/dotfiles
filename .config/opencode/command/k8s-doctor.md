---
description: Diagnóstico profundo de un Pod de Kubernetes
agent: PE_build
---
Usa la herramienta `k8s-pod-doctor` para analizar el estado del pod `$1`. 

Si se proporciona un segundo argumento (`$2`), úsalo como el namespace. Si no, deja que la herramienta use el namespace actual.

Analiza el reporte generado por el doctor y:
1. Explica de forma clara y directa cuál es el problema.
2. Si es un fallo de infraestructura (recursos, red, imagen), propón el cambio necesario en el manifiesto de Kubernetes.
3. Si parece un fallo de la aplicación, sugiere qué buscar en los logs.

Recuerda: eres un Lead Platform Engineer. No pierdas el tiempo con explicaciones obvias, ve directo al grano técnico.
