#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/backups.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::backups` fetcher, jq filtering, and caching run. The cache is pointed
# at a per-test temporary directory so tests stay isolated. The stub records the
# forwarded method/resource/options/filter to a file so they can be asserted,
# and can be made to fail (return 1) to verify error propagation.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# backups.reload
# ------------------------------------------------------------------------------

@test "backups.reload posts to the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /backups/reload" ]
}

@test "backups.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backups.freeze
# ------------------------------------------------------------------------------

@test "backups.freeze without a timeout posts no options" {
    bashio::api.supervisor() { printf '%s\n' "$@" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.freeze
    [ "${status}" -eq 0 ]
    [ "$(sed -n '1p' "${BATS_TEST_TMPDIR}/call")" = "POST" ]
    [ "$(sed -n '2p' "${BATS_TEST_TMPDIR}/call")" = "/backups/freeze" ]
    [ "$(sed -n '3p' "${BATS_TEST_TMPDIR}/call")" = "" ]
}

@test "backups.freeze with a timeout posts the timeout as JSON options" {
    bashio::api.supervisor() { printf '%s\n' "$@" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.freeze "30"
    [ "${status}" -eq 0 ]
    [ "$(sed -n '1p' "${BATS_TEST_TMPDIR}/call")" = "POST" ]
    [ "$(sed -n '2p' "${BATS_TEST_TMPDIR}/call")" = "/backups/freeze" ]
    [ "$(sed -n '3p' "${BATS_TEST_TMPDIR}/call")" = '{"timeout":30}' ]
}

@test "backups.freeze propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups.freeze "30" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backups.freeze rejects a non-integer timeout without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::backups.freeze '30,"foo":1' || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "backups.freeze accepts a zero timeout" {
    bashio::api.supervisor() { printf '%s\n' "$@" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.freeze "0"
    [ "${status}" -eq 0 ]
    [ "$(sed -n '3p' "${BATS_TEST_TMPDIR}/call")" = '{"timeout":0}' ]
}

@test "backups.freeze rejects a leading-zero timeout without calling the API" {
    # A leading zero (e.g. "007") would embed as invalid JSON, so reject it.
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::backups.freeze "007" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# backups.thaw
# ------------------------------------------------------------------------------

@test "backups.thaw posts to the thaw endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.thaw
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /backups/thaw" ]
}

@test "backups.thaw propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups.thaw || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backups.days_until_stale
# ------------------------------------------------------------------------------

@test "backups.days_until_stale without a value reads it from the info" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"days_until_stale":30}'
    }
    run bashio::backups.days_until_stale
    [ "${status}" -eq 0 ]
    [ "${output}" = "30" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /backups/info false" ]
}

@test "backups.days_until_stale with a value posts it as JSON options" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.days_until_stale "10"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/options {"days_until_stale":10}' ]
}

@test "backups.days_until_stale propagates a set failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups.days_until_stale "10" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backups.days_until_stale rejects a non-integer value without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::backups.days_until_stale '10,"foo":1' || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

@test "backups.days_until_stale accepts a zero value" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups.days_until_stale "0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/options {"days_until_stale":0}' ]
}

@test "backups.days_until_stale rejects a leading-zero value without calling the API" {
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    rc=0
    bashio::backups.days_until_stale "007" || rc=$?
    [ "${rc}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# backups (the generic fetcher)
# ------------------------------------------------------------------------------

@test "backups without a slug lists all backup slugs" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"backups":[{"slug":"aaa"},{"slug":"bbb"}]}'
    }
    run bashio::backups
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /backups/info false" ]
    [ "${lines[0]}" = "aaa" ]
    [ "${lines[1]}" = "bbb" ]
}

@test "backups with a slug fetches that backup info and caches it" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"slug":"aaa","name":"My backup"}'
    }
    run bashio::backups "aaa" "backups.aaa.name" '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "My backup" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /backups/aaa/info false" ]
    [ -f "${__BASHIO_CACHE_DIR}/backups.aaa.name.cache" ]
    [ -f "${__BASHIO_CACHE_DIR}/backups.aaa.info.cache" ]
}

@test "backups returns a cached result without calling the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' "cached-value" >"${__BASHIO_CACHE_DIR}/some.key.cache"
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups "aaa" "some.key" '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "backups reuses the cached backup info for a slug" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' '{"slug":"aaa","name":"From cache"}' \
        >"${__BASHIO_CACHE_DIR}/backups.aaa.info.cache"
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backups "aaa" false '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "From cache" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

@test "backups with filter 'false' returns the raw info untouched" {
    bashio::api.supervisor() { printf '%s' '{"slug":"aaa"}'; }
    run bashio::backups "aaa" false false
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"slug":"aaa"}' ]
}

@test "backups propagates a failure to list all backups" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backups propagates a failure to fetch a single backup" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backups "aaa" false '.name' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backups fails when the jq filter is invalid" {
    bashio::api.supervisor() { printf '%s' '{"slug":"aaa"}'; }
    rc=0
    bashio::backups "aaa" false '.[' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backup.* accessors (slug, cache key, and filter forwarding)
# ------------------------------------------------------------------------------

@test "backup.type forwards the slug, cache key and filter" {
    bashio::api.supervisor() {
        echo "$2" >"${BATS_TEST_TMPDIR}/resource"
        printf '%s' '{"type":"full"}'
    }
    run bashio::backup.type "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "full" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/resource")" = "/backups/aaa/info" ]
    [ -f "${__BASHIO_CACHE_DIR}/backups.aaa.type.cache" ]
}

