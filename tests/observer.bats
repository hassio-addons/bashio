#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/observer.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::observer` fetcher, jq filtering, and caching run. The cache is pointed
# at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "observer module is loaded by bashio" {
    run type -t bashio::observer.update
    [ "${status}" -eq 0 ]
    [ "${output}" = "function" ]
}

# ------------------------------------------------------------------------------
# observer.update: with and without version, plus failure propagation.
# ------------------------------------------------------------------------------

@test "observer.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::observer.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /observer/update" ]
}

@test "observer.update with a version sends it as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::observer.update "2024.1.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /observer/update {"version":"2024.1.0"}' ]
}

@test "observer.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::observer.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "observer.update with a version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::observer.update "2024.1.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# observer: info fetcher, filtering, caching, and failure handling.
# ------------------------------------------------------------------------------

@test "observer fetches info from the correct endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"2024.1.0"}'
    }
    run bashio::observer
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /observer/info false" ]
    [ "${output}" = '{"version":"2024.1.0"}' ]
}

@test "observer applies a jq filter to the info response" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::observer 'observer.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "observer returns a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'my.key' 'cached-value'
    run bashio::observer 'my.key'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
}

@test "observer reuses cached observer.info instead of refetching" {
    bashio::cache.set 'observer.info' '{"version":"9.9.9"}'
    bashio::api.supervisor() { return 1; }
    run bashio::observer 'observer.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "9.9.9" ]
}

@test "observer propagates an API failure when fetching info" {
    bashio::api.supervisor() { return 1; }
    run bashio::observer
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Info-backed getters.
# ------------------------------------------------------------------------------

@test "observer.version returns the version field" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::observer.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "observer.version_latest returns the version_latest field" {
    bashio::api.supervisor() { printf '%s' '{"version_latest":"2024.2.0"}'; }
    run bashio::observer.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.2.0" ]
}

@test "observer.update_available returns the update_available field" {
    bashio::api.supervisor() { printf '%s' '{"update_available":true}'; }
    run bashio::observer.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "observer.update_available defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::observer.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "observer.host returns the host field" {
    bashio::api.supervisor() { printf '%s' '{"host":"172.30.32.6"}'; }
    run bashio::observer.host
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.6" ]
}

# ------------------------------------------------------------------------------
# observer.stats: fetcher, filtering, caching, and failure handling.
# ------------------------------------------------------------------------------

@test "observer.stats fetches stats from the correct endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::observer.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /observer/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5}' ]
}

@test "observer.stats returns a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'my.stat' 'cached-stat'
    run bashio::observer.stats 'my.stat'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-stat" ]
}

@test "observer.stats propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::observer.stats
    [ "${status}" -ne 0 ]
}

@test "observer.cpu_percent returns the cpu_percent stat" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":12.34}'; }
    run bashio::observer.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.34" ]
}

@test "observer.memory_usage returns the memory_usage stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_usage":1048576}'; }
    run bashio::observer.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1048576" ]
}

@test "observer.memory_limit returns the memory_limit stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_limit":2097152}'; }
    run bashio::observer.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2097152" ]
}

@test "observer.memory_percent returns the memory_percent stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_percent":50}'; }
    run bashio::observer.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "50" ]
}

@test "observer.network_tx returns the network_tx stat" {
    bashio::api.supervisor() { printf '%s' '{"network_tx":512}'; }
    run bashio::observer.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "512" ]
}

@test "observer.network_rx returns the network_rx stat" {
    bashio::api.supervisor() { printf '%s' '{"network_rx":256}'; }
    run bashio::observer.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "256" ]
}

@test "observer.blk_read returns the blk_read stat" {
    bashio::api.supervisor() { printf '%s' '{"blk_read":1024}'; }
    run bashio::observer.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "observer.blk_write returns the blk_write stat" {
    bashio::api.supervisor() { printf '%s' '{"blk_write":2048}'; }
    run bashio::observer.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}
