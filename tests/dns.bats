#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/dns.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::dns`/`bashio::dns.stats` fetchers, jq filtering, and caching run. The
# cache is pointed at a per-test temporary directory so tests stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::dns.update
# ------------------------------------------------------------------------------

@test "dns.update without a version posts to the update endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.update
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /dns/update" ]
}

@test "dns.update with a version sends it as a JSON options object" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.update "2024.1.0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /dns/update {"version":"2024.1.0"}' ]
}

@test "dns.update reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::dns.update "2024.1.0" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "dns.update without a version reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::dns.update || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.reset
# ------------------------------------------------------------------------------

@test "dns.reset calls the reset endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.reset
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /dns/reset" ]
}

@test "dns.reset reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::dns.reset || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.restart
# ------------------------------------------------------------------------------

@test "dns.restart calls the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.restart
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /dns/restart" ]
}

@test "dns.restart propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::dns.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.logs
# ------------------------------------------------------------------------------

@test "dns.logs fetches the raw logs endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.logs
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /dns/logs true" ]
}

@test "dns.logs propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.logs
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns (info fetcher)
# ------------------------------------------------------------------------------

@test "dns fetches the info endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"version":"1.0","host":"172.30.32.3"}'
    }
    run bashio::dns
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /dns/info false" ]
    [ "${output}" = '{"version":"1.0","host":"172.30.32.3"}' ]
}

@test "dns applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","host":"172.30.32.3"}'
    }
    run bashio::dns 'dns.info.custom' '.host'
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.3" ]
}

@test "dns reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns
    [ "${status}" -ne 0 ]
}

@test "dns with the base key and a filter does not corrupt the base blob" {
    # Passing the reserved base key together with a filter must not overwrite
    # the shared blob with the filtered scalar; later unfiltered reads must
    # still return the full object.
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0","host":"172.30.32.3"}'
    }
    run bashio::dns 'dns.info' '.host'
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.3" ]
    run bashio::cache.get 'dns.info'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.host')" = "172.30.32.3" ]
}

@test "dns serves a previously cached value without calling the API" {
    bashio::cache.set 'dns.info.cached' 'cached-value'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns 'dns.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::dns.host
# ------------------------------------------------------------------------------

@test "dns.host extracts the host from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"host":"172.30.32.3"}'
    }
    run bashio::dns.host
    [ "${status}" -eq 0 ]
    [ "${output}" = "172.30.32.3" ]
}

@test "dns.host propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.host
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.version
# ------------------------------------------------------------------------------

@test "dns.version extracts the version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.2.3"}'
    }
    run bashio::dns.version
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.2.3" ]
}

@test "dns.version propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.version
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.version_latest
# ------------------------------------------------------------------------------

@test "dns.version_latest extracts the latest version from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"version_latest":"2.0.0"}'
    }
    run bashio::dns.version_latest
    [ "${status}" -eq 0 ]
    [ "${output}" = "2.0.0" ]
}

@test "dns.version_latest propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.version_latest
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.update_available
# ------------------------------------------------------------------------------

@test "dns.update_available returns the boolean from the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"update_available":true}'
    }
    run bashio::dns.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "dns.update_available defaults to false when the key is missing" {
    bashio::api.supervisor() {
        printf '%s' '{"version":"1.0"}'
    }
    run bashio::dns.update_available
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "dns.update_available propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.update_available
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.locals
# ------------------------------------------------------------------------------

@test "dns.locals lists the local DNS servers" {
    bashio::api.supervisor() {
        printf '%s' '{"locals":["dns://1.1.1.1","dns://8.8.8.8"]}'
    }
    run bashio::dns.locals
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "dns://1.1.1.1" ]
    [ "${lines[1]}" = "dns://8.8.8.8" ]
}

@test "dns.locals propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.locals
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.servers
# ------------------------------------------------------------------------------

@test "dns.servers lists the configured DNS servers" {
    bashio::api.supervisor() {
        printf '%s' '{"servers":["dns://9.9.9.9"]}'
    }
    run bashio::dns.servers
    [ "${status}" -eq 0 ]
    [ "${output}" = "dns://9.9.9.9" ]
}

@test "dns.servers propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.servers
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.stats (stats fetcher)
# ------------------------------------------------------------------------------

@test "dns.stats fetches the stats endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::dns.stats
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /dns/stats false" ]
    [ "${output}" = '{"cpu_percent":1.5}' ]
}

@test "dns.stats applies a jq filter to the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":1.5}'
    }
    run bashio::dns.stats 'dns.stats.custom' '.cpu_percent'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
}

@test "dns.stats reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.stats
    [ "${status}" -ne 0 ]
}

@test "dns.stats serves a previously cached value without calling the API" {
    bashio::cache.set 'dns.stats.cached' 'cached-stats'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::dns.stats 'dns.stats.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-stats" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::dns.cpu_percent
# ------------------------------------------------------------------------------

@test "dns.cpu_percent extracts the cpu usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"cpu_percent":12.5}'
    }
    run bashio::dns.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.5" ]
}

@test "dns.cpu_percent propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.cpu_percent
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.memory_usage
# ------------------------------------------------------------------------------

@test "dns.memory_usage extracts the memory usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_usage":1024}'
    }
    run bashio::dns.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "1024" ]
}

@test "dns.memory_usage propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.memory_usage
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.memory_limit
# ------------------------------------------------------------------------------

@test "dns.memory_limit extracts the memory limit from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_limit":2048}'
    }
    run bashio::dns.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}

@test "dns.memory_limit propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.memory_limit
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.memory_percent
# ------------------------------------------------------------------------------

@test "dns.memory_percent extracts the memory percentage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"memory_percent":50}'
    }
    run bashio::dns.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "50" ]
}

@test "dns.memory_percent propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.memory_percent
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.network_tx
# ------------------------------------------------------------------------------

@test "dns.network_tx extracts the outgoing network usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"network_tx":777}'
    }
    run bashio::dns.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "777" ]
}

@test "dns.network_tx propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.network_tx
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.network_rx
# ------------------------------------------------------------------------------

@test "dns.network_rx extracts the incoming network usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"network_rx":888}'
    }
    run bashio::dns.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "888" ]
}

@test "dns.network_rx propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.network_rx
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.blk_read
# ------------------------------------------------------------------------------

@test "dns.blk_read extracts the disk read usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_read":111}'
    }
    run bashio::dns.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "111" ]
}

@test "dns.blk_read propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.blk_read
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::dns.blk_write
# ------------------------------------------------------------------------------

@test "dns.blk_write extracts the disk write usage from the stats response" {
    bashio::api.supervisor() {
        printf '%s' '{"blk_write":222}'
    }
    run bashio::dns.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "222" ]
}

@test "dns.blk_write propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::dns.blk_write
    [ "${status}" -ne 0 ]
}
