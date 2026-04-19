
import { tool } from "@opencode-ai/plugin"

const SKILL = `
---
name: hexagonal-validator
description: Validates Go projects for Hexagonal Architecture (Clean Architecture) violations. It checks that dependencies flow inwards (Domain -> Usecase -> Infrastructure).
license: Apache 2.0
---

## When to use this tool

Use this tool when working on Go projects that follow Hexagonal or Clean Architecture. Run it during code reviews or after refactoring to ensure architectural integrity.

## How to use this tool

Just call the tool in a Go project root. It will analyze all subpackages.

### Examples

\`\`\`bash
hexagonal-validator
\`\`\`
`;

export default tool({
  description: SKILL,
  args: {},
  async execute(args) {
    try {
      // Run the Go script we just created
      const result = await Bun.$`go run .config/opencode/tool/hex_check.go`.text()
      return result.trim()
    } catch (error) {
      // If violations are found, the Go script exits with 1, which Bun.$ catches as an error
      if (error.stdout) {
          return error.stdout.toString().trim()
      }
      return `❌ Error running hexagonal-validator: ${error.message}`
    }
  },
})
