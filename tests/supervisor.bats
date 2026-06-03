#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/supervisor.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::supervisor` fetcher, jq filtering, and caching run. The cache is
# pointed at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "supervisor.ping calls the ping endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.ping
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /supervisor/ping" ]
}

@test "supervisor.version extracts the version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"2024.1.0","arch":"amd64"}'
    }
    run bashio::supervisor.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "supervisor.arch extracts the architecture from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"2024.1.0","arch":"amd64"}'
    }
    run bashio::supervisor.arch
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "supervisor.channel sends the channel as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::supervisor.channel "beta"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /supervisor/options {"channel":"beta"}' ]
}
