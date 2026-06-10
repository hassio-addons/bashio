#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/apps.sh.
#
# These tests stub the API boundary (`bashio::api.supervisor`) and let the real
# `bashio::apps` fetcher, jq filtering, and caching run. The cache is pointed
# at a per-test temporary directory so tests stay isolated. Stubs record their
# arguments via "$*" and the assertions check the EXACT call string (method,
# resource, filter/JSON), so they pin down the contract rather than fragments.
#
# A few setters end with `bashio::cache.flush_all`, which removes the cache
# directory. Where a setter is exercised the cache dir is recreated implicitly
# by the next `bashio::cache.set`, so tests do not rely on it surviving.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"
}

# A canned store listing used by the fetcher to determine the install state of
# a slug, and the per-addon info responses returned afterwards.
store_listing() {
    printf '%s' '{"addons":[
        {"slug":"alpha","installed":true},
        {"slug":"beta","installed":false}
    ]}'
}

# ------------------------------------------------------------------------------
# Action helpers: simple POST/GET passthroughs.
# ------------------------------------------------------------------------------

@test "addons.reload posts to the reload endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::apps.reload
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/reload" ]
}

@test "addons.reload propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::apps.reload || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.start posts to the start endpoint for a given slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.start "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/example/start" ]
}

@test "addon.start defaults to the self slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.start
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/self/start" ]
}

@test "addon.restart posts to the restart endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.restart "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/example/restart" ]
}

@test "addon.stop posts to the stop endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.stop "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/example/stop" ]
}

@test "addon.rebuild posts to the rebuild endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.rebuild "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/example/rebuild" ]
}

@test "addon.install posts to the store install endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.install "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /store/addons/example/install" ]
}

@test "addon.install propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.install "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.uninstall posts to the uninstall endpoint" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.uninstall "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /addons/example/uninstall" ]
}

@test "addon.uninstall propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.uninstall "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.update posts to the store update endpoint for an explicit slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.update "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /store/addons/example/update" ]
}

@test "addon.update resolves self to a concrete slug before posting" {
    # self is not valid on the store endpoint, so the resolver must swap it for
    # the real slug obtained via addon.slug.
    bashio::app.slug() { printf '%s' "resolved_self"; }
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.update "self"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "POST /store/addons/resolved_self/update" ]
}

@test "addon.update propagates an API failure" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.update "example" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.logs requests raw logs output" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.logs "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/example/logs true" ]
}

@test "addon.documentation requests raw documentation for an explicit slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.documentation "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/example/documentation true" ]
}

@test "addon.documentation resolves self before requesting" {
    bashio::app.slug() { printf '%s' "resolved_self"; }
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.documentation "self"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/resolved_self/documentation true" ]
}

@test "addon.changelog requests raw changelog for an explicit slug" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.changelog "example"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/example/changelog true" ]
}

@test "addon.changelog resolves self before requesting" {
    bashio::app.slug() { printf '%s' "resolved_self"; }
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.changelog "self"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/resolved_self/changelog true" ]
}

# ------------------------------------------------------------------------------
# The bashio::apps fetcher: list mode, slug mode, caching, filtering.
# ------------------------------------------------------------------------------

@test "addons lists every slug from the store listing" {
    bashio::api.supervisor() { store_listing; }
    run bashio::apps
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "alpha" ]
    [ "${lines[1]}" = "beta" ]
}

@test "addons caches the unfiltered store listing as store.addons.info" {
    bashio::api.supervisor() { store_listing; }
    bashio::apps >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/store.addons.info.cache" ]
    run jq -r '.addons | length' <"${__BASHIO_CACHE_DIR}/store.addons.info.cache"
    [ "${output}" = "2" ]
}

@test "addons caches the filtered list under the default cache key" {
    bashio::api.supervisor() { store_listing; }
    bashio::apps >/dev/null
    [ -f "${__BASHIO_CACHE_DIR}/addons.list.cache" ]
    run cat "${__BASHIO_CACHE_DIR}/addons.list.cache"
    [ "${lines[0]}" = "alpha" ]
    [ "${lines[1]}" = "beta" ]
}

@test "addons serves the filtered list from cache without hitting the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' "cached-value" >"${__BASHIO_CACHE_DIR}/addons.list.cache"
    bashio::api.supervisor() {
        echo "API SHOULD NOT BE CALLED"
        return 1
    }
    run bashio::apps
    [ "${status}" -eq 0 ]
    [ "${output}" = "cached-value" ]
}

