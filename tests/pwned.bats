#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/pwned.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

@test "pwned does not log the full password hash, even at debug level" {
    # Stub Have I Been Pwned: respond 200 with no matching suffix.
    curl() { printf '\n200'; }

    # Enable debug logging and capture it to a file.
    __BASHIO_LOG_LEVEL="${__BASHIO_LOG_LEVEL_DEBUG}"
    exec {LOG_FD}>"${BATS_TEST_TMPDIR}/log"

    bashio::pwned "test" >/dev/null

    run cat "${BATS_TEST_TMPDIR}/log"
    # The full SHA-1 of "test" must never appear in the logs (only the 5-char
    # k-anonymity prefix is sent to, and logged for, the API).
    [[ "${output}" != *"A94A8FE5CCB19BA61C4C0873D391E987982FBBD3"* ]]
}
