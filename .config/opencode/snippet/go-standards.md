Follow Go best practices:
- Always handle errors explicitly, use error wrapping: `fmt.Errorf("context: %w", err)`
- Use `PascalCase` for exports, `camelCase` for locals
- Avoid package-level state, use structs and methods
- Standard library first, avoid external deps unless necessary
- Group imports: stdlib first, then external