@test "addons reuses the cached store.addons.info instead of calling the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    store_listing >"${__BASHIO_CACHE_DIR}/store.addons.info.cache"
    bashio::api.supervisor() {
        echo "API SHOULD NOT BE CALLED"
        return 1
    }
    run bashio::apps
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "alpha" ]
    [ "${lines[1]}" = "beta" ]
}

@test "addons fails when the store listing API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::apps >/dev/null || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addons for an installed slug fetches from the addons info endpoint" {
    # The first call returns the store listing (alpha is installed), the second
    # must therefore target the installed-addon info endpoint.
    bashio::api.supervisor() {
        echo "$*" >>"${BATS_TEST_TMPDIR}/calls"
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"alpha"}'
        fi
    }
    run bashio::apps "alpha"
    [ "${status}" -eq 0 ]
    [ "${output}" = "alpha" ]
    run cat "${BATS_TEST_TMPDIR}/calls"
    [ "${lines[0]}" = "GET /store/addons false" ]
    [ "${lines[1]}" = "GET /addons/alpha/info false" ]
}

@test "addons for an uninstalled slug fetches from the store addon endpoint" {
    bashio::api.supervisor() {
        echo "$*" >>"${BATS_TEST_TMPDIR}/calls"
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"beta"}'
        fi
    }
    run bashio::apps "beta"
    [ "${status}" -eq 0 ]
    [ "${output}" = "beta" ]
    run cat "${BATS_TEST_TMPDIR}/calls"
    [ "${lines[1]}" = "GET /store/addons/beta false" ]
}

@test "addons for the self slug uses the installed info endpoint without consulting the store listing" {
    # self is known to be installed, so the restricted /store/addons listing
    # must not be consulted at all; the only call is the installed-info endpoint.
    bashio::api.supervisor() {
        echo "$*" >>"${BATS_TEST_TMPDIR}/calls"
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"selfslug"}'
        fi
    }
    run bashio::apps "self"
    [ "${status}" -eq 0 ]
    [ "${output}" = "selfslug" ]
    run cat "${BATS_TEST_TMPDIR}/calls"
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "GET /addons/self/info false" ]
}

@test "addons for a cached slug does not consult the store listing" {
    # When the per-addon info is already cached, the install state is known, so
    # the restricted /store/addons listing must not be consulted.
    bashio::cache.set "addons.alpha.info" '{"slug":"alpha"}'
    bashio::api.supervisor() { echo "$*" >>"${BATS_TEST_TMPDIR}/calls"; }
    run bashio::apps "alpha"
    [ "${status}" -eq 0 ]
    [ "${output}" = "alpha" ]
    # No API call is made at all (neither the store listing nor the info endpoint).
    [ ! -f "${BATS_TEST_TMPDIR}/calls" ]
}

@test "addons applies a custom jq filter and caches under a custom key" {
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"alpha","name":"Alpha App"}'
        fi
    }
    run bashio::apps "alpha" "custom.key" '.name'
    [ "${status}" -eq 0 ]
    [ "${output}" = "Alpha App" ]
    [ -f "${__BASHIO_CACHE_DIR}/custom.key.cache" ]
    run cat "${__BASHIO_CACHE_DIR}/custom.key.cache"
    [ "${output}" = "Alpha App" ]
}

@test "addons with filter false returns the raw info unfiltered" {
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"alpha","name":"Alpha App"}'
        fi
    }
    run bashio::apps "alpha" false false
    [ "${status}" -eq 0 ]
    run jq -r '.name' <<<"${output}"
    [ "${output}" = "Alpha App" ]
}

@test "addons fails when the jq filter is invalid" {
    bashio::api.supervisor() { store_listing; }
    rc=0
    bashio::apps false false '.[' >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# installed / self helpers.
# ------------------------------------------------------------------------------

@test "addons.installed lists only installed slugs" {
    bashio::api.supervisor() { store_listing; }
    run bashio::apps.installed
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "alpha" ]
}

@test "addon.installed reports true for an installed addon" {
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"alpha","installed":true}'
        fi
    }
    run bashio::app.installed "alpha"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "addon.installed reports true when installed is null (addons API)" {
    # When info comes from the addons API the installed field is null, which the
    # filter coalesces to true.
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"alpha","installed":null}'
        fi
    }
    run bashio::app.installed "alpha"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "addon.slug returns the slug of self" {
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' '{"slug":"my_self_slug"}'
        fi
    }
    run bashio::app.slug
    [ "${status}" -eq 0 ]
    [ "${output}" = "my_self_slug" ]
}

