# Subagent Permission Rules (DRY — included by all 6 sub-agents)

These rules are evaluated FIRST (deny-first model). After denies, `"*": allow` is the catch-all for everything else.

```yaml
permission:
  bash:
    # --- Destructive operations (ALWAYS DENY) ---
    "rm -rf /": deny
    "rm -rf *": deny
    "rm -rf /*": deny
    "mkfs*": deny
    "dd *": deny
    "sudo rm*": deny
    "chmod -R 777 /": deny
    # --- Git write operations (sub-agents are read-only on git) ---
    "git add*": deny
    "git commit*": deny
    "git push*": deny
    "git pull*": deny
    "git merge*": deny
    "git rebase*": deny
    "git reset*": deny
    "git checkout*": deny
    "git stash*": deny
    "git cherry-pick*": deny
    # --- Network (no outbound from sub-agents) ---
    "curl*": deny
    "wget*": deny
    "nc*": deny
    # --- macOS security ---
    "security*": deny
    "sysctl*": deny
    # --- Catch-all: everything else allowed ---
    "*": allow
```

NOTE: Sub-agents can READ git (`git status`, `git diff`, `git log`, etc.) — only writes are denied. Sub-agents can also build, test, edit files, run scripts, and use all CLI tools. The denies are for safety against accidental destructive actions, not for sandboxing.
