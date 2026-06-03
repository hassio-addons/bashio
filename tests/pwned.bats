#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/pwned.sh.
#
# The logging functions are stubbed to record everything passed to them, so the
# tests assert directly that no secret is ever handed to a log call (independent
# of the configured log level or format).
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    BASHIO_TEST_LOG="${BATS_TEST_TMPDIR}/log"
    : >"${BASHIO_TEST_LOG}"
    bashio::log.trace() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.debug() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.info() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.warning() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.error() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
}

@test "pwned never logs the full password hash" {
    curl() { printf '\n200'; }
    bashio::pwned "test" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    # Only the 5-char k-anonymity prefix may be logged, never the full SHA-1.
    [[ "${output}" != *"A94A8FE5CCB19BA61C4C0873D391E987982FBBD3"* ]]
}

@test "pwned never logs the plaintext password" {
    curl() { printf '\n200'; }
    bashio::pwned "SuperSecretValue" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    [[ "${output}" != *"SuperSecretValue"* ]]
}
