# Agentes Disponibles 🤖

Estos son los roles especializados disponibles en tu entorno OpenCode. Cada uno está diseñado para una fase específica del ciclo de desarrollo.

## 🏗️ Platform Engineering (PE)

El núcleo de tu productividad. Estos agentes gestionan la infraestructura, el despliegue y la planificación.

### `PE_plan` (Default)
**Rol:** Arquitecto Estratégico.
- **Uso:** Análisis inicial, descomposición de tareas complejas en pasos atómicos (ToDos).
- **Herramientas:** TodoWrite, Read (Contexto).
- **Filosofía:** "Weeks of coding can save you hours of planning". No ejecuta código, solo piensa.

### `PE_build`
**Rol:** Ejecutor Táctico.
- **Uso:** Implementación paso a paso del plan trazado.
- **Herramientas:** Bash, Filesystem, Git.
- **Filosofía:** Ejecución secuencial, testeo inmediato tras cada cambio.

### `PE` (General)
**Rol:** Ingeniero Full-Stack / Platform.
- **Uso:** Consultas generales, debugging, operaciones rápidas.
- **Capacidades:** Kubernetes, GCP, Terraform, Scripting.

## 👨‍💻 Arquitectos de Lenguaje

Especialistas verticales con conocimiento profundo de idiomatismos y patrones de diseño específicos.

### `go_architect`
**Perfil:** Senior Go Developer & GDE.
- **Enfoque:** Clean Architecture, concurrencia (goroutines/channels), optimización.
- **Estilo:** Idiomático, estricto con el manejo de errores (`if err != nil`), prefiere standard library sobre frameworks pesados.
- **Stack:** Gin/Chi, Gorm/Sqlc, Docker.

### `python_architect`
**Perfil:** Python Senior Architect.
- **Enfoque:** Type Hinting estricto (Pydantic), rendimiento, escalabilidad.
- **Estilo:** Zen of Python, PEP-8 riguroso, asíncrono (asyncio/FastAPI).
- **Stack:** FastAPI, Pandas, SQLAlchemy, Pytest.

## 🔄 Flujo de Trabajo Recomendado

1. **Planificar:** Inicia con `PE_plan` para romper la tarea: "Quiero migrar el servicio de usuarios a Go".
2. **Construir:** Cambia a `PE_build` o `go_architect` para ejecutar los pasos del TodoList generado.
3. **Desplegar:** Usa `PE` para operaciones de Kubernetes/Terraform.
