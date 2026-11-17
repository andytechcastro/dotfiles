package main

import (
	"maps"
	"strconv"
	"strings"
	"testing"
)

// TestValidateModelValue covers the shape + allowlist contract for every
// {{MODEL:key}} value in an active profile. Each case pins one measured or
// plausible silent-failure mode of the raw textual substitution.
func TestValidateModelValue(t *testing.T) {
	tests := []struct {
		name    string
		value   string
		wantErr string // empty means must pass; else substring of the error
	}{
		// Contract F — required cases
		{"valid gateway with variant", "opencode-go/gemini-4-argon#medium", ""},
		{"valid gateway bare (no variants exposed — must stay bare)", "opencode-go/mimo-v2.6-flash", ""},
		{"reject space before hash (js-yaml comment trap)", "opencode-go/gemini-4-argon #medium", "WHITESPACE"},
		{"reject value starting with hash", "#medium", "HASH_FIRST"},
		{"reject double hash", "opencode-go/a#b#c", "MULTI_HASH"},
		{"reject empty value", "", "EMPTY_VALUE"},

		// Additional shape violations
		{"reject missing slash", "opencode-go", "MISSING_SEGMENT"},
		{"reject empty model segment", "opencode-go/#medium", "EMPTY_SEGMENT"},
		{"reject empty variant segment", "opencode-go/a#", "EMPTY_SEGMENT"},
		{"reject empty after slash", "opencode-go/", "MISSING_SEGMENT"},
		{"reject empty provider", "/model", "MISSING_SEGMENT"},
		{"reject trailing whitespace", "opencode-go/qwen3.8-flash ", "WHITESPACE"},
		{"reject embedded newline", "opencode-go/qwen3.8-flash\n", "WHITESPACE"},
		{"reject illegal characters", "opencode-go/qwen$flash", "ILLEGAL_CHARACTERS"},
		{"reject slash in variant", "opencode-go/a#b/c", "ILLEGAL_CHARACTERS"},

		// Allowlist policy
		{"reject non-allowlisted provider", "google/gemini-4-hydrogen", "PROVIDER_NOT_ALLOWLISTED"},
		{"reject lookalike provider prefix", "opencode-goX/model", "PROVIDER_NOT_ALLOWLISTED"},

		// Valid charset corners
		{"accept dots, dashes, digits", "opencode-go/gpt-6-luna#none", ""},
		{"accept numeric-ish model", "opencode-go/42", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateModelValue("testkey", tt.value)
			if tt.wantErr == "" {
				if err != nil {
					t.Fatalf("validateModelValue(%q) = unexpected error: %v", tt.value, err)
				}
				return
			}
			if err == nil {
				t.Fatalf("validateModelValue(%q) = nil, want error containing %q", tt.value, tt.wantErr)
			}
			if !strings.Contains(err.Error(), tt.wantErr) {
				t.Fatalf("validateModelValue(%q) = %v, want error containing %q", tt.value, err, tt.wantErr)
			}
			// Error must name the key and quote the value (contract B).
			// The emitter uses %q, so compare against the escaped form.
			if !strings.Contains(err.Error(), `"testkey"`) || !strings.Contains(err.Error(), strconv.Quote(tt.value)) {
				t.Fatalf("error must name key and quoted value, got: %v", err)
			}
		})
	}
}

// TestValidateModelValueAllowlistedNonGateway proves the allowlist is the
// deliberate extension point: a non-opencode-go provider is rejected by
// default and accepted only after being explicitly added.
func TestValidateModelValueAllowlistedNonGateway(t *testing.T) {
	const id = "google/gemini-3.8-flash"
	if err := validateModelValue("chef", id); err == nil {
		t.Fatalf("validateModelValue(%q) = nil, want PROVIDER_NOT_ALLOWLISTED before allowlisting", id)
	}

	saved := maps.Clone(allowedModelProviders)
	t.Cleanup(func() { allowedModelProviders = saved })

	allowedModelProviders["google"] = true
	if err := validateModelValue("chef", id); err != nil {
		t.Fatalf("validateModelValue(%q) after allowlisting google = %v, want nil", id, err)
	}
}