@test "backup.name returns the backup name" {
    bashio::api.supervisor() { printf '%s' '{"name":"Nightly"}'; }
    run bashio::backup.name "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Nightly" ]
}

@test "backup.date returns the backup date" {
    bashio::api.supervisor() { printf '%s' '{"date":"2024-01-01T00:00:00Z"}'; }
    run bashio::backup.date "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024-01-01T00:00:00Z" ]
}

@test "backup.size returns the backup size" {
    bashio::api.supervisor() { printf '%s' '{"size":12.5}'; }
    run bashio::backup.size "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "12.5" ]
}

@test "backup.size_bytes returns the backup size in bytes" {
    bashio::api.supervisor() { printf '%s' '{"size_bytes":1048576}'; }
    run bashio::backup.size_bytes "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1048576" ]
}

@test "backup.protected returns the protected flag" {
    bashio::api.supervisor() { printf '%s' '{"protected":true}'; }
    run bashio::backup.protected "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "backup.location returns the location when present" {
    bashio::api.supervisor() { printf '%s' '{"location":"Network share"}'; }
    run bashio::backup.location "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Network share" ]
}

@test "backup.location returns empty when the location is null" {
    bashio::api.supervisor() { printf '%s' '{"location":null}'; }
    run bashio::backup.location "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.homeassistant_version returns the version when present" {
    bashio::api.supervisor() { printf '%s' '{"homeassistant":"2024.1.0"}'; }
    run bashio::backup.homeassistant_version "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "backup.homeassistant_version returns empty when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::backup.homeassistant_version "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.supervisor_version returns the version when present" {
    bashio::api.supervisor() { printf '%s' '{"supervisor_version":"2024.1.0"}'; }
    run bashio::backup.supervisor_version "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2024.1.0" ]
}

@test "backup.supervisor_version returns empty when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::backup.supervisor_version "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.addons returns the addon list when non-empty" {
    bashio::api.supervisor() { printf '%s' '{"addons":[{"slug":"core_ssh"}]}'; }
    run bashio::backup.addons "aaa"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"core_ssh"* ]]
}

@test "backup.addons returns empty when the addon list is empty" {
    bashio::api.supervisor() { printf '%s' '{"addons":[]}'; }
    run bashio::backup.addons "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.repositories returns the list when non-empty" {
    bashio::api.supervisor() { printf '%s' '{"repositories":["core"]}'; }
    run bashio::backup.repositories "aaa"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"core"* ]]
}

@test "backup.repositories returns empty when the list is empty" {
    bashio::api.supervisor() { printf '%s' '{"repositories":[]}'; }
    run bashio::backup.repositories "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.folders returns the list when non-empty" {
    bashio::api.supervisor() { printf '%s' '{"folders":["share"]}'; }
    run bashio::backup.folders "aaa"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"share"* ]]
}

@test "backup.folders returns empty when the list is empty" {
    bashio::api.supervisor() { printf '%s' '{"folders":[]}'; }
    run bashio::backup.folders "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "backup.homeassistant_exclude_database returns the flag when present" {
    bashio::api.supervisor() {
        printf '%s' '{"homeassistant_exclude_database":true}'
    }
    run bashio::backup.homeassistant_exclude_database "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "backup.homeassistant_exclude_database defaults to false when missing" {
    bashio::api.supervisor() { printf '%s' '{}'; }
    run bashio::backup.homeassistant_exclude_database "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "backup.compressed returns the compressed flag" {
    bashio::api.supervisor() { printf '%s' '{"compressed":true}'; }
    run bashio::backup.compressed "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "backup.homeassistant selects the slug from the full backup list" {
    bashio::api.supervisor() {
        echo "$2" >"${BATS_TEST_TMPDIR}/resource"
        printf '%s' '{"backups":[{"slug":"aaa","content":{"homeassistant":true}}]}'
    }
    run bashio::backup.homeassistant "aaa"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
    # It uses the full backups list, not the per-backup info endpoint.
    [ "$(cat "${BATS_TEST_TMPDIR}/resource")" = "/backups/info" ]
}

@test "backup.type propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.type "aaa" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backup.new_full / backup.new_partial
# ------------------------------------------------------------------------------

@test "backup.new_full posts the options to the new/full endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backup.new_full '{"name":"My backup"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/new/full {"name":"My backup"}' ]
}

@test "backup.new_full propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.new_full '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backup.new_partial posts the options to the new/partial endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backup.new_partial '{"addons":["core_ssh"]}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/new/partial {"addons":["core_ssh"]}' ]
}

@test "backup.new_partial propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.new_partial '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backup.delete
# ------------------------------------------------------------------------------

@test "backup.delete deletes the backup by slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backup.delete "aaa"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "DELETE /backups/aaa" ]
}

@test "backup.delete propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.delete "aaa" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# backup.restore_full / backup.restore_partial
# ------------------------------------------------------------------------------

@test "backup.restore_full posts the slug and options to the restore endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backup.restore_full "aaa" '{"password":"x"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/aaa/restore/full {"password":"x"}' ]
}

@test "backup.restore_full propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.restore_full "aaa" '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "backup.restore_partial posts the slug and options to the restore endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::backup.restore_partial "aaa" '{"addons":["core_ssh"]}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /backups/aaa/restore/partial {"addons":["core_ssh"]}' ]
}

@test "backup.restore_partial propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::backup.restore_partial "aaa" '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}
