package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type Package struct {
	ImportPath string   `json:"ImportPath"`
	Imports    []string `json:"Imports"`
}

func main() {
	cmd := exec.Command("go", "list", "-json", "./...")
	output, err := cmd.Output()
	if err != nil {
		fmt.Printf("Error running go list: %v\n", err)
		os.Exit(1)
	}

	// go list -json ./... returns a sequence of JSON objects, not an array
	dec := json.NewDecoder(strings.NewReader(string(output)))
	var packages []Package
	for dec.More() {
		var p Package
		if err := dec.Decode(&p); err != nil {
			fmt.Printf("Error decoding JSON: %v\n", err)
			os.Exit(1)
		}
		packages = append(packages, p)
	}

	violations := []string{}

	for _, p := range packages {
		// Rule 1: Domain should not import anything from other layers
		if isLayer(p.ImportPath, "domain") || isLayer(p.ImportPath, "internal/domain") || isLayer(p.ImportPath, "entity") {
			for _, imp := range p.Imports {
				if isLayer(imp, "usecase") || isLayer(imp, "infrastructure") || isLayer(imp, "adapter") || isLayer(imp, "handler") {
					violations = append(violations, fmt.Sprintf("❌ Domain Violation: %s imports %s", p.ImportPath, imp))
				}
			}
		}

		// Rule 2: Usecase should not import infrastructure or adapters
		if isLayer(p.ImportPath, "usecase") || isLayer(p.ImportPath, "application") {
			for _, imp := range p.Imports {
				if isLayer(imp, "infrastructure") || isLayer(imp, "adapter") || isLayer(imp, "handler") {
					violations = append(violations, fmt.Sprintf("❌ Usecase Violation: %s imports %s", p.ImportPath, imp))
				}
			}
		}
	}

	if len(violations) == 0 {
		fmt.Println("✅ Hexagonal Architecture is clean!")
	} else {
		fmt.Println("⚠️  Architectural Violations Found:")
		for _, v := range violations {
			fmt.Println(v)
		}
		os.Exit(1)
	}
}

func isLayer(path string, layerName string) bool {
	parts := strings.Split(path, "/")
	for _, part := range parts {
		if part == layerName {
			return true
		}
	}
	return false
}
