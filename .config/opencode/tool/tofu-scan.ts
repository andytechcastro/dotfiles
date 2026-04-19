
import { tool } from "@opencode-ai/plugin"

const SKILL = `
---
name: tofu-scan
description: A security scanner for OpenTofu and Terraform configurations using Trivy. It detects misconfigurations and security vulnerabilities in your IaC.
license: Apache 2.0
---

## When to use this tool

Use this tool whenever you are working with OpenTofu or Terraform files (.tf, .tfvars). It is essential to run it before committing changes to ensure no security regressions are introduced.

## How to use this tool

The tool scans a directory (defaulting to the current one) and reports vulnerabilities based on the specified severity levels.

### Examples

\`\`\`bash
# Scan current directory for High and Critical issues
tofu-scan

# Scan a specific directory
tofu-scan path/to/infra

# Scan only for Critical issues
tofu-scan --severity CRITICAL
\`\`\`

## Expected Output
A summary of found vulnerabilities, including the ID, title, and a brief description of the risk.
`;

export default tool({
  description: SKILL,
  args: {
    path: tool.schema.string().default(".").describe("The directory to scan for IaC configurations."),
    severity: tool.schema.string().default("HIGH,CRITICAL").describe("Comma-separated list of severities to report (UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL)."),
  },
  async execute(args) {
    try {
      // We use trivy config which is optimized for IaC scanning
      const result = await Bun.$`trivy config ${args.path} --severity ${args.severity} --format table`.text()
      
      if (!result.trim() || result.includes("No issues found")) {
        return "✅ No security vulnerabilities found in the IaC configuration."
      }
      
      return result.trim()
    } catch (error) {
      return `❌ Error running trivy-scan: ${error.message}`
    }
  },
})
