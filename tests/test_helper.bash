#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Test helper: loads the bashio library so its functions are available to tests.
# ==============================================================================

# Resolve the repository root based on this file's location.
BASHIO_TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

# shellcheck source=/dev/null
source "${BASHIO_TEST_ROOT}/lib/bashio.sh"

# Bashio enables errexit, nounset and pipefail when sourced. Relax them again so
# they do not interfere with the Bats test runner.
set +o errexit +o nounset +o pipefail
