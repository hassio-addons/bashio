#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/cli.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::cli` fetcher, jq filtering, and caching run. The cache is pointed at
# a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::cli.update
# ------------------------------------------------------------------------------

@test "cli.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::cli.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /cli/update" ]
}

@test "cli.update with a version posts it as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::cli.update "2024.1.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /cli/update {"version":"2024.1.0"}' ]
}

@test "cli.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::cli.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "cli.update with a version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::cli.update "2024.1.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::cli (info fetcher)
# ------------------------------------------------------------------------------

@test "cli fetches info from the correct endpoint with raw output" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"1.0","version_latest":"1.1"}'
    }
    run bashio::cli
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /cli/info false" ]
    [ "${output}" = '{"version":"1.0","version_latest":"1.1"}' ]
}

@test "cli applies the provided jq filter" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"1.1"}'
    }
    run bashio::cli 'cli.info.custom' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.0" ]
}

@test "cli returns the cached value for the requested cache key" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'cli.info.custom' 'cached-value'
    run bashio::cli 'cli.info.custom'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
}

@test "cli reuses cached cli.info instead of calling the API again" {
    bashio::cache.set 'cli.info' '{"version":"9.9"}'
    bashio::api.supervisor() { return 1; }
    run bashio::cli 'cli.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "9.9" ]
}

@test "cli caches the filtered response under the cache key" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::cli 'cli.info.version' '.version'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.0" ]
    run bashio::cache.get 'cli.info.version'
    [ "${output}" = "1.0" ]
}

@test "cli propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::cli
    [ "${status}" -ne 0 ]
}

@test "cli fails when the jq filter is invalid" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::cli 'cli.info.bad' '.['
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Info getters
# ------------------------------------------------------------------------------

@test "cli.version returns the version field" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"2024.1.0","version_latest":"2024.2.0"}'
    }
    run bashio::cli.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "cli.version_latest returns the version_latest field" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"2024.1.0","version_latest":"2024.2.0"}'
    }
    run bashio::cli.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.2.0" ]
}

@test "cli.update_available returns the update_available flag" {
    bashio::api.supervisor() {
        printf '%s' '{"update_available":true}'
    }
    run bashio::cli.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "cli.update_available defaults to false when missing" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::cli.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "cli.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::cli.version
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::cli.stats (stats fetcher)
# ------------------------------------------------------------------------------

@test "cli.stats fetches stats from the correct endpoint with raw output" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::cli.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /cli/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5}' ]
}

@test "cli.stats returns the cached value for the requested cache key" {
    bashio::api.supervisor() { return 1; }
    bashio::cache.set 'cli.stats.custom' 'cached-stats'
    run bashio::cli.stats 'cli.stats.custom'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-stats" ]
}

@test "cli.stats reuses cached cli.stats instead of calling the API again" {
    bashio::cache.set 'cli.stats' '{"cpu_percent":42}'
    bashio::api.supervisor() { return 1; }
    run bashio::cli.stats 'cli.stats.cpu_percent' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "cli.stats propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::cli.stats
    [ "${status}" -ne 0 ]
}

@test "cli.stats fails when the jq filter is invalid" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::cli.stats 'cli.stats.bad' '.['
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Stats getters
# ------------------------------------------------------------------------------

@test "cli.cpu_percent returns the cpu_percent field" {
    bashio::api.supervisor() { printf '%s' '{"cpu_percent":12.5}'; }
    run bashio::cli.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.5" ]
}

@test "cli.memory_usage returns the memory_usage field" {
    bashio::api.supervisor() { printf '%s' '{"memory_usage":1024}'; }
    run bashio::cli.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "cli.memory_limit returns the memory_limit field" {
    bashio::api.supervisor() { printf '%s' '{"memory_limit":2048}'; }
    run bashio::cli.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}

@test "cli.memory_percent returns the memory_percent field" {
    bashio::api.supervisor() { printf '%s' '{"memory_percent":50}'; }
    run bashio::cli.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "50" ]
}

@test "cli.network_tx returns the network_tx field" {
    bashio::api.supervisor() { printf '%s' '{"network_tx":111}'; }
    run bashio::cli.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "111" ]
}

@test "cli.network_rx returns the network_rx field" {
    bashio::api.supervisor() { printf '%s' '{"network_rx":222}'; }
    run bashio::cli.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "222" ]
}

@test "cli.blk_read returns the blk_read field" {
    bashio::api.supervisor() { printf '%s' '{"blk_read":333}'; }
    run bashio::cli.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "333" ]
}

@test "cli.blk_write returns the blk_write field" {
    bashio::api.supervisor() { printf '%s' '{"blk_write":444}'; }
    run bashio::cli.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "444" ]
}

@test "cli.cpu_percent propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::cli.cpu_percent
    [ "${status}" -ne 0 ]
}
