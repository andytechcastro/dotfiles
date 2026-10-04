# OpenCode Agent Architecture 🧠

Este directorio contiene la configuración y construcción de agentes de IA avanzados para Platform Engineering y Desarrollo Backend.

## 🏗️ Arquitectura (The Builder Pattern)

No editamos los ficheros de configuración (`config.json`) ni los prompts de los agentes (`agent/*.md`) directamente en su ubicación final. Usamos un sistema de construcción en Go para inyectar secretos y componer los prompts de forma modular.

### Estructura de Directorios

- **`builder/`**: El corazón del sistema.
  - `main.go`: Motor de construcción agnóstico. Reemplaza variables `${VAR}` y gestiona feature-flags (`_requires_env`).
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
2. **Variables de Entorno**: El builder detectará automáticamente qué servicios configurar basándose en las variables que exportes.

### Pasos de Construcción

1. Exporta tus claves (solo las que tengas):
   ```bash
   # Opcional: Búsqueda web nativa V2 (provider tavily; leída en runtime, no en config)
   export TAVILY_API_KEY="tvly-xxxxxxxx"
   
   # Opcional: Para integraciones Jira/Confluence
   export ATLASSIAN_API_TOKEN="tu-token"
   ```

2. Ejecuta el builder:
   ```bash
   cd .config/opencode/builder
   go run main.go
   ```

3. **Verificación**:
   - Si definiste la variable, el MCP correspondiente se activará (`✅ Requirements met`).
   - Si NO la definiste, el MCP se eliminará limpiamente del config (`🚫 Missing env`).

## 🛠️ Capacidades Dinámicas

El sistema soporta **Feature Toggling** basado en entorno.
En el template `config.json`, puedes definir dependencias así:

```json
"my-tool": {
    "type": "local",
    ...,
    "_requires_env": ["MY_API_KEY"]
}
```

Si `MY_API_KEY` no está en el entorno, `my-tool` desaparece del fichero final.

## ⚠️ Seguridad

- `config.json` y la carpeta `agent/` están en `.gitignore`.
- Los secretos **NUNCA** se commitean, se inyectan en tiempo de construcción.
