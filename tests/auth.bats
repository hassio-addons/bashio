#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/auth.sh (Home Assistant Supervisor auth backend).
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. It records its arguments to a
# file and returns a configurable exit code so success and failure handling
# can be asserted. The log functions are stubbed to a file so the tests can
# assert that the password is never logged, like tests/pwned.bats.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

PASSWORD="SuperSecretValue"

setup() {
    BASHIO_TEST_LOG="${BATS_TEST_TMPDIR}/log"
    : >"${BASHIO_TEST_LOG}"
    bashio::log.trace() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.debug() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.info() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.warning() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }
    bashio::log.error() { printf '%s\n' "$*" >>"${BASHIO_TEST_LOG}"; }

    CALL_FILE="${BATS_TEST_TMPDIR}/call"
}

# ---------------------------------------------------------------------------
# bashio::auth - authenticate a Home Assistant user
# ---------------------------------------------------------------------------

@test "auth posts the credentials to /auth as JSON" {
    bashio::api.supervisor() { printf '%s' "$*" >"${CALL_FILE}"; }
    run bashio::auth "alice" "${PASSWORD}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${CALL_FILE}")" = 'POST /auth {"username":"alice","password":"SuperSecretValue"}' ]
}

@test "auth returns success when the Supervisor returns 200" {
    bashio::api.supervisor() { return 0; }
    run bashio::auth "alice" "${PASSWORD}"
    [ "${status}" -eq 0 ]
}

@test "auth returns failure when the Supervisor returns 401" {
    # api.supervisor maps the 401 unauthorized response onto a non-zero exit.
    bashio::api.supervisor() { return 1; }
    run bashio::auth "alice" "wrongpass"
    [ "${status}" -ne 0 ]
}

@test "auth never logs the plaintext password" {
    bashio::api.supervisor() { return 0; }
    bashio::auth "alice" "${PASSWORD}" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    [[ "${output}" != *"${PASSWORD}"* ]]
}

# ---------------------------------------------------------------------------
# bashio::auth.list - list users
# ---------------------------------------------------------------------------

@test "auth.list calls GET /auth/list and returns the users" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${CALL_FILE}"
        printf '%s' '[{"username":"alice"},{"username":"bob"}]'
    }
    run bashio::auth.list
    [ "${status}" -eq 0 ]
    [ "$(cat "${CALL_FILE}")" = "GET /auth/list false .users" ]
    [ "$(printf '%s' "${output}" | jq -r '.[0].username')" = "alice" ]
}

@test "auth.list propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::auth.list
    [ "${status}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::auth.reset - reset a password
# ---------------------------------------------------------------------------

@test "auth.reset posts the credentials to /auth/reset as JSON" {
    bashio::api.supervisor() { printf '%s' "$*" >"${CALL_FILE}"; }
    run bashio::auth.reset "alice" "${PASSWORD}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${CALL_FILE}")" = 'POST /auth/reset {"username":"alice","password":"SuperSecretValue"}' ]
}

@test "auth.reset propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::auth.reset "alice" "${PASSWORD}"
    [ "${status}" -ne 0 ]
}

@test "auth.reset never logs the plaintext password" {
    bashio::api.supervisor() { return 0; }
    bashio::auth.reset "alice" "${PASSWORD}" >/dev/null
    run cat "${BASHIO_TEST_LOG}"
    [[ "${output}" != *"${PASSWORD}"* ]]
}

# ---------------------------------------------------------------------------
# bashio::auth.cache.reset - clear the auth cache
# ---------------------------------------------------------------------------

@test "auth.cache.reset calls DELETE /auth/cache" {
    bashio::api.supervisor() { printf '%s' "$*" >"${CALL_FILE}"; }
    run bashio::auth.cache.reset
    [ "${status}" -eq 0 ]
    [ "$(cat "${CALL_FILE}")" = "DELETE /auth/cache" ]
}

@test "auth.cache.reset propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::auth.cache.reset
    [ "${status}" -ne 0 ]
}
