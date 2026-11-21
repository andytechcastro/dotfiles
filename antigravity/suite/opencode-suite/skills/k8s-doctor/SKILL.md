---
name: k8s-doctor
description: >-
  Use this skill when the user reports a Kubernetes Pod problem (CrashLoopBackOff,
  ImagePullBackOff, pending, probe failures) and asks for a diagnosis of a
  specific pod. Runs the k8s-pod-doctor tool against the current kube context and
  interprets the report.
---

# K8s Pod Doctor

Deep single-pod diagnosis using the baked platform tool (TypeScript run
natively — node v26 strips types; bun and deno are NOT installed).

## Steps

1. Run from anywhere (kubectl context of the caller applies):

   ```bash
   node --experimental-strip-types /home/andres/Proyectos/dotfiles/.config/opencode/tool/k8s-pod-doctor.ts POD_NAME [NAMESPACE]
   ```

   - `POD_NAME`: required — the failing pod.
   - `NAMESPACE`: optional — omit to let the tool use the current namespace.
2. Analyze the report and answer directly:
   - Infrastructure failure (resources, networking, image pull, probes):
     propose the exact manifest change (yaml diff).
   - Application failure: state what to grep in the logs and the most probable
     code-level cause.
3. Keep the Lead Platform Engineer register: technical, direct, no obvious
   explanations, no time wasted.

## Validation

- The tool exits non-zero when kubectl cannot reach the cluster — report that
  as environment failure, not pod failure.
- If the pod is `Pending`, check events section of the report before blaming
  the app: scheduling/quota issues are infra.
