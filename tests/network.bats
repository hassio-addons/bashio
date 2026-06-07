#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/network.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::network`/`bashio::network.interface` fetchers, jq filtering, and
# caching run. The cache is pointed at a per-test temporary directory so tests
# stay isolated.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# ------------------------------------------------------------------------------
# bashio::network.reload
# ------------------------------------------------------------------------------

@test "network.reload calls the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /network/reload" ]
}

@test "network.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::network.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network (info fetcher)
# ------------------------------------------------------------------------------

@test "network fetches the info endpoint and returns the raw body" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"host_internet":true}'
    }
    run bashio::network
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /network/info false" ]
    [ "${output}" = '{"host_internet":true}' ]
}

@test "network applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"host_internet":true,"supervisor_internet":false}'
    }
    run bashio::network 'network.info.custom' '.supervisor_internet'
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "network reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::network
    [ "${status}" -ne 0 ]
}

@test "network serves a previously cached value without calling the API" {
    bashio::cache.set 'network.info.cached' 'cached-net'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network 'network.info.cached'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-net" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::network.host_internet
# ------------------------------------------------------------------------------

@test "network.host_internet returns the host internet state" {
    bashio::api.supervisor() {
        printf '%s' '{"host_internet":true}'
    }
    run bashio::network.host_internet
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "network.host_internet propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.host_internet
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.supervisor_internet
# ------------------------------------------------------------------------------

@test "network.supervisor_internet returns the supervisor internet state" {
    bashio::api.supervisor() {
        printf '%s' '{"supervisor_internet":false}'
    }
    run bashio::network.supervisor_internet
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "network.supervisor_internet propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.supervisor_internet
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.interfaces
# ------------------------------------------------------------------------------

@test "network.interfaces lists the interface names" {
    bashio::api.supervisor() {
        printf '%s' '{"interfaces":[{"interface":"eth0"},{"interface":"wlan0"}]}'
    }
    run bashio::network.interfaces
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "eth0" ]
    [ "${lines[1]}" = "wlan0" ]
}

@test "network.interfaces propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.interfaces
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.interface (per-interface fetcher)
# ------------------------------------------------------------------------------

@test "network.interface fetches the default interface info endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"interface":"eth0"}'
    }
    run bashio::network.interface
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /network/interface/default/info false" ]
    [ "${output}" = '{"interface":"eth0"}' ]
}

@test "network.interface fetches a named interface info endpoint" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"interface":"eth0"}'
    }
    run bashio::network.interface 'network.interface.eth0.info' 'eth0'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /network/interface/eth0/info false" ]
}

@test "network.interface with the dynamic base key and a filter does not corrupt the base blob" {
    # The per-interface base key is dynamic; passing it together with a filter
    # must not overwrite the shared blob with the filtered scalar.
    bashio::api.supervisor() {
        printf '%s' '{"interface":"eth0","type":"ethernet"}'
    }
    run bashio::network.interface 'network.interface.eth0.info' 'eth0' '.type'
    [ "${status}" -eq 0 ]
    [ "${output}" = "ethernet" ]
    run bashio::cache.get 'network.interface.eth0.info'
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -r '.interface')" = "eth0" ]
    # A repeated base-key+filter call must still apply the filter, not return
    # the cached unfiltered blob.
    run bashio::network.interface 'network.interface.eth0.info' 'eth0' '.type'
    [ "${status}" -eq 0 ]
    [ "${output}" = "ethernet" ]
}

@test "network.interface applies a jq filter to the info response" {
    bashio::api.supervisor() {
        printf '%s' '{"interface":"eth0","type":"ethernet"}'
    }
    run bashio::network.interface 'network.interface.eth0.info.type' 'eth0' '.type'
    [ "${status}" -eq 0 ]
    [ "${output}" = "ethernet" ]
}

@test "network.interface reports failure when the API call fails" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.interface
    [ "${status}" -ne 0 ]
}

@test "network.interface serves a previously cached value without calling the API" {
    bashio::cache.set 'network.interface.eth0.info' 'cached-iface'
    bashio::api.supervisor() { echo "called" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network.interface 'network.interface.eth0.info' 'eth0'
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-iface" ]
    [ ! -f "${BATS_TEST_TMPDIR}/call" ]
}

# ------------------------------------------------------------------------------
# bashio::network.name
# ------------------------------------------------------------------------------

@test "network.name returns the interface name" {
    bashio::api.supervisor() {
        printf '%s' '{"interface":"eth0"}'
    }
    run bashio::network.name
    [ "${status}" -eq 0 ]
    [ "${output}" = "eth0" ]
}

@test "network.name forwards a named interface to the API resource" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"interface":"wlan0"}'
    }
    run bashio::network.name 'wlan0'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /network/interface/wlan0/info false" ]
    [ "${output}" = "wlan0" ]
}

@test "network.name propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.name
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.type
# ------------------------------------------------------------------------------

@test "network.type returns the interface type" {
    bashio::api.supervisor() {
        printf '%s' '{"type":"ethernet"}'
    }
    run bashio::network.type
    [ "${status}" -eq 0 ]
    [ "${output}" = "ethernet" ]
}

@test "network.type propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.type
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.enabled (getter and setter)
# ------------------------------------------------------------------------------