// TestValidateProfileNonString pins the panic-to-error conversion: the old
// `v.(string)` assertion crashed the builder mid-run on structured values.
func TestValidateProfileNonString(t *testing.T) {
	for _, raw := range []interface{}{
		map[string]interface{}{"providerID": "opencode-go"},
		[]interface{}{"opencode-go/a"},
		float64(4),
		nil,
		true,
	} {
		_, err := validateProfile(map[string]interface{}{"model": raw})
		if err == nil {
			t.Fatalf("validateProfile with non-string value %#v = nil error, want hard failure", raw)
		}
		if !strings.Contains(err.Error(), `"model"`) {
			t.Fatalf("error must name the offending key, got: %v", err)
		}
	}
}

// TestValidateProfileOK mirrors the live opencodego profile: valid values
// pass and are returned byte-identical (no suffix appended or stripped).
func TestValidateProfileOK(t *testing.T) {
	raw := map[string]interface{}{
		"organiza":  "opencode-go/mimo-v2.6-flash",
		"finanzas":  "opencode-go/gemini-4-argon#medium",
		"commander": "opencode-go/qwen3.8-flash",
	}
	flat, err := validateProfile(raw)
	if err != nil {
		t.Fatalf("validateProfile(valid profile) = %v, want nil", err)
	}
	if got, want := flat["organiza"], "opencode-go/mimo-v2.6-flash"; got != want {
		t.Fatalf("bare id mutated: got %q, want %q", got, want)
	}
	if got, want := flat["finanzas"], "opencode-go/gemini-4-argon#medium"; got != want {
		t.Fatalf("suffixed id mutated: got %q, want %q", got, want)
	}
}

// TestValidateProfileAllViolationsReported checks deterministic, aggregated
// reporting (sorted keys, every violation, not just the first).
func TestValidateProfileAllViolationsReported(t *testing.T) {
	_, err := validateProfile(map[string]interface{}{
		"zebra":     "opencode-go/a#b#c",
		"alpha":     "",
		"middle":    "opencode-go/ok",
		"nonstring": map[string]interface{}{},
	})
	if err == nil {
		t.Fatal("want error, got nil")
	}
	msg := err.Error()
	if strings.Contains(msg, `"middle"`) {
		t.Fatalf("valid key reported as violation: %v", err)
	}
	iAlpha, iZebra, iNon := strings.Index(msg, `"alpha"`), strings.Index(msg, `"zebra"`), strings.Index(msg, `"nonstring"`)
	if iAlpha < 0 || iZebra < 0 || iNon < 0 {
		t.Fatalf("all three violations must be reported, got: %v", err)
	}
	if !(iAlpha < iNon && iNon < iZebra) {
		t.Fatalf("violations must be reported in sorted key order, got: %v", err)
	}
}

// TestResolveModelPlaceholdersMissingKey pins contract C: a missing key is a
// hard error, never the old warn-and-leave-literal path.
func TestResolveModelPlaceholdersMissingKey(t *testing.T) {
	saved := ModelProfile
	t.Cleanup(func() { ModelProfile = saved })

	ModelProfile = map[string]string{"chef": "opencode-go/gpt-6-luna#medium"}

	// Missing key → error mentioning the key.
	_, err := resolveModelPlaceholders("model: {{MODEL:ghost}}\n")
	if err == nil {
		t.Fatal("missing key must be a hard error, got nil")
	}
	if !strings.Contains(err.Error(), `"ghost"`) {
		t.Fatalf("error must name the missing key, got: %v", err)
	}

	// Present key → verbatim substitution, both emission paths identical.
	out, err := resolveModelPlaceholders("model: {{MODEL:chef}}\n")
	if err != nil {
		t.Fatalf("valid key errored: %v", err)
	}
	if out != "model: opencode-go/gpt-6-luna#medium\n" {
		t.Fatalf("substitution mutated value: %q", out)
	}
	// JSON config target shape — '#' must survive untouched inside a string.
	out, err = resolveModelPlaceholders(`{"model": "{{MODEL:chef}}"}`)
	if err != nil {
		t.Fatalf("valid key errored on JSON path: %v", err)
	}
	if out != `{"model": "opencode-go/gpt-6-luna#medium"}` {
		t.Fatalf("JSON path mutated value: %q", out)
	}
}
