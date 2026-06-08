#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/security.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::security` fetcher, jq filtering, and caching run. The cache is
# pointed at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::security (info fetcher)
# ------------------------------------------------------------------------------

@test "security fetches the info endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"pwned":true,"force_security":false}'
    }
    run bashio::security
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /security/info false" ]
    [ "${output}" = '{"pwned":true,"force_security":false}' ]
}

@test "security applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"pwned":true,"force_security":false}'
    }
    run bashio::security 'security.info.custom' '.pwned'
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "security reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::security
    [ "${status}" -ne 0 ]
}

@test "security serves a previously cached value without calling the API" {
    bashio::cache.set 'security.info.cached' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::security 'security.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::security.options
# ------------------------------------------------------------------------------

@test "security.options posts the given JSON to the options endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::security.options '{"force_security":true}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /security/options {"force_security":true}' ]
}

@test "security.options propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::security.options '{"force_security":true}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "security.options flushes the cache after a successful set" {
    bashio::cache.set 'security.info' 'stale'
    bashio::api.supervisor() { return 0; }
    run bashio::security.options '{"pwned":false}'
    [ "${status}" -eq 0 ]
    run bashio::cache.exists 'security.info'
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::security.pwned
# ------------------------------------------------------------------------------

@test "security.pwned returns the boolean from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"pwned":true}'
    }
    run bashio::security.pwned
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "security.pwned defaults to false when the key is missing" {
    bashio::api.supervisor() {
        printf '%s' '{"force_security":true}'
    }
    run bashio::security.pwned
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "security.pwned with a value posts it to the options endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::security.pwned true
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /security/options {"pwned":true}' ]
}

@test "security.pwned normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    # A crafted value must not break out into additional options keys; anything
    # that is not strictly true is treated as false.
    run bashio::security.pwned 'true,"force_security":true'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"pwned":false}' ]
    run jq -e 'has("force_security")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "security.pwned normalizes literal true to a boolean true payload" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::security.pwned 'true'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"pwned":true}' ]
}

@test "security.pwned propagates an API failure when reading" {
    bashio::api.supervisor() { return 1; }
    run bashio::security.pwned
    [ "${status}" -ne 0 ]
}

@test "security.pwned propagates an API failure when setting" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::security.pwned true || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::security.force_security
# ------------------------------------------------------------------------------

@test "security.force_security returns the boolean from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"force_security":true}'
    }
    run bashio::security.force_security
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "security.force_security defaults to false when the key is missing" {
    bashio::api.supervisor() {
        printf '%s' '{"pwned":true}'
    }
    run bashio::security.force_security
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "security.force_security with a value posts it to the options endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::security.force_security false
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /security/options {"force_security":false}' ]
}

@test "security.force_security normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::security.force_security 'true,"pwned":true'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /security/options {"force_security":false}' ]
}

@test "security.force_security propagates an API failure when reading" {
    bashio::api.supervisor() { return 1; }
    run bashio::security.force_security
    [ "${status}" -ne 0 ]
}

@test "security.force_security propagates an API failure when setting" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::security.force_security true || rc=$?
    [ "${rc}" -ne 0 ]
}
