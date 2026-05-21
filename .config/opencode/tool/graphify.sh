#!/usr/bin/env bash
# Ensure uv tool bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
exec graphify "$@"