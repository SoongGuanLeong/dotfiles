#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/lib.sh"

export_dotfiles_env_vars
MIN_NIXPKGS_AGE_DAYS=14

command -v nix >/dev/null 2>&1 ||
  die "Nix is required"

command -v jq >/dev/null 2>&1 ||
  die "jq is required"

cd "$DOTFILES_DIRECTORY"

metadata="$(nix flake metadata --json .)"
nixpkgs_node="$(
  jq -r '
    .locks.nodes.root.inputs.nixpkgs as $name
    | .locks.nodes[$name]
  ' <<<"$metadata"
)"

nixpkgs_revision="$(jq -r '.locked.rev // empty' <<<"$nixpkgs_node")"
nixpkgs_last_modified="$(jq -r '.locked.lastModified // empty' <<<"$nixpkgs_node")"

[[ -n "$nixpkgs_revision" ]] ||
  die "Could not determine pinned nixpkgs revision"

[[ "$nixpkgs_last_modified" =~ ^[0-9]+$ ]] ||
  die "Could not determine nixpkgs revision timestamp"

now="$(date +%s)"
age_seconds=$((now - nixpkgs_last_modified))
age_days=$((age_seconds / 86400))

printf '=== Nixpkgs policy ===\n'
printf 'Revision: %s\n' "$nixpkgs_revision"
printf 'Age:      %s days\n' "$age_days"
printf 'Minimum:  %s days\n' "$MIN_NIXPKGS_AGE_DAYS"

if (( age_seconds < MIN_NIXPKGS_AGE_DAYS * 86400 )); then
  printf 'Status:   TOO NEW FOR UPDATE\n'
else
  printf 'Status:   ELIGIBLE FOR UPDATE\n'
fi

printf '\n=== Package vulnerability metadata ===\n'

packages="$(
  nix eval --impure --json \
    '.#homeConfigurations.default.config.home.packages' \
    --apply '
      builtins.map (p: {
        name = p.pname or p.name;
        version = p.version or null;
        vulnerabilities = p.meta.knownVulnerabilities or [];
      })
    '
)"

vulnerable_count="$(
  jq '[.[] | select(.vulnerabilities | length > 0)] | length' <<<"$packages"
)"

if (( vulnerable_count > 0 )); then
  printf '%s\n' "$packages" |
    jq -r '
      .[]
      | select(.vulnerabilities | length > 0)
      | "\(.name) \(.version // "unknown"): \(.vulnerabilities | join("; "))"
    '
  die "One or more managed packages have known vulnerabilities"
fi

package_count="$(jq 'length' <<<"$packages")"

printf 'Packages checked: %s\n' "$package_count"
printf 'Known vulnerabilities: 0\n'
printf 'Status: PASS\n'

if (( age_seconds < MIN_NIXPKGS_AGE_DAYS * 86400 )); then
  printf '\nAudit passed; current lock is not eligible for a dependency update yet.\n'
else
  printf '\nAudit passed; current lock is eligible for a dependency update.\n'
fi