# ------------------------------------------------------------------------------
# Scalar getters. These all flow through bashio::apps with a fixed filter; a
# representative set is checked end to end to confirm the filter and value.
# ------------------------------------------------------------------------------

# Fetches a single addon field for the "alpha" addon using the given JSON body.
get_field() {
    local body="$1"
    shift
    BODY="${body}"
    bashio::api.supervisor() {
        if [[ "$2" == "/store/addons" ]]; then
            store_listing
        else
            printf '%s' "${BODY}"
        fi
    }
    "$@" "alpha"
}

@test "addon.name returns the name field" {
    run get_field '{"slug":"alpha","name":"Alpha"}' bashio::app.name
    [ "${status}" -eq 0 ]
    [ "${output}" = "Alpha" ]
}

@test "addon.hostname returns the hostname field" {
    run get_field '{"slug":"alpha","hostname":"alpha-host"}' bashio::app.hostname
    [ "${output}" = "alpha-host" ]
}

@test "addon.description returns the description field" {
    run get_field '{"slug":"alpha","description":"Desc"}' bashio::app.description
    [ "${output}" = "Desc" ]
}

@test "addon.long_description returns the long_description field" {
    run get_field '{"slug":"alpha","long_description":"Long"}' bashio::app.long_description
    [ "${output}" = "Long" ]
}

@test "addon.url returns the url field" {
    run get_field '{"slug":"alpha","url":"http://x"}' bashio::app.url
    [ "${output}" = "http://x" ]
}

@test "addon.version returns the version field" {
    run get_field '{"slug":"alpha","version":"1.2.3"}' bashio::app.version
    [ "${output}" = "1.2.3" ]
}

@test "addon.version_latest returns the version_latest field" {
    run get_field '{"slug":"alpha","version_latest":"2.0.0"}' bashio::app.version_latest
    [ "${output}" = "2.0.0" ]
}

@test "addon.state returns the state field" {
    run get_field '{"slug":"alpha","state":"started"}' bashio::app.state
    [ "${output}" = "started" ]
}

@test "addon.stage returns the stage field" {
    run get_field '{"slug":"alpha","stage":"stable"}' bashio::app.stage
    [ "${output}" = "stable" ]
}

@test "addon.startup returns the startup field" {
    run get_field '{"slug":"alpha","startup":"application"}' bashio::app.startup
    [ "${output}" = "application" ]
}

@test "addon.repository returns the repository field" {
    run get_field '{"slug":"alpha","repository":"core"}' bashio::app.repository
    [ "${output}" = "core" ]
}

@test "addon.apparmor returns the apparmor field" {
    run get_field '{"slug":"alpha","apparmor":"default"}' bashio::app.apparmor
    [ "${output}" = "default" ]
}

@test "addon.hassio_role returns the role field" { # codespell:ignore hassio
    run get_field '{"slug":"alpha","hassio_role":"manager"}' bashio::app.hassio_role
    [ "${output}" = "manager" ]
}

@test "addon.homeassistant returns the minimal core version" {
    run get_field '{"slug":"alpha","homeassistant":"2024.1.0"}' bashio::app.homeassistant
    [ "${output}" = "2024.1.0" ]
}

@test "addon.rating returns the rating field" {
    run get_field '{"slug":"alpha","rating":6}' bashio::app.rating
    [ "${output}" = "6" ]
}

# ------------------------------------------------------------------------------
# Boolean getters with `// false` defaults: check both the explicit value and
# the fallback when the field is absent.
# ------------------------------------------------------------------------------

@test "addon.detached returns the detached value" {
    run get_field '{"slug":"alpha","detached":true}' bashio::app.detached
    [ "${output}" = "true" ]
}

@test "addon.detached defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.detached
    [ "${output}" = "false" ]
}

@test "addon.available returns the available value" {
    run get_field '{"slug":"alpha","available":true}' bashio::app.available
    [ "${output}" = "true" ]
}

@test "addon.advanced defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.advanced
    [ "${output}" = "false" ]
}

@test "addon.update_available returns the value" {
    run get_field '{"slug":"alpha","update_available":true}' bashio::app.update_available
    [ "${output}" = "true" ]
}

@test "addon.build defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.build
    [ "${output}" = "false" ]
}

@test "addon.host_network returns the value" {
    run get_field '{"slug":"alpha","host_network":true}' bashio::app.host_network
    [ "${output}" = "true" ]
}

