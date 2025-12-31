# OpenCode Agent Architecture 🧠

Este directorio contiene la configuración y construcción de agentes de IA avanzados para Platform Engineering y Desarrollo Backend.

## 🏗️ Arquitectura (The Builder Pattern)

No editamos los ficheros de configuración (`config.json`) ni los prompts de los agentes (`agent/*.md`) directamente en su ubicación final. Usamos un sistema de construcción en Go para inyectar secretos y componer los prompts de forma modular.

### Estructura de Directorios

- **`builder/`**: El corazón del sistema.
  - `main.go`: Script en Go que compila los templates.
  - `templates/`: Plantillas base para la configuración y los agentes.
    - `agent/`: Templates de los agentes (referencian a prompts comunes).
    - `config/`: Template del `config.json`.
- **`prompts/`**: Piezas reutilizables de prompts (Identidad, Comportamiento, Reglas) que se inyectan en los agentes.
- **`agent/`** (GitIgnored): Directorio de salida donde se generan los agentes finales.
- **`config.json`** (GitIgnored): Fichero de configuración final con secretos inyectados.

## 🚀 Cómo Desplegar (Setup)

Para generar la configuración y los agentes, necesitas ejecutar el builder.

### Prerrequisitos
1. **Go** instalado.
2. **Brave Search API Key** (Gratis). Consíguela en [brave.com](https://brave.com/search/api/).

### Pasos de Construcción

1. Exporta tu clave de API:
   ```bash
   export BRAVE_API_KEY="BSA-xxxxxxxxxxxxxxxxxxxx"
   ```

2. Ejecuta el builder:
   ```bash
   cd .config/opencode/builder
   go run main.go
   ```

3. ¡Listo! OpenCode ahora usará la configuración generada con soporte para búsqueda web y herramientas nativas.

## 🛠️ Capacidades

- **Context7**: Documentación profunda de librerías.
- **Brave Search**: Búsqueda en tiempo real de errores y versiones.
- **Filesystem & Shell**: Ejecución nativa de comandos (Go, Rust, Kubectl) restringida al entorno de usuario.

## ⚠️ Seguridad

- `config.json` y la carpeta `agent/` están en `.gitignore`.
- **NUNCA** subas tu `BRAVE_API_KEY` al repositorio.
