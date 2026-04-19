
import { tool } from "@opencode-ai/plugin"

const SKILL = `
---
name: k8s-pod-doctor
description: A cluster-aware diagnostic tool for Kubernetes pods. Analyzes pods by checking state, recent events, and logs while verifying the current context and namespace.
license: Apache 2.0
---

## When to use this tool

Use this tool whenever a pod is misbehaving (CrashLoopBackOff, OOMKilled, etc.). It works across multiple clusters if you use kubectx/kubens.

## How to use this tool

Provide the pod name. If no namespace is provided, it uses the current one from kubens.

### Examples

\`\`\`bash
# Diagnose in current context and current namespace
k8s-pod-doctor my-app-xyz

# Diagnose in a specific namespace
k8s-pod-doctor my-app-xyz -n staging
\`\`\`
`;

export default tool({
  description: SKILL,
  args: {
    podName: tool.schema.string().describe("The name of the pod to diagnose."),
    namespace: tool.schema.string().optional().describe("Namespace to use. Defaults to current kubens context."),
  },
  async execute(args) {
    const { podName, namespace } = args;
    
    try {
      // 1. Identify Environment
      const currentCtx = (await Bun.$`kubectx -c`.text()).trim();
      const currentNs = namespace || (await Bun.$`kubens -c`.text()).trim();
      
      let report = `🩺 **Diagnosis for Pod:** \${podName}\n`;
      report += `🌐 **Context:** \${currentCtx} | **Namespace:** \${currentNs}\n`;
      report += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;

      // 2. Get Pod Details
      const podInfoRaw = await Bun.$`kubectl get pod \${podName} -n \${currentNs} -o json`.text();
      const podInfo = JSON.parse(podInfoRaw);
      const status = podInfo.status;
      const containerStatus = status.containerStatuses ? status.containerStatuses[0] : {};
      
      report += `**Phase:** \${status.phase}\n`;
      report += `**State:** \${JSON.stringify(containerStatus.state || "Unknown")}\n`;
      report += `**Restarts:** \${containerStatus.restartCount || 0}\n\n`;

      // 3. Get Recent Events (Filtered for this pod)
      report += `⚠️ **Recent Warning Events:**\n`;
      const events = await Bun.$`kubectl get events -n \${currentNs} --field-selector involvedObject.name=\${podName} --sort-by='.lastTimestamp'`.text();
      report += events.trim() || "No recent events found.";
      report += "\n\n";

      // 4. Get Logs (Last 20 lines)
      report += `📋 **Last 20 Log Lines:**\n`;
      try {
        const logs = await Bun.$`kubectl logs \${podName} -n \${currentNs} --tail=20`.text();
        report += logs.trim() || "No logs available.";
      } catch (e) {
        report += "Could not retrieve logs (Pod might not be in a loggable state).";
      }
      
      // 5. Smart Analysis
      report += "\n\n🔍 **Doctor's Note:**\n";
      const stateStr = JSON.stringify(containerStatus);
      if (stateStr.includes("OOMKilled")) {
        report += "-> Pod was **OOMKilled**. You need to increase memory limits in the manifest.\n";
      } else if (stateStr.includes("ImagePullBackOff")) {
        report += "-> **ImagePullBackOff**. Check the image name, tag, or registry credentials.\n";
      } else if (status.phase === "Pending") {
        report += "-> Pod is **Pending**. Check for node resource exhaustion or unschedulable nodes.\n";
      } else {
        report += "-> No obvious platform-level failure. Check application-level logs for bugs.\n";
      }

      return report;
    } catch (error) {
      return `❌ Error diagnosing pod \${podName}: \${error.message}`;
    }
  },
})