@test "addon.host_pid defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.host_pid
    [ "${output}" = "false" ]
}

@test "addon.host_ipc returns the value" {
    run get_field '{"slug":"alpha","host_ipc":true}' bashio::app.host_ipc
    [ "${output}" = "true" ]
}

@test "addon.host_dbus defaults to false when absent" { # codespell:ignore dbus
    run get_field '{"slug":"alpha"}' bashio::app.host_dbus
    [ "${output}" = "false" ]
}

@test "addon.udev returns the value" {
    run get_field '{"slug":"alpha","udev":true}' bashio::app.udev
    [ "${output}" = "true" ]
}

@test "addon.uart defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.uart
    [ "${output}" = "false" ]
}

@test "addon.usb returns the value" {
    run get_field '{"slug":"alpha","usb":true}' bashio::app.usb
    [ "${output}" = "true" ]
}

@test "addon.icon defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.icon
    [ "${output}" = "false" ]
}

@test "addon.logo returns the value" {
    run get_field '{"slug":"alpha","logo":true}' bashio::app.logo
    [ "${output}" = "true" ]
}

@test "addon.has_documentation defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.has_documentation
    [ "${output}" = "false" ]
}

@test "addon.has_changelog returns the value" {
    run get_field '{"slug":"alpha","changelog":true}' bashio::app.has_changelog
    [ "${output}" = "true" ]
}

@test "addon.hassio_api defaults to false when absent" { # codespell:ignore hassio
    run get_field '{"slug":"alpha"}' bashio::app.hassio_api
    [ "${output}" = "false" ]
}

@test "addon.homeassistant_api returns the value" {
    run get_field '{"slug":"alpha","homeassistant_api":true}' bashio::app.homeassistant_api
    [ "${output}" = "true" ]
}

@test "addon.auth_api defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.auth_api
    [ "${output}" = "false" ]
}

@test "addon.protected returns the value" {
    run get_field '{"slug":"alpha","protected":true}' bashio::app.protected
    [ "${output}" = "true" ]
}

@test "addon.stdin defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.stdin
    [ "${output}" = "false" ]
}

@test "addon.full_access returns the value" {
    run get_field '{"slug":"alpha","full_access":true}' bashio::app.full_access
    [ "${output}" = "true" ]
}

@test "addon.gpio defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.gpio
    [ "${output}" = "false" ]
}

@test "addon.kernel_modules returns the value" {
    run get_field '{"slug":"alpha","kernel_modules":true}' bashio::app.kernel_modules
    [ "${output}" = "true" ]
}

@test "addon.devicetree defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.devicetree
    [ "${output}" = "false" ]
}

@test "addon.docker_api returns the value" {
    run get_field '{"slug":"alpha","docker_api":true}' bashio::app.docker_api
    [ "${output}" = "true" ]
}

@test "addon.video defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.video
    [ "${output}" = "false" ]
}

@test "addon.audio returns the value" {
    run get_field '{"slug":"alpha","audio":true}' bashio::app.audio
    [ "${output}" = "true" ]
}

@test "addon.ingress defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.ingress
    [ "${output}" = "false" ]
}

# ------------------------------------------------------------------------------
# Getters with `// empty` defaults: absent fields produce empty output.
# ------------------------------------------------------------------------------

@test "addon.webui returns the value" {
    run get_field '{"slug":"alpha","webui":"http://[HOST]"}' bashio::app.webui
    [ "${output}" = "http://[HOST]" ]
}

@test "addon.webui is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.webui
    [ "${output}" = "" ]
}

@test "addon.ip_address returns the value" {
    run get_field '{"slug":"alpha","ip_address":"172.30.0.2"}' bashio::app.ip_address
    [ "${output}" = "172.30.0.2" ]
}

@test "addon.ip_address is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.ip_address
    [ "${output}" = "" ]
}

@test "addon.ingress_entry returns the value" {
    run get_field '{"slug":"alpha","ingress_entry":"/api/ingress/x"}' bashio::app.ingress_entry
    [ "${output}" = "/api/ingress/x" ]
}

@test "addon.ingress_url returns the value" {
    run get_field '{"slug":"alpha","ingress_url":"/x/"}' bashio::app.ingress_url
    [ "${output}" = "/x/" ]
}

@test "addon.ingress_port returns the value" {
    run get_field '{"slug":"alpha","ingress_port":8099}' bashio::app.ingress_port
    [ "${output}" = "8099" ]
}

