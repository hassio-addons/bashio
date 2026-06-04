#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/multicast.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# multicast fetchers, jq filtering, and caching run. The cache is pointed at a
# per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::multicast.update
# ------------------------------------------------------------------------------

@test "multicast.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::multicast.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /multicast/update" ]
}

@test "multicast.update with a version forwards it as a JSON object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::multicast.update "1.2.3"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /multicast/update {"version":"1.2.3"}' ]
}

@test "multicast.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast.update "1.2.3" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.restart (preserved + expanded)
# ------------------------------------------------------------------------------

@test "multicast.restart calls the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::multicast.restart
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /multicast/restart" ]
}

@test "multicast.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.logs
# ------------------------------------------------------------------------------

@test "multicast.logs requests the logs endpoint in raw mode" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::multicast.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /multicast/logs true" ]
}

# ------------------------------------------------------------------------------
# bashio::multicast (info fetcher)
# ------------------------------------------------------------------------------

@test "multicast fetches info from the API and returns the raw object" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::multicast
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /multicast/info false" ]
    [ "${output}" = '{"version":"1.0","version_latest":"2.0"}' ]
}

@test "multicast applies a jq filter when provided" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::multicast 'multicast.custom' '.version_latest'
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.0" ]
}

@test "multicast serves a cached value without calling the API" {
    bashio::api.supervisor() { return 1; }
    mkdir -p "${__BASHIO_CACHE_DIR}"
    bashio::cache.set 'multicast.info' '{"version":"9.9"}'
    run bashio::multicast
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"version":"9.9"}' ]
}

@test "multicast propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.version
# ------------------------------------------------------------------------------

@test "multicast.version extracts the version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::multicast.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.0" ]
}

@test "multicast.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast.version || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.version_latest
# ------------------------------------------------------------------------------

@test "multicast.version_latest extracts the latest version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","version_latest":"2.0"}'
    }
    run bashio::multicast.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.0" ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.update_available
# ------------------------------------------------------------------------------

@test "multicast.update_available returns the update flag" {
    bashio::api.supervisor() {
        printf '%s' '{"update_available":true}'
    }
    run bashio::multicast.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "multicast.update_available defaults to false when absent" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::multicast.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

# ------------------------------------------------------------------------------
# bashio::multicast.stats (stats fetcher)
# ------------------------------------------------------------------------------

@test "multicast.stats fetches stats from the API and returns the raw object" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5,"memory_usage":1024}'
    }
    run bashio::multicast.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /multicast/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5,"memory_usage":1024}' ]
}

@test "multicast.stats applies a jq filter when provided" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":1.5,"memory_usage":1024}'
    }
    run bashio::multicast.stats 'multicast.custom' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
}

@test "multicast.stats propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::multicast.stats || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# stats accessors
# ------------------------------------------------------------------------------

@test "multicast.cpu_percent extracts the cpu_percent stat" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":2.5,"memory_usage":1,"memory_limit":2,"memory_percent":3,"network_tx":4,"network_rx":5,"blk_read":6,"blk_write":7}'
    }
    run bashio::multicast.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.5" ]
}

@test "multicast.memory_usage extracts the memory_usage stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_usage":1024}'
    }
    run bashio::multicast.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "multicast.memory_limit extracts the memory_limit stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_limit":2048}'
    }
    run bashio::multicast.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}

@test "multicast.memory_percent extracts the memory_percent stat" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_percent":42}'
    }
    run bashio::multicast.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "42" ]
}

@test "multicast.network_tx extracts the network_tx stat" {
    bashio::api.supervisor() {
        printf '%s' '{"network_tx":100}'
    }
    run bashio::multicast.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "100" ]
}

@test "multicast.network_rx extracts the network_rx stat" {
    bashio::api.supervisor() {
        printf '%s' '{"network_rx":200}'
    }
    run bashio::multicast.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "200" ]
}

@test "multicast.blk_read extracts the blk_read stat" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_read":300}'
    }
    run bashio::multicast.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "300" ]
}

@test "multicast.blk_write extracts the blk_write stat" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_write":400}'
    }
    run bashio::multicast.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "400" ]
}
