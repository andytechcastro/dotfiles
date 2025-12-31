package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// Config holds the paths relative to the builder directory
const (
	TemplatesDir = "templates"
	PromptsDir   = "../prompts" // Relative to builder/
	OutputDir    = "../"        // Relative to builder/ (.config/opencode/)
)

func main() {
	// Ensure we are in the correct directory (optional check, but good for safety)
	cwd, _ := os.Getwd()
	fmt.Printf("🚀 Starting OpenCode Builder in: %s\n", cwd)

	// 1. Process Agents
	err := processAgents()
	if err != nil {
		fmt.Printf("❌ Error processing agents: %v\n", err)
		os.Exit(1)
	}

	// 2. Process Config
	err = processConfig()
	if err != nil {
		fmt.Printf("❌ Error processing config: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Build completed successfully!")
}

func processAgents() error {
	agentTemplatesDir := filepath.Join(TemplatesDir, "agent")
	outputAgentDir := filepath.Join(OutputDir, "agent")

	// Create output dir if not exists
	if err := os.MkdirAll(outputAgentDir, 0755); err != nil {
		return err
	}

	files, err := ioutil.ReadDir(agentTemplatesDir)
	if err != nil {
		return err
	}

	// Regex to match {file:path/to/file}
	// We want to capture the path inside
	re := regexp.MustCompile(`\{file:([^}]+)\}`)

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		fmt.Printf("🔨 Building Agent: %s\n", file.Name())

		content, err := ioutil.ReadFile(filepath.Join(agentTemplatesDir, file.Name()))
		if err != nil {
			return err
		}

		// Replace function
		newContent := re.ReplaceAllStringFunc(string(content), func(match string) string {
			// Extract path from {file:path}
			refPath := strings.TrimSuffix(strings.TrimPrefix(match, "{file:"), "}")

			// Handle absolute vs relative paths
			// In the templates, we will use relative paths to PROMPTS directory
			// e.g. ../prompts/identity.md

			// Resolve the absolute path of the referenced file
			// We assume the reference is relative to the config root or builder root.
			// Let's assume standardizing on paths relative to .config/opencode/

			var absPath string
			// Handle both absolute paths (starting with /) and relative paths
			if filepath.IsAbs(refPath) {
				absPath = refPath
			} else {
				// Resolve relative to the template file location? Or fixed prompts dir?
				// Let's implement a smart resolver.
				// If it starts with ../prompts, we know where it is.
				// We are in builder/templates/agent.
				// ../prompts in the file means it wants to go up one level from opencode/agent

				// However, let's fix the resolution to be robust.
				// We will look for the file relative to the project root or PromptsDir

				// If path contains "prompts/", look in PromptsDir
				if strings.Contains(refPath, "prompts/") {
					// Normalize path to just filename if needed or keep subpath
					_, fname := filepath.Split(refPath)
					absPath = filepath.Join(PromptsDir, fname)
				} else {
					// Fallback: try to resolve relative to current directory
					absPath = refPath
				}
			}

			// Read referenced file
			refContent, err := ioutil.ReadFile(absPath)
			if err != nil {
				fmt.Printf("   ⚠️  Warning: Could not read included file '%s' (resolved: %s): %v\n", refPath, absPath, err)
				return match // Return original string if fail
			}

			// Return content of referenced file
			return string(refContent)
		})

		// Write to output
		err = ioutil.WriteFile(filepath.Join(outputAgentDir, file.Name()), []byte(newContent), 0644)
		if err != nil {
			return err
		}
	}
	return nil
}

func processConfig() error {
	configTemplate := filepath.Join(TemplatesDir, "config", "config.json")
	outputConfig := filepath.Join(OutputDir, "config.json")

	fmt.Printf("🔧 Building Config: config.json\n")

	content, err := ioutil.ReadFile(configTemplate)
	if err != nil {
		return err
	}

	// Targeted replacement to avoid nuking $schema or other JSON fields
	// We only replace variables that we explicitly know about.
	varsToReplace := []string{
		"ATLASSIAN_DOMAIN",
		"ATLASSIAN_EMAIL",
		"ATLASSIAN_API_TOKEN",
		"BRAVE_API_KEY",
	}

	newContentStr := string(content)
	missingVars := []string{}

	for _, v := range varsToReplace {
		val := os.Getenv(v)
		if val == "" {
			missingVars = append(missingVars, v)
			// Don't replace if empty? Or replace with empty string?
			// Replacing with empty might break JSON syntax if it's inside quotes ""
			// but keeping ${VAR} is also invalid JSON usually.
			// Let's replace with empty string but warn.
		}
		// Replace ${VAR}
		newContentStr = strings.ReplaceAll(newContentStr, "${"+v+"}", val)
		// Replace $VAR (just in case used without braces)
		newContentStr = strings.ReplaceAll(newContentStr, "$"+v, val)
	}

	if len(missingVars) > 0 {
		fmt.Printf("   ⚠️  Warning: The following environment variables are missing: %v\n", missingVars)
		fmt.Printf("       Generated config.json will have empty values for these fields.\n")
	}

	err = ioutil.WriteFile(outputConfig, []byte(newContentStr), 0644)
	if err != nil {
		return err
	}

	fmt.Println("   🔒 Secrets injected (targeted replacement)")
	return nil
}
