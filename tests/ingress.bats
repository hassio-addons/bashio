#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/ingress.sh.
#
# The Supervisor API boundary is stubbed via a `bashio::api.supervisor` bash
# function so no real HTTP requests are made. The cache is isolated to a
# per-test temporary directory.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ---------------------------------------------------------------------------
# bashio::ingress.panels
# ---------------------------------------------------------------------------

@test "ingress.panels calls GET /ingress/panels and returns the panels object" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"a8a8a8a8":{"title":"Demo","enable":true}}'
    }
    run bashio::ingress.panels
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /ingress/panels false .panels" ]
    [ "${output}" = '{"a8a8a8a8":{"title":"Demo","enable":true}}' ]
}

@test "ingress.panels applies a jq filter to the panels response" {
    bashio::api.supervisor() {
        printf '%s' '{"a8a8a8a8":{"title":"Demo","enable":true}}'
    }
    run bashio::ingress.panels 'ingress.panels.custom' '.a8a8a8a8.title'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Demo" ]
}

@test "ingress.panels reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::ingress.panels
    [ "${status}" -ne 0 ]
}

@test "ingress.panels serves a previously cached value without calling the API" {
    bashio::cache.set 'ingress.panels.cached' 'cached-panels'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::ingress.panels 'ingress.panels.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-panels" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ---------------------------------------------------------------------------
# bashio::ingress.session
# ---------------------------------------------------------------------------

@test "ingress.session calls POST /ingress/session with the session filter" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' 'abc-session-id'
    }
    run bashio::ingress.session
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /ingress/session {} .session" ]
}

@test "ingress.session returns the session id from the API response" {
    bashio::api.supervisor() { printf '%s' 'abc-session-id'; }
    run bashio::ingress.session
    [ "${status}" -eq 0 ]
    [ "${output}" = "abc-session-id" ]
}

@test "ingress.session propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::ingress.session || rc=$?
    [ "${rc}" -ne 0 ]
}

# ---------------------------------------------------------------------------
# bashio::ingress.validate_session
# ---------------------------------------------------------------------------

@test "ingress.validate_session posts the session in a JSON body" {
    bashio::api.supervisor() { printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"; }
    expected_payload=$(bashio::var.json session "abc-session-id")
    run bashio::ingress.validate_session "abc-session-id"
    [ "${status}" -eq 0 ]
    call="$(cat "${BATS_TEST_TMPDIR}/call")"
    [ "${call}" = "POST /ingress/validate_session ${expected_payload}" ]
}

@test "ingress.validate_session payload contains the session id" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/payload"; }
    bashio::ingress.validate_session "my-session"
    payload="$(cat "${BATS_TEST_TMPDIR}/payload")"
    [ "$(printf '%s' "${payload}" | jq -r '.session')" = "my-session" ]
}

@test "ingress.validate_session returns success on a valid session" {
    bashio::api.supervisor() { return 0; }
    run bashio::ingress.validate_session "valid-session"
    [ "${status}" -eq 0 ]
}

@test "ingress.validate_session returns failure on an invalid session" {
    bashio::api.supervisor() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/call"
        return 1
    }
    rc=0
    bashio::ingress.validate_session "invalid-session" || rc=$?
    [ "${rc}" -ne 0 ]
    # The failing Supervisor call must still have been attempted.
    [[ "$(cat "${BATS_TEST_TMPDIR}/call")" == "POST /ingress/validate_session "* ]]
}