@test "network.enabled returns the enabled state when no value is given" {
    bashio::api.supervisor() {
        printf '%s' '{"enabled":true}'
    }
    run bashio::network.enabled
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "network.enabled posts the enabled state as raw JSON when setting" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network.enabled 'eth0' 'true'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /network/interface/eth0/update {"enabled":true}' ]
}

@test "network.enabled setter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::network.enabled 'eth0' 'true' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "network.enabled normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::network.enabled 'eth0' 'true,"ipv4":{"method":"disabled"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"enabled":false}' ]
    run jq -e 'has("ipv4")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "network.enabled getter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.enabled
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.connected
# ------------------------------------------------------------------------------

@test "network.connected returns the connected state" {
    bashio::api.supervisor() {
        printf '%s' '{"connected":true}'
    }
    run bashio::network.connected
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "network.connected propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.connected
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv4_method
# ------------------------------------------------------------------------------

@test "network.ipv4_method returns the ipv4 method" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv4":{"method":"auto"}}'
    }
    run bashio::network.ipv4_method
    [ "${status}" -eq 0 ]
    [ "${output}" = "auto" ]
}

@test "network.ipv4_method propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv4_method
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv6_method
# ------------------------------------------------------------------------------

@test "network.ipv6_method returns the ipv6 method" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv6":{"method":"auto"}}'
    }
    run bashio::network.ipv6_method
    [ "${status}" -eq 0 ]
    [ "${output}" = "auto" ]
}

@test "network.ipv6_method propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv6_method
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv4_address
# ------------------------------------------------------------------------------

@test "network.ipv4_address lists the ipv4 addresses" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv4":{"address":["192.168.1.10/24","10.0.0.2/16"]}}'
    }
    run bashio::network.ipv4_address
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "192.168.1.10/24" ]
    [ "${lines[1]}" = "10.0.0.2/16" ]
}

@test "network.ipv4_address propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv4_address
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv6_address
# ------------------------------------------------------------------------------

@test "network.ipv6_address lists the ipv6 addresses" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv6":{"address":["2001:db8::1/64"]}}'
    }
    run bashio::network.ipv6_address
    [ "${status}" -eq 0 ]
    [ "${output}" = "2001:db8::1/64" ]
}

@test "network.ipv6_address propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv6_address
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv4_nameservers
# ------------------------------------------------------------------------------

@test "network.ipv4_nameservers lists the ipv4 nameservers" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv4":{"nameservers":["1.1.1.1","8.8.8.8"]}}'
    }
    run bashio::network.ipv4_nameservers
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "1.1.1.1" ]
    [ "${lines[1]}" = "8.8.8.8" ]
}

@test "network.ipv4_nameservers propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv4_nameservers
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv6_nameservers
# ------------------------------------------------------------------------------

@test "network.ipv6_nameservers lists the ipv6 nameservers" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv6":{"nameservers":["2606:4700:4700::1111"]}}'
    }
    run bashio::network.ipv6_nameservers
    [ "${status}" -eq 0 ]
    [ "${output}" = "2606:4700:4700::1111" ]
}

@test "network.ipv6_nameservers propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv6_nameservers
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv4_gateway
# ------------------------------------------------------------------------------

@test "network.ipv4_gateway returns the ipv4 gateway" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv4":{"gateway":"192.168.1.1"}}'
    }
    run bashio::network.ipv4_gateway
    [ "${status}" -eq 0 ]
    [ "${output}" = "192.168.1.1" ]
}

@test "network.ipv4_gateway propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv4_gateway
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv6_gateway
# ------------------------------------------------------------------------------

@test "network.ipv6_gateway returns the ipv6 gateway" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv6":{"gateway":"fe80::1"}}'
    }
    run bashio::network.ipv6_gateway
    [ "${status}" -eq 0 ]
    [ "${output}" = "fe80::1" ]
}

@test "network.ipv6_gateway propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv6_gateway
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv4 (getter and setter)
# ------------------------------------------------------------------------------

@test "network.ipv4 returns the ipv4 settings object when no value is given" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv4":{"method":"auto","gateway":"192.168.1.1"}}'
    }
    run bashio::network.ipv4
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -c '.method')" = '"auto"' ]
}

@test "network.ipv4 posts the settings as raw JSON when setting" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network.ipv4 'eth0' '{"method":"auto"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /network/interface/eth0/update {"ipv4":{"method":"auto"}}' ]
}

@test "network.ipv4 setter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::network.ipv4 'eth0' '{"method":"auto"}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "network.ipv4 getter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv4
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::network.ipv6 (getter and setter)
# ------------------------------------------------------------------------------

@test "network.ipv6 returns the ipv6 settings object when no value is given" {
    bashio::api.supervisor() {
        printf '%s' '{"ipv6":{"method":"auto","gateway":"fe80::1"}}'
    }
    run bashio::network.ipv6
    [ "${status}" -eq 0 ]
    [ "$(printf '%s' "${output}" | jq -c '.method')" = '"auto"' ]
}

@test "network.ipv6 posts the settings as raw JSON when setting" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::network.ipv6 'eth0' '{"method":"auto"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /network/interface/eth0/update {"ipv6":{"method":"auto"}}' ]
}

@test "network.ipv6 setter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::network.ipv6 'eth0' '{"method":"auto"}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "network.ipv6 getter propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    run bashio::network.ipv6
    [ "${status}" -ne 0 ]
}