@test "addon.ingress_port is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.ingress_port
    [ "${output}" = "" ]
}

@test "addon.network_description is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.network_description
    [ "${output}" = "" ]
}

# ------------------------------------------------------------------------------
# List getters: arrays expanded one element per line.
# ------------------------------------------------------------------------------

@test "addon.dns lists each DNS name" {
    run get_field '{"slug":"alpha","dns":["dns1","dns2"]}' bashio::app.dns
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "dns1" ]
    [ "${lines[1]}" = "dns2" ]
}

@test "addon.dns is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.dns
    [ "${output}" = "" ]
}

@test "addon.arch lists each architecture" {
    run get_field '{"slug":"alpha","arch":["amd64","aarch64"]}' bashio::app.arch
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "amd64" ]
    [ "${lines[1]}" = "aarch64" ]
}

@test "addon.machine lists each machine type" {
    run get_field '{"slug":"alpha","machine":["raspberrypi","tinker"]}' bashio::app.machine
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "raspberrypi" ]
    [ "${lines[1]}" = "tinker" ]
}

@test "addon.privileged lists each privilege" {
    run get_field '{"slug":"alpha","privileged":["NET_ADMIN","SYS_TIME"]}' bashio::app.privileged
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "NET_ADMIN" ]
    [ "${lines[1]}" = "SYS_TIME" ]
}

@test "addon.devices lists each device" {
    run get_field '{"slug":"alpha","devices":["/dev/ttyUSB0","/dev/ttyUSB1"]}' bashio::app.devices
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "/dev/ttyUSB0" ]
    [ "${lines[1]}" = "/dev/ttyUSB1" ]
}

@test "addon.devices is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.devices
    [ "${output}" = "" ]
}

# ------------------------------------------------------------------------------
# Setter/getter helpers that POST options. For setters we assert the exact JSON
# body, and that a failing API call propagates.
# ------------------------------------------------------------------------------

@test "addon.auto_update reads the value when no second argument is given" {
    run get_field '{"slug":"alpha","auto_update":true}' bashio::app.auto_update
    [ "${output}" = "true" ]
}

@test "addon.auto_update defaults to false when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.auto_update
    [ "${output}" = "false" ]
}

@test "addon.auto_update posts the value as a raw boolean" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.auto_update "alpha" "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"auto_update":true}' ]
}

@test "addon.auto_update propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.auto_update "alpha" "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.auto_update normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    # A crafted value must not break out into additional options keys; anything
    # that is not strictly true is treated as false.
    run bashio::app.auto_update "alpha" 'true,"rootfs_path":"/"'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"auto_update":false}' ]
    run jq -e 'has("rootfs_path")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "addon.boot reads the value when no second argument is given" {
    run get_field '{"slug":"alpha","boot":"auto"}' bashio::app.boot
    [ "${output}" = "auto" ]
}

@test "addon.boot posts the value as a JSON string" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.boot "alpha" "manual"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"boot":"manual"}' ]
}

@test "addon.boot propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.boot "alpha" "manual" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.ingress_panel reads the value when no second argument is given" {
    run get_field '{"slug":"alpha","ingress_panel":true}' bashio::app.ingress_panel
    [ "${output}" = "true" ]
}

@test "addon.ingress_panel posts the value as a raw boolean" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.ingress_panel "alpha" "true"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"ingress_panel":true}' ]
}

@test "addon.ingress_panel normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::app.ingress_panel "alpha" 'true,"rootfs_path":"/"'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"ingress_panel":false}' ]
    run jq -e 'has("rootfs_path")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "addon.watchdog reads the value when no second argument is given" {
    run get_field '{"slug":"alpha","watchdog":true}' bashio::app.watchdog
    [ "${output}" = "true" ]
}

@test "addon.watchdog posts the value as a raw boolean" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.watchdog "alpha" "false"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"watchdog":false}' ]
}

@test "addon.watchdog normalizes the value and cannot inject extra options" {
    bashio::api.supervisor() { printf '%s' "$3" >"${BATS_TEST_TMPDIR}/body"; }
    run bashio::app.watchdog "alpha" 'true,"rootfs_path":"/"'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/body")" = '{"watchdog":false}' ]
    run jq -e 'has("rootfs_path")' <"${BATS_TEST_TMPDIR}/body"
    [ "${status}" -ne 0 ]
}

