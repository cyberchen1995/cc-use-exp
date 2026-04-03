#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
ALLOWLIST_FILE="${REPO_ROOT}/.github/cla/allowlist.txt"
EVENT_PATH="${GITHUB_EVENT_PATH:-}"
REQUIRED_LABEL="cla-signed"

if [[ ! -f "${ALLOWLIST_FILE}" ]]; then
  echo "CLA allowlist file not found: ${ALLOWLIST_FILE}" >&2
  exit 1
fi

if [[ -z "${EVENT_PATH}" || ! -f "${EVENT_PATH}" ]]; then
  echo "GITHUB_EVENT_PATH is not set or does not point to a readable event payload." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse the GitHub event payload." >&2
  exit 1
fi

pr_author=$(jq -r '.pull_request.user.login // empty' "${EVENT_PATH}")
pr_number=$(jq -r '.pull_request.number // empty' "${EVENT_PATH}")
pr_labels=$(jq -r '.pull_request.labels[].name? // empty' "${EVENT_PATH}")

if [[ -z "${pr_author}" ]]; then
  echo "Unable to determine pull request author from event payload." >&2
  exit 1
fi

if grep -Fqx "${pr_author}" "${ALLOWLIST_FILE}"; then
  echo "CLA gate passed for PR #${pr_number}: author '${pr_author}' is in the allowlist."
  exit 0
fi

if printf '%s\n' "${pr_labels}" | grep -Fqx "${REQUIRED_LABEL}"; then
  echo "CLA gate passed for PR #${pr_number}: label '${REQUIRED_LABEL}' is present."
  exit 0
fi

cat >&2 <<EOF
CLA gate failed for PR #${pr_number}: author '${pr_author}' is not allowlisted and label '${REQUIRED_LABEL}' is missing.

Next steps for maintainers:
1. Confirm the contributor has signed and returned CLA.md.
2. Archive the signed CLA outside the repository or in your internal records.
3. Either add '${pr_author}' to .github/cla/allowlist.txt for ongoing approval,
   or add the '${REQUIRED_LABEL}' label to this pull request for one-off approval.
EOF

exit 1
