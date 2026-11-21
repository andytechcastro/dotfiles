#!/usr/bin/env python3
"""Merge ACP bits into an opencode config (idempotent, atomic, V1- or V2-shaped).

Usage: pi-acp-merge.py <config-path>
Adds (if missing):
  - plugin pin: opencode-antigravity-acp@0.1.0  (exact pin; audit sha256
    715f4bdcd1b760b68f29f843151e8730aa00053379a22bc4f49bbf29dc3b207d)
  - tool.use floors protecting the agy OAuth token file (read/edit deny).
Writes <config-path>.bak-acp once (never overwrites an existing backup),
then replaces the file atomically with mode 0600. Prints a one-line report.
Exit 0 = changed or already-converged; 2 = config unreadable/invalid (no write).
"""
import json
import os
import sys
import tempfile

PLUGIN = "opencode-antigravity-acp@0.1.0"
FLOORS = [
    {"action": "read", "resource": "*antigravity-oauth-token*", "effect": "deny"},
    {"action": "edit", "resource": "*antigravity-oauth-token*", "effect": "deny"},
]
# If the config whitelists providers via experimental.policies (deny "*"
# catch-all), the ACP provider is filtered out of the catalog and every
# antigravity-acp model silently degrades to the instance default. Measured
# on the Pi 2026-11-21 (bisect: real config -> 0 models, minimal -> 9).
POLICY_ALLOW = {"action": "provider.use", "resource": "antigravity-acp", "effect": "allow"}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: pi-acp-merge.py <config-path>", file=sys.stderr)
        return 2
    path = os.path.abspath(sys.argv[1])
    try:
        with open(path, encoding="utf-8") as fh:
            cfg = json.load(fh)
        if not isinstance(cfg, dict):
            raise ValueError("top-level is not an object")
    except (OSError, ValueError) as exc:
        print(f"REFUSED: cannot parse {path}: {exc}", file=sys.stderr)
        return 2

    changed = []
    plugins = cfg.get("plugin")
    if not isinstance(plugins, list):
        plugins = []
    if PLUGIN not in plugins:
        plugins.append(PLUGIN)
        cfg["plugin"] = plugins
        changed.append("plugin pin added")

    tool = cfg.get("tool")
    if not isinstance(tool, dict):
        tool = {}
    use = tool.get("use")
    if not isinstance(use, list):
        use = []
    have = {(r.get("action"), r.get("resource")) for r in use if isinstance(r, dict)}
    added = [f for f in FLOORS if (f["action"], f["resource"]) not in have]
    if added:
        use.extend(added)
        tool["use"] = use
        cfg["tool"] = tool
        changed.append(f"{len(added)} floors added")

    # Provider whitelist compatibility (see POLICY_ALLOW note above).
    exp = cfg.get("experimental")
    if isinstance(exp, dict) and isinstance(exp.get("policies"), list):
        policies = exp["policies"]
        deny_all = any(
            p.get("action") == "provider.use" and p.get("resource") == "*"
            and p.get("effect") == "deny"
            for p in policies if isinstance(p, dict)
        )
        has_allow = any(p == POLICY_ALLOW for p in policies if isinstance(p, dict))
        if deny_all and not has_allow:
            policies.append(POLICY_ALLOW)
            changed.append("policy allow antigravity-acp added")

    if not changed:
        print("already converged: plugin pin + floors present")
        return 0

    bak = path + ".bak-acp"
    if not os.path.exists(bak):
        with open(path, "rb") as src, open(bak, "wb") as dst:
            dst.write(src.read())
        os.chmod(bak, 0o600)

    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".acp-", suffix=".json")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(cfg, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        print("REFUSED: atomic write failed", file=sys.stderr)
        return 2

    print("merged: " + "; ".join(changed) + f" (backup: {bak})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
