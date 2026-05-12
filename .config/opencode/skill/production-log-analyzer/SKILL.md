---
name: production-log-analyzer
description: Proactively fetches and analyzes production error logs from Datadog when investigating service-related issues.
license: Apache-2.0
---

## What I do
- Automatically triggers `dd-logs` when the user mentions a bug, a failure, or a specific service behavior in production.
- Correlates stack traces from logs with the local codebase to pinpoint the exact line of failure.
- Provides a summary of the impact (frequency of errors, unique error messages).

## When to use me
Use this skill autonomously whenever a service name is mentioned in the context of an "issue", "bug", "crash", or "error". Do NOT wait for the user to ask for logs.

## Instructions
1. If an issue is reported for service X, immediately run `dd-logs --service X`.
2. If the logs contain a stack trace, use `rg` or `mgrep` to find the relevant code in the current repository.
3. Present the findings by linking the production error to the specific code block.