@test "addon.watchdog propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.watchdog "alpha" "true" || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.audio_input reads the value when no second argument is given" {
    run get_field '{"slug":"alpha","audio_input":"hw:1,0"}' bashio::app.audio_input
    [ "${output}" = "hw:1,0" ]
}

@test "addon.audio_input is empty when absent" {
    run get_field '{"slug":"alpha"}' bashio::app.audio_input
    [ "${output}" = "" ]
}

@test "addon.audio_input posts the value as a JSON string" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.audio_input "alpha" "hw:1,0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"audio_input":"hw:1,0"}' ]
}

@test "addon.audio_output posts the value as a JSON string" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.audio_output "alpha" "hw:0,0"
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"audio_output":"hw:0,0"}' ]
}

@test "addon.audio_output propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.audio_output "alpha" "hw:0,0" || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# addon.options: read mode and write mode.
# ------------------------------------------------------------------------------

@test "addon.options reads the options object" {
    run get_field '{"slug":"alpha","options":{"foo":"bar"}}' bashio::app.options
    [ "${status}" -eq 0 ]
    run jq -r '.foo' <<<"${output}"
    [ "${output}" = "bar" ]
}

@test "addon.options posts the given options as a raw JSON body" {
    # The second positional argument is wrapped under the options key as raw
    # JSON via the ^ prefix internally.
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.options "alpha" '{"foo":"bar"}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"options":{"foo":"bar"}}' ]
}

@test "addon.options propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.options "alpha" '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# addon.option: setting and clearing a single key. These pin the JSON-injection
# safety contract and the raw "^" prefix behaviour.
# ------------------------------------------------------------------------------

@test "addon.option stores the value as a literal string (no JSON injection)" {
    bashio::app.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{"existing":"x"}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::app.option "name" 'a","injected":"b'
    # The crafted value is stored verbatim as a string...
    [ "$(jq -r '.name' <"${BATS_TEST_TMPDIR}/opts")" = 'a","injected":"b' ]
    # ...and must not have injected a separate key.
    run jq -e 'has("injected")' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -ne 0 ]
}

@test "addon.option sets a raw JSON value with the ^ prefix" {
    bashio::app.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::app.option "enabled" "^true"
    run jq -e '.enabled == true' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -eq 0 ]
}

@test "addon.option updates an already existing key in place" {
    bashio::app.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{"name":"old"}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::app.option "name" "new"
    [ "$(jq -r '.name' <"${BATS_TEST_TMPDIR}/opts")" = "new" ]
}

@test "addon.option removes a key when no value is given" {
    bashio::app.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{"keep":"yes","drop":"no"}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::app.option "drop"
    # The dropped key is gone...
    run jq -e 'has("drop")' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -ne 0 ]
    # ...while the other key is untouched.
    [ "$(jq -r '.keep' <"${BATS_TEST_TMPDIR}/opts")" = "yes" ]
}

@test "addon.option sets a raw JSON object with the ^ prefix" {
    bashio::app.options() {
        if [[ $# -le 1 ]]; then
            printf '%s' '{}'
        else
            printf '%s' "$2" >"${BATS_TEST_TMPDIR}/opts"
        fi
    }
    bashio::app.option "nested" '^{"a":1}'
    run jq -e '.nested.a == 1' <"${BATS_TEST_TMPDIR}/opts"
    [ "${status}" -eq 0 ]
}

# ------------------------------------------------------------------------------
# addon.config: self-only config with caching and the empty -> {} fallback.
# ------------------------------------------------------------------------------

@test "addon.config requests the self options config" {
    bashio::api.supervisor() {
        echo "$*" >"${BATS_TEST_TMPDIR}/call"
        printf '%s' '{"foo":"bar"}'
    }
    run bashio::app.config
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = "GET /addons/self/options/config false" ]
    run jq -r '.foo' <<<"${output}"
    [ "${output}" = "bar" ]
}

@test "addon.config turns an empty response into an empty JSON object" {
    bashio::api.supervisor() { printf '%s' ''; }
    run bashio::app.config
    [ "${status}" -eq 0 ]
    [ "${output}" = "{}" ]
}

@test "addon.config serves from cache without calling the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' '{"cached":true}' >"${__BASHIO_CACHE_DIR}/addons.self.options.config.cache"
    bashio::api.supervisor() {
        echo "API SHOULD NOT BE CALLED"
        return 1
    }
    run bashio::app.config
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"cached":true}' ]
}

@test "addon.config fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.config >/dev/null || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Network and port helpers.
# ------------------------------------------------------------------------------

