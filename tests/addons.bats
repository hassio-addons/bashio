#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/addons.sh.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

@test "addons.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::addons.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::addon.update "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.option stores the value as a literal string (no JSON injection)" {
    bashio::addon.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{"existing":"x"}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::addon.option "name" 'a","injected":"b'
    # The crafted value is stored verbatim as a string...
    [ "$(jq -r '.name' <"${BATS_TEST_TMPDIR}/opts")" = 'a","injected":"b' ]
    # ...and must not have injected a separate key.
    run jq -e 'has("injected")' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -ne 0 ]
}

@test "addon.option sets a raw JSON value with the ^ prefix" {
    bashio::addon.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::addon.option "enabled" "^true"
    run jq -e '.enabled == true' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -eq 0 ]
}
