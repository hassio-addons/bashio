#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/core.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::core` fetcher, jq filtering, and caching run. The cache is pointed at
# a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# Simple action endpoints (POST/GET forwarding).
# ------------------------------------------------------------------------------

@test "core.start posts to the start endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.start
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/start" ]
}

@test "core.start propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::core.start
    [ "${status}" -ne 0 ]
}

@test "core.stop posts to the stop endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.stop
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/stop" ]
}

@test "core.restart posts to the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.restart
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/restart" ]
}

@test "core.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::core.restart
    [ "${status}" -ne 0 ]
}

@test "core.rebuild posts to the rebuild endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.rebuild
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/rebuild" ]
}

@test "core.check posts to the check endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.check
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/check" ]
}

@test "core.logs fetches the logs with the raw flag" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /core/logs true" ]
}

# ------------------------------------------------------------------------------
# core.update: with and without version, plus failure propagation.
# ------------------------------------------------------------------------------

@test "core.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /core/update" ]
}

@test "core.update with a version sends it as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.update "2024.1.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /core/update {"version":"2024.1.0"}' ]
}

@test "core.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "core.update with a version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.update "2024.1.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# core: info fetcher, filtering, caching, and failure handling.
# ------------------------------------------------------------------------------

@test "core fetches info from the correct endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"2024.1.0"}'
    }
    run bashio::core
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /core/info false" ]
    [ "${output}" = '{"version":"2024.1.0"}' ]
}

@test "core applies a jq filter to the info response" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::core 'core.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "core returns a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'my.key' 'cached-value'
    run bashio::core 'my.key'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
}

@test "core reuses cached core.info instead of refetching" {
    bashio::cache.set 'core.info' '{"version":"9.9.9"}'
    bashio::api.supervisor() { return 1; }
    run bashio::core 'core.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "9.9.9" ]
}

@test "core propagates an API failure when fetching info" {
    bashio::api.supervisor() { return 1; }
    run bashio::core
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Info-backed getters.
# ------------------------------------------------------------------------------

@test "core.version returns the version field" {
    bashio::api.supervisor() { printf '%s' '{"version":"2024.1.0"}'; }
    run bashio::core.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "core.version_latest returns the version_latest field" {
    bashio::api.supervisor() { printf '%s' '{"version_latest":"2024.2.0"}'; }
    run bashio::core.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.2.0" ]
}

@test "core.update_available returns the update_available field" {
    bashio::api.supervisor() { printf '%s' '{"update_available":true}'; }
    run bashio::core.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "core.update_available defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::core.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "core.arch returns the arch field" {
    bashio::api.supervisor() { printf '%s' '{"arch":"amd64"}'; }
    run bashio::core.arch
    [ "${status}" -eq 0 ]
    [ "${output}" = "amd64" ]
}

@test "core.machine returns the machine field" {
    bashio::api.supervisor() { printf '%s' '{"machine":"qemux86-64"}'; }
    run bashio::core.machine
    [ "${status}" -eq 0 ]
    [ "${output}" = "qemux86-64" ]
}

@test "core.custom returns the custom field" {
    bashio::api.supervisor() { printf '%s' '{"custom":true}'; }
    run bashio::core.custom
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "core.custom defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::core.custom
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "core.boot returns the boot field" {
    bashio::api.supervisor() { printf '%s' '{"boot":true}'; }
    run bashio::core.boot
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "core.boot defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::core.boot
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "core.port returns the port field" {
    bashio::api.supervisor() { printf '%s' '{"port":8123}'; }
    run bashio::core.port
    [ "${status}" -eq 0 ]
    [ "${output}" = "8123" ]
}

@test "core.ssl returns the ssl field" {
    bashio::api.supervisor() { printf '%s' '{"ssl":true}'; }
    run bashio::core.ssl
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "core.ssl defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::core.ssl
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

# ------------------------------------------------------------------------------
# core.image: getter and setter directions.
# ------------------------------------------------------------------------------

@test "core.image without arguments returns the image field" {
    bashio::api.supervisor() { printf '%s' '{"image":"ghcr.io/home-assistant/core"}'; }
    run bashio::core.image
    [ "${status}" -eq 0 ]
    [ "${output}" = "ghcr.io/home-assistant/core" ]
}

@test "core.image with an argument posts options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.image "ghcr.io/example/image"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /core/options {"image":"ghcr.io/example/image"}' ]
}

@test "core.image propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.image "ghcr.io/example/image" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# core.watchdog: getter and setter directions.
# ------------------------------------------------------------------------------

@test "core.watchdog without arguments returns the watchdog field" {
    bashio::api.supervisor() { printf '%s' '{"watchdog":true}'; }
    run bashio::core.watchdog
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "core.watchdog defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::core.watchdog
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "core.watchdog with a value posts a raw boolean option" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::core.watchdog "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /core/options {"watchdog":true}' ]
}

@test "core.watchdog propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::core.watchdog "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# core.stats: fetcher, filtering, caching, and failure handling.
# ------------------------------------------------------------------------------

@test "core.stats fetches stats from the correct endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::core.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /core/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5}' ]
}

@test "core.stats returns a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'my.stat' 'cached-stat'
    run bashio::core.stats 'my.stat'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-stat" ]
}

@test "core.stats propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::core.stats
    [ "${status}" -ne 0 ]
}

@test "core.cpu_percent returns the cpu_percent stat" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":12.34}'; }
    run bashio::core.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.34" ]
}

@test "core.memory_usage returns the memory_usage stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_usage":1048576}'; }
    run bashio::core.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1048576" ]
}

@test "core.memory_limit returns the memory_limit stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_limit":2097152}'; }
    run bashio::core.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2097152" ]
}

@test "core.memory_percent returns the memory_percent stat" {
    bashio::api.supervisor() { printf '%s' '{"memory_percent":50}'; }
    run bashio::core.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "50" ]
}

@test "core.network_tx returns the network_tx stat" {
    bashio::api.supervisor() { printf '%s' '{"network_tx":512}'; }
    run bashio::core.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "512" ]
}

@test "core.network_rx returns the network_rx stat" {
    bashio::api.supervisor() { printf '%s' '{"network_rx":256}'; }
    run bashio::core.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "256" ]
}

@test "core.blk_read returns the blk_read stat" {
    bashio::api.supervisor() { printf '%s' '{"blk_read":1024}'; }
    run bashio::core.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "core.blk_write returns the blk_write stat" {
    bashio::api.supervisor() { printf '%s' '{"blk_write":2048}'; }
    run bashio::core.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}