@test "addon.network returns the network map when present" {
    run get_field '{"slug":"alpha","network":{"80/tcp":8080}}' bashio::app.network
    [ "${status}" -eq 0 ]
    run jq -r '."80/tcp"' <<<"${output}"
    [ "${output}" = "8080" ]
}

@test "addon.network is empty when the network map is an empty object" {
    run get_field '{"slug":"alpha","network":{}}' bashio::app.network
    [ "${output}" = "" ]
}

@test "addon.network posts the given network map as a raw JSON body" {
    bashio::api.supervisor() { echo "$*" >"${BATS_TEST_TMPDIR}/call"; }
    run bashio::app.network "alpha" '{"80/tcp":8080}'
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/call")" = 'POST /addons/alpha/options {"network":{"80/tcp":8080}}' ]
}

@test "addon.network propagates an API failure on set" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.network "alpha" '{}' || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.network_description returns the descriptions when present" {
    run get_field '{"slug":"alpha","network_description":{"80/tcp":"Web"}}' bashio::app.network_description
    run jq -r '."80/tcp"' <<<"${output}"
    [ "${output}" = "Web" ]
}

@test "addon.port reads the mapped port, defaulting the protocol to tcp" {
    run get_field '{"slug":"alpha","network":{"80/tcp":8080}}' bashio::app.port "80"
    [ "${status}" -eq 0 ]
    [ "${output}" = "8080" ]
}

@test "addon.port reads a port with an explicit protocol" {
    run get_field '{"slug":"alpha","network":{"53/udp":5353}}' bashio::app.port "53/udp"
    [ "${output}" = "5353" ]
}

@test "addon.port is empty when the port is not mapped" {
    run get_field '{"slug":"alpha","network":{}}' bashio::app.port "80"
    [ "${output}" = "" ]
}

@test "addon.port sets a user port by merging into the network map" {
    # Read returns the current network, write records the merged result. The
    # third argument switches the function into set mode.
    bashio::app.network() {
        if [[ $# -ge 2 ]]; then
            echo "$2" >"${BATS_TEST_TMPDIR}/net"
        else
            printf '%s' '{"80/tcp":8080}'
        fi
    }
    run bashio::app.port "443" "alpha" "8443"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '."443/tcp"' <"${BATS_TEST_TMPDIR}/net")" = "8443" ]
    # The pre-existing mapping is preserved.
    [ "$(jq -r '."80/tcp"' <"${BATS_TEST_TMPDIR}/net")" = "8080" ]
}

@test "addon.port_description reads the description, defaulting to tcp" {
    run get_field '{"slug":"alpha","network_description":{"80/tcp":"Web UI"}}' bashio::app.port_description "80"
    [ "${output}" = "Web UI" ]
}

# ------------------------------------------------------------------------------
# Stats fetcher and its derived getters.
# ------------------------------------------------------------------------------

# Stubs the API so the stats endpoint returns the given body.
stats_field() {
    local body="$1"
    shift
    BODY="${body}"
    bashio::api.supervisor() {
        echo "$*" >>"${BATS_TEST_TMPDIR}/calls"
        printf '%s' "${BODY}"
    }
    "$@" "alpha"
}

@test "addon.stats fetches the stats endpoint and returns the raw object" {
    run stats_field '{"cpu_percent":1.5,"memory_usage":100}' bashio::app.stats
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/calls"
    [ "${lines[0]}" = "GET /addons/alpha/stats false" ]
}

@test "addon.stats fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.stats "alpha" >/dev/null || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.stats serves from its cache key without calling the API" {
    mkdir -p "${__BASHIO_CACHE_DIR}"
    printf '%s' '{"cpu_percent":9}' >"${__BASHIO_CACHE_DIR}/addons.alpha.stats.cache"
    bashio::api.supervisor() {
        echo "API SHOULD NOT BE CALLED"
        return 1
    }
    run bashio::app.stats "alpha"
    [ "${status}" -eq 0 ]
    run jq -r '.cpu_percent' <<<"${output}"
    [ "${output}" = "9" ]
}

# The derived stat getters (cpu_percent, memory_usage, memory_limit,
# memory_percent, network_tx, network_rx, blk_read, blk_write) all dispatch to
# bashio::app.stats with a per-field jq filter and return the extracted value.

@test "addon.cpu_percent returns the cpu_percent value from the stats" {
    run stats_field '{"cpu_percent":1.5}' bashio::app.cpu_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.5" ]
}

@test "addon.cpu_percent fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.cpu_percent "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.memory_usage returns the memory_usage value from the stats" {
    run stats_field '{"memory_usage":2048}' bashio::app.memory_usage
    [ "${status}" -eq 0 ]
    [ "${output}" = "2048" ]
}

