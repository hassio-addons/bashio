#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/pwned.sh (Have I Been Pwned password checks).
#
# The HIBP network boundary is stubbed by shadowing `curl` (configurable via
# MOCK_BODY/MOCK_STATUS). The log functions are stubbed to a file so the tests
# can both capture the echoed occurrence count on stdout and assert on what was
# (and was not) logged, independent of the configured log level.
#
# The k-anonymity API returns the SHA-1 suffix (chars 6-40) and a count per
# line. For the password "test" the SHA-1 is
# A94A8FE5CCB19BA61C4C0873D391E987982FBBD3, so the prefix sent is "A94A8" and
# the matching suffix is "FE5CCB19BA61C4C0873D391E987982FBBD3".
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

TEST_SUFFIX="FE5CCB19BA61C4C0873D391E987982FBBD3"

setup() {
    BASHIO_TEST_LOG="${BATS_TEST_TMPDIR}/log"
    : >"${BASHIO_TEST_LOG}"
    bashio::log.trace() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.debug() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.info() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.warning() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.error() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }

    # HIBP boundary stub. Defaults to an empty 200 response (no match).
    MOCK_BODY=''
    MOCK_STATUS='200'
    curl() { printf '%s\n%s' "${MOCK_BODY}" "${MOCK_STATUS}"; }
}

@test "pwned never logs the full password hash" {
    bashio::pwned "test" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    # Only the 5-char k-anonymity prefix may be logged, never the full SHA-1.
    [[ "${output}" != *"A94A8FE5CCB19BA61C4C0873D391E987982FBBD3"* ]]
}

@test "pwned never logs the plaintext password" {
    bashio::pwned "SuperSecretValue" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    [[ "${output}" != *"SuperSecretValue"* ]]
}

@test "pwned returns the occurrence count when the password is found" {
    MOCK_BODY="${TEST_SUFFIX}:42"
    run bashio::pwned "test"
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "pwned strips a trailing carriage return from the count" {
    MOCK_BODY="${TEST_SUFFIX}:1337"$'\r'
    run bashio::pwned "test"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1337" ]
}

@test "pwned returns 0 when the password is not found" {
    MOCK_BODY="0000000000000000000000000000000000A:5"
    run bashio::pwned "test"
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "pwned rejects an empty password without contacting the API" {
    curl() { touch "${BATS_TEST_TMPDIR}/curl_called"; }
    run bashio::pwned ""
    [ "${status}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/curl_called" ]
}

@test "pwned fails on HIBP error HTTP statuses" {
    for code in 429 503 500; do
        MOCK_STATUS="${code}"
        run bashio::pwned "test"
        [ "${status}" -ne 0 ]
    done
}

@test "pwned fails when the API request itself fails" {
    curl() { return 1; }
    run bashio::pwned "test"
    [ "${status}" -ne 0 ]
}

@test "pwned.is_safe_password is safe for an unseen password" {
    MOCK_BODY="0000000000000000000000000000000000A:5"
    run bashio::pwned.is_safe_password "test"
    [ "${status}" -eq 0 ]
}

@test "pwned.is_safe_password is unsafe for a breached password" {
    MOCK_BODY="${TEST_SUFFIX}:42"
    run bashio::pwned.is_safe_password "test"
    [ "${status}" -ne 0 ]
}

@test "pwned.is_safe_password assumes safe when the check cannot run" {
    curl() { return 1; }
    run bashio::pwned.is_safe_password "test"
    [ "${status}" -eq 0 ]
    grep -q "assuming it is safe" "${BASHIO_TEST_LOG}"
}

@test "pwned.occurrences returns the count" {
    MOCK_BODY="${TEST_SUFFIX}:42"
    run bashio::pwned.occurrences "test"
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "pwned.occurrences returns 0 when the check fails" {
    curl() { return 1; }
    run bashio::pwned.occurrences "test"
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "the deprecated misspelled alias warns and still delegates" {
    MOCK_BODY="${TEST_SUFFIX}:42"
    run bashio::pwned.occurances "test" # codespell:ignore occurances
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
    grep -q "deprecated" "${BASHIO_TEST_LOG}"
}
