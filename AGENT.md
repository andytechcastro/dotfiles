# 🤖 Agentes IA - OpenCode

Este documento describe los roles especializados disponibles en tu entorno OpenCode. Cada agente está diseñado para una fase específica del ciclo de desarrollo.

---

## 🏗️ Platform Engineering (PE)

El núcleo de tu productividad. Agentes para infraestructura, despliegue y planificación.

### `PE_plan` (Default)
**Rol:** Arquitecto Estratégico

- **Uso:** Análisis inicial, descomposición de tareas complejas en pasos atómicos (ToDos).
- **Herramientas:** TodoWrite, Read (Contexto).
- **Filosofía:** *"Weeks of coding can save you hours of planning"*. No ejecuta código, solo piensa.

### `PE_build`
**Rol:** Ejecutor Táctico

- **Uso:** Implementación paso a paso del plan trazado.
- **Herramientas:** Bash, Filesystem, Git.
- **Filosofía:** Ejecución secuencial, testeo inmediato tras cada cambio.

### `PE` (General)
**Rol:** Ingeniero Full-Stack / Platform

- **Uso:** Consultas generales, debugging, operaciones rápidas.
- **Capacidades:** Kubernetes, GCP, Terraform, Scripting, Docker.

---

## 👨‍💻 Arquitectos de Lenguaje

Especialistas verticales con conocimiento profundo de idiomatismos y patrones de diseño específicos.

### `go_architect`
**Perfil:** Senior Go Developer & GDE

- **Enfoque:** Clean Architecture, concurrencia (goroutines/channels), optimización.
- **Estilo:** Idiomático, estricto con el manejo de errores (`if err != nil`), prefiere standard library sobre frameworks pesados.
- **Stack:** Gin/Chi, Gorm/Sqlc, Docker.

### `python_architect`
**Perfil:** Python Senior Architect

- **Enfoque:** Type Hinting estricto (Pydantic), rendimiento, escalabilidad.
- **Estilo:** Zen of Python, PEP-8 riguroso, asíncrono (asyncio/FastAPI).
- **Stack:** FastAPI, Pandas, SQLAlchemy, Pytest.

---

## 🔄 Flujo de Trabajo Recomendado

```
┌─────────────────────────────────────────────────────────┐
│  1. PLANIFICAR                                           │
│     PE_plan → Descomposición en ToDos                   │
│     "Quiero migrar el servicio de usuarios a Go"        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  2. CONSTRUIR                                            │
│     PE_build / go_architect → Ejecución del plan        │
│     Testeo inmediato tras cada paso                     │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  3. DESPLEGAR                                            │
│     PE → K8s, Terraform, GCP                            │
└─────────────────────────────────────────────────────────┘
```

---

## ⚙️ Configuración

Los agentes se generan mediante el **Builder Pattern** en `.config/opencode/builder/`.

```bash
# Regenerar agentes con secretos inyectados
cd .config/opencode/builder
go run main.go
```

**Nota:** `config.json` y `agent/` están en `.gitignore` por seguridad.

---

## 🛠️ MCPs Disponibles

| Servicio | Variable Requerida | Función |
|----------|-------------------|---------|
| Brave Search | `BRAVE_API_KEY` | Búsqueda web |
| Atlassian | `ATLASSIAN_API_TOKEN` | Jira/Confluence |
| Context7 | Auto | Docs de librerías |

El builder activa/desactiva MCPs automáticamente según las variables de entorno definidas.