@test "addon.memory_usage fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.memory_usage "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.memory_limit returns the memory_limit value from the stats" {
    run stats_field '{"memory_limit":4096}' bashio::app.memory_limit
    [ "${status}" -eq 0 ]
    [ "${output}" = "4096" ]
}

@test "addon.memory_limit fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.memory_limit "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.memory_percent returns the memory_percent value from the stats" {
    run stats_field '{"memory_percent":50.0}' bashio::app.memory_percent
    [ "${status}" -eq 0 ]
    [ "${output}" = "50.0" ]
}

@test "addon.memory_percent fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.memory_percent "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.network_tx returns the network_tx value from the stats" {
    run stats_field '{"network_tx":1000}' bashio::app.network_tx
    [ "${status}" -eq 0 ]
    [ "${output}" = "1000" ]
}

@test "addon.network_tx fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.network_tx "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.network_rx returns the network_rx value from the stats" {
    run stats_field '{"network_rx":2000}' bashio::app.network_rx
    [ "${status}" -eq 0 ]
    [ "${output}" = "2000" ]
}

@test "addon.network_rx fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.network_rx "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.blk_read returns the blk_read value from the stats" {
    run stats_field '{"blk_read":300}' bashio::app.blk_read
    [ "${status}" -eq 0 ]
    [ "${output}" = "300" ]
}

@test "addon.blk_read fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.blk_read "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

@test "addon.blk_write returns the blk_write value from the stats" {
    run stats_field '{"blk_write":400}' bashio::app.blk_write
    [ "${status}" -eq 0 ]
    [ "${output}" = "400" ]
}

@test "addon.blk_write fails when the API call fails" {
    bashio::api.supervisor() { return 1; }
    rc=0
    bashio::app.blk_write "alpha" >/dev/null 2>&1 || rc=$?
    [ "${rc}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Protection-mode guards.
# ------------------------------------------------------------------------------

@test "require.protected succeeds when protection mode is enabled" {
    bashio::app.protected() { printf '%s' "true"; }
    run bashio::require.protected
    [ "${status}" -eq 0 ]
}

@test "require.protected exits non-zero when protection mode is disabled" {
    bashio::app.protected() { printf '%s' "false"; }
    run bashio::require.protected
    [ "${status}" -ne 0 ]
}

@test "require.unprotected succeeds when protection mode is disabled" {
    bashio::app.protected() { printf '%s' "false"; }
    run bashio::require.unprotected
    [ "${status}" -eq 0 ]
}

@test "require.unprotected exits non-zero when protection mode is enabled" {
    bashio::app.protected() { printf '%s' "true"; }
    run bashio::require.unprotected
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# Deprecated addon.* / addons.* aliases (renamed to app.* / apps.*).
# ------------------------------------------------------------------------------

@test "the deprecated addon.name alias delegates to app.name" {
    bashio::app.name() { printf 'app:%s' "$1"; }
    run bashio::addon.name "myslug"
    [ "${status}" -eq 0 ]
    [ "${output}" = "app:myslug" ]
}

@test "the deprecated addon.name alias warns once" {
    bashio::app.name() { :; }
    warns=0
    bashio::log.warning() { warns=$((warns + 1)); }
    # Direct calls (no run/command-substitution) so the warn-once state and the
    # counter both live in this shell.
    bashio::addon.name "self" >/dev/null
    bashio::addon.name "self" >/dev/null
    [ "${warns}" -eq 1 ]
}

@test "the deprecated addons alias delegates to apps" {
    bashio::apps() { printf 'apps-list'; }
    run bashio::addons
    [ "${status}" -eq 0 ]
    [ "${output}" = "apps-list" ]
}

@test "the deprecated addons.reload alias delegates to apps.reload" {
    bashio::apps.reload() { printf 'reloaded'; }
    run bashio::addons.reload
    [ "${status}" -eq 0 ]
    [ "${output}" = "reloaded" ]
}

@test "the deprecated addon.option alias delegates to app.option" {
    bashio::app.option() { printf 'set:%s=%s' "$1" "$2"; }
    run bashio::addon.option "key" "value"
    [ "${status}" -eq 0 ]
    [ "${output}" = "set:key=value" ]
}
