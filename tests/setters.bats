#!/usr/bin/env bats
# ==============================================================================
# Cross-module regression tests for Supervisor API setters.
#
# Every setter that POSTs to the Supervisor API and then flushes the cache must
# report a failure when the API call fails, even when invoked in a conditional
# context (where errexit is suppressed). The `setter || rc=$?` form reproduces
# that context; with the trailing cache flush the failure used to be masked.
#
# One representative setter per touched module is covered here; supervisor.sh is
# additionally covered in supervisor.bats.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
    # Make every Supervisor API call fail.
    bashio::api.supervisor() { return 1; }
}

@test "addons.reload propagates an API failure" {
    rc=0
    bashio::addons.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.update propagates an API failure" {
    rc=0
    bashio::addon.update "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "audio.reload propagates an API failure" {
    rc=0
    bashio::audio.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backups.reload propagates an API failure" {
    rc=0
    bashio::backups.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "cli.update propagates an API failure" {
    rc=0
    bashio::cli.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "core.update propagates an API failure" {
    rc=0
    bashio::core.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "core.image propagates an API failure" {
    rc=0
    bashio::core.image "ghcr.io/example/image" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "dns.restart propagates an API failure" {
    rc=0
    bashio::dns.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "host.hostname propagates an API failure" {
    rc=0
    bashio::host.hostname "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "jobs.reset propagates an API failure" {
    rc=0
    bashio::jobs.reset || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "multicast.restart propagates an API failure" {
    rc=0
    bashio::multicast.restart || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "network.reload propagates an API failure" {
    rc=0
    bashio::network.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "os.update propagates an API failure" {
    rc=0
    bashio::os.update || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "repository.add propagates an API failure" {
    rc=0
    bashio::repository.add "https://example.com/repository" || rc=$?
    [ "${rc}" -ne 0 ]
}
