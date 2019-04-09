#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reloads the add-ons.
# ------------------------------------------------------------------------------
function bashio::addons.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /addons/reload
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Start the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.start() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/start"
}

# ------------------------------------------------------------------------------
# Restart the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.restart() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/restart"
}

# ------------------------------------------------------------------------------
# Stop the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.stop() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/stop"
}

# ------------------------------------------------------------------------------
# Install the specified add-on.
#
# Arguments:
#   $1 Add-on slug
# ------------------------------------------------------------------------------
function bashio::addon.install() {
    local slug=${1}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/install"
}

# ------------------------------------------------------------------------------
# Rebuild the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.rebuild() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/rebuild"
}

# ------------------------------------------------------------------------------
# Uninstall the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.uninstall() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/uninstall"
}

# ------------------------------------------------------------------------------
# Update the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.update() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST "/addons/${slug}/update"
}

# ------------------------------------------------------------------------------
# RAW Docker log of the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.log() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio GET "/addons/${slug}/log" true
}

# ------------------------------------------------------------------------------
# Returns the changelog of the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.changelog() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio GET "/addons/${slug}/changelog" true
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about addons.
#
# Arguments:
#   $1 Add-on slug (optional)
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::addons() {
    local slug=${1:-false}
    local cache_key=${2:-'addons.list'}
    local filter=${3:-'.addons[].slug'}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::var.false "${slug}"; then
        if bashio::cache.exists "addons.list"; then
            info=$(bashio::cache.get 'addons.list')
        else
            info=$(bashio::api.hassio GET "/addons" false)
            bashio::cache.set "addons.list" "${info}"
        fi
    else
        if bashio::cache.exists "addons.${slug}.info"; then
            info=$(bashio::cache.get "addons.${slug}.info")
        else
            info=$(bashio::api.hassio GET "/addons/${slug}/info" false)
            bashio::cache.set "addons.${slug}.info" "${info}"
        fi
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns a list of installed add-ons or for a specific add-ons.

# Arguments:
#   $1 Add-on slug (optional)
# ------------------------------------------------------------------------------
function bashio::addons.installed() {
    local slug=${1:-false}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.false "${slug}"; then
        bashio::addons \
            false \
            'addons.info.installed' \
            '.addons[] | select(.installed != null) | .slug'
    else
        bashio::addons \
            "${slug}" \
            "addons.${slug}.installed" \
            'if (.version != null) then true else false end'
    fi
}

# ------------------------------------------------------------------------------
# Returns the name of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.name() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.name" '.name'
}

# ------------------------------------------------------------------------------
# Returns the description of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.description() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.description" '.description'
}

# ------------------------------------------------------------------------------
# Returns the long description of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.long_description() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.long_description" \
        '.long_description'
}

# ------------------------------------------------------------------------------
# Returns or sets whether or not auto update is enabled for this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
#   $2 Set current auto update state (Optional)
# ------------------------------------------------------------------------------
function bashio::addon.auto_update() {
    local slug=${1:-'self'}
    local auto_update=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${auto_update}"; then
        auto_update=$(bashio::var.json auto_update "^${auto_update}")
        bashio::api.hassio POST "/addons/${slug}/options" "${auto_update}"
        bashio::cache.flush_all
    else
        bashio::addons \
            "${slug}" \
            "addons.${slug}.auto_update" \
            '.auto_update // false'
    fi
}

# ------------------------------------------------------------------------------
# Returns the URL of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.url() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.url" '.url'
}

# ------------------------------------------------------------------------------
# Returns the deatched state of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.detached() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.detached" '.detached // false'
}

# ------------------------------------------------------------------------------
# Returns the availability state of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.available() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.available" '.available // false'
}

# ------------------------------------------------------------------------------
# Returns list of supported architectures by the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.arch() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.arch" '.arch[]'
}

# ------------------------------------------------------------------------------
# Returns list of supported machine types by the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.machine() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.machine" '.machine[]'
}

# ------------------------------------------------------------------------------
# Returns the slug of the repository this add-on is in.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.repository() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.repository" '.repository'
}


# ------------------------------------------------------------------------------
# Returns the version of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.version() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.version" '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.last_version() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.last_version" '.last_version'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.update_available() {
    local addon=${1:-'self'}
    local version
    local last_version

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    version=$(bashio::addon.version "${addon}")
    last_version=$(bashio::addon.last_version "${addon}")

    if [[ "${version}" = "${last_version}" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the current state of an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.state() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.state" '.state'
}

# ------------------------------------------------------------------------------
# Returns the current boot setting of this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
#   $2 Sets boot setting (optional).
# ------------------------------------------------------------------------------
function bashio::addon.boot() {
    local slug=${1:-'self'}
    local boot=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${boot}"; then
        boot=$(bashio::var.json boot "${boot}")
        bashio::api.hassio POST "/addons/${slug}/options" "${boot}"
        bashio::cache.flush_all
    else
        bashio::addons "${slug}" "addons.${slug}.boot" '.boot'
    fi
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on is being build locally.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.build() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.build" '.build // false'
}

# ------------------------------------------------------------------------------
# Returns options for this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.options() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.options" '.options'
}

# ------------------------------------------------------------------------------
# Returns a list of ports which are exposed on the host network for this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.network() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.network" '.network'
}

# ------------------------------------------------------------------------------
# Returns a list of ports and their descriptions for this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.network_description() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" \
        "addons.${slug}.network_description" \
        '.network_description'
}

# ------------------------------------------------------------------------------
# Returns a user configured port number for a original port number.
#
# Arguments:
#   $1 Original port number
#   $2 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.port() {
    local port=${1:-}
    local slug=${2:-'self'}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    # Default to TCP if not specified.
    if [[ "${port}" != *"/"* ]]; then
        port="${port}/tcp"
    fi

    bashio::addons \
        "${slug}" \
        "addons.${slug}.network.${port//\//-}" \
        ".network[\"${port}\"]"
}

# ------------------------------------------------------------------------------
# Returns a description for port number for this add-on.
#
# Arguments:
#   $1 Original port number
#   $2 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.port_description() {
    local port=${1:-}
    local slug=${2:-'self'}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    # Default to TCP if not specified.
    if [[ "${port}" != *"/"* ]]; then
        port="${port}/tcp"
    fi

    bashio::addons \
        "${slug}" \
        "addons.${slug}.network_description.${port//\//-}" \
        ".network_description[\"${port}\"]"
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on runs on the host network.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.host_network() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.host_network" \
        '.host_network // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on runs on the host pid namespace.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.host_pid() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.host_pid" \
        '.host_pid // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on has IPC access.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.host_ipc() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.host_ipc" \
        '.host_ipc // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on has DBus access to the host.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.host_dbus() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.host_dbus" \
        '.host_dbus // false'
}

# ------------------------------------------------------------------------------
# Returns the privileges the add-on has on to the hardware / system.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.privileged() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.privileged" '.privileged[]'
}

# ------------------------------------------------------------------------------
# Returns the current apparmor state of this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.apparmor() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.apparmor" '.apparmor'
}

# ------------------------------------------------------------------------------
# Returns a list devices made available to the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.devices() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.devices" '.devices // empty | .[]'
}

# ------------------------------------------------------------------------------
# Returns if UART was made available to the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.auto_uart() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.auto_uart" '.auto_uart // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on has a icon available.
#
# Arguments:
#   $1 Add-on slug
# ------------------------------------------------------------------------------
function bashio::addon.icon() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.icon" '.icon // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on has a logo available.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.logo() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.logo" '.logo // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on has a changelog available.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.changelog() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.changelog" '.changelog // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access the Hass.io API.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.hassio_api() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.hassio_api" '.hassio_api // false'
}

# ------------------------------------------------------------------------------
# Returns the Hass.io API role of this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.hassio_role() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.hassio_role" '.hassio_role'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access the Home Assistant API.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.homeassistant_api() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.homeassistant_api" \
        '.homeassistant_api // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access the Hass.io Authentication API.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.auth_api() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.auth_api" '.auth_api // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on run in protected mode.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.protected() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.protected" '.protected // false'
}

# ------------------------------------------------------------------------------
# Returns the add-on its rating
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.rating() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.rating" '.rating'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can use the STDIN on the Hass.io API.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.stdin() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.stdin" '.stdin // false'
}

# ------------------------------------------------------------------------------
# A URL for web interface of this add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.webui() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.webui" '.webui // empty'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access GPIO.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.gpio() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.gpio" '.gpio // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access kernel modules.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.kernel_modules() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.kernel_modules" \
        '.kernel_modules // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access the devicetree.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.devicetree() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.devicetree" '.devicetree // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access the Docker socket.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.docker_api() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.docker_api" '.docker_api // false'
}

# ------------------------------------------------------------------------------
# Returns whether or not this add-on can access an audio device.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.audio() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.audio" '.audio // false'
}

# ------------------------------------------------------------------------------
# Returns the available audio input device for an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.audio_input() {
    local slug=${1:-'self'}
    local audio_input=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${audio_input}"; then
        audio_input=$(bashio::var.json audio_input "${audio_input}")
        bashio::api.hassio POST "/addons/${slug}/options" "${audio_input}"
        bashio::cache.flush_all
    else
        bashio::addons \
            "${slug}" \
            "addons.${slug}.audio_input" \
            '.audio_input // empty'
    fi
}

# ------------------------------------------------------------------------------
# Returns the available audio output device for an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
#   $2 Audio output device to set (Optional)
# ------------------------------------------------------------------------------
function bashio::addon.audio_output() {
    local slug=${1:-'self'}
    local audio_output=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${audio_output}"; then
        audio_output=$(bashio::var.json audio_output "${audio_output}")
        bashio::api.hassio POST "/addons/${slug}/options" "${audio_output}"
        bashio::cache.flush_all
    else
        bashio::addons \
            "${slug}" \
            "addons.${slug}.audio_output" \
            '.audio_output // empty'
    fi
}

# ------------------------------------------------------------------------------
# Returns IP address assigned on the hassio network for an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.ip_address() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.ip_address" '.ip_address // empty'
}

# ------------------------------------------------------------------------------
# Returns if the add-on support ingress mode.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.ingress() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons "${slug}" "addons.${slug}.ingress" '.ingress // false'
}

# ------------------------------------------------------------------------------
# Returns the ingress entry point of the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.ingress_entry() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.ingress_entry" \
        '.ingress_entry // empty'
}

# ------------------------------------------------------------------------------
# Returns the ingress url of the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.ingress_url() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.ingress_url" \
        '.ingress_url // empty'
}

# ------------------------------------------------------------------------------
# Returns the ingress port of the add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.ingress_port() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons \
        "${slug}" \
        "addons.${slug}.ingress_port" \
        '.ingress_port // empty'
}

# ------------------------------------------------------------------------------
# List all available stats about an add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::addon.stats() {
    local slug=${1:-'self'}
    local cache_key=${2:-"addons.${slug}.stats"}
    local filter=${3:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists "addons.${slug}.stats"; then
        info=$(bashio::cache.get "addons.${slug}.stats")
    else
        info=$(bashio::api.hassio GET "/addons/${slug}/stats" false)
        bashio::cache.set "addons.${slug}.stats" "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns CPU usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.cpu_percent() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.cpu_percent" \
        '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.memory_usage() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.memory_usage" \
        '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.memory_limit() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.memory_limit" \
        '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.network_tx() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.network_tx" \
        '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.network_rx() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.network_rx" \
        '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.blk_read() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.blk_read" \
        '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the specified add-on.
#
# Arguments:
#   $1 Add-on slug (optional, default: self)
# ------------------------------------------------------------------------------
function bashio::addon.blk_write() {
    local slug=${1:-'self'}
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::addons.stats \
        "${slug}" \
        "addons.${slug}.stats.blk_write" \
        '.blk_write'
}

# ------------------------------------------------------------------------------
# Checks if the add-on is running in protected mode and exits if not.
# ------------------------------------------------------------------------------
function bashio::require.protected() {
    local protected

    protected=$(bashio::addon.protected 'self')
    if bashio::var.true "${protected}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal "PROTECTION MODE IS DISABLED!"
    bashio::log.fatal
    bashio::log.fatal "We are trying to help you to protect your system the"
    bashio::log.fatal "best we can. Therefore, this add-on checks if"
    bashio::log.fatal "protection mode is enabled on this add-on."
    bashio::log.fatal
    bashio::log.fatal "Unfortunately, it has been disabled."
    bashio::log.fatal "Pleas enable it again!"
    bashio::log.fatal ""
    bashio::log.fatal "Steps:"
    bashio::log.fatal " - Go to the Hass.io Panel."
    bashio::log.fatal " - Click on this add-on."
    bashio::log.fatal " - Set the 'Protection mode' switch to on."
    bashio::log.fatal " - Restart the add-on."
    bashio::log.fatal

    bashio::exit.nok
}

# ------------------------------------------------------------------------------
# Checks if the add-on is running in unprotected mode and exits if not.
# ------------------------------------------------------------------------------
function bashio::require.unprotected() {
    local protected

    protected=$(bashio::addon.protected 'self')
    if bashio::var.false "${protected}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal "PROTECTION MODE IS ENABLED!"
    bashio::log.fatal
    bashio::log.fatal "To be able to use this add-on, you'll need to disable"
    bashio::log.fatal "protection mode on this add-on. Without it, the add-on"
    bashio::log.fatal "is unable to access Docker."
    bashio::log.fatal
    bashio::log.fatal "Steps:"
    bashio::log.fatal " - Go to the Hass.io Panel."
    bashio::log.fatal " - Click on this add-on."
    bashio::log.fatal " - Set the 'Protection mode' switch to off."
    bashio::log.fatal " - Restart the add-on."
    bashio::log.fatal
    bashio::log.fatal "Access to Docker allows you to do really powerful things"
    bashio::log.fatal "including complete destruction of your system."
    bashio::log.fatal "Please, be sure you know what you are doing before"
    bashio::log.fatal "enabling this feature (and this add-on)!"
    bashio::log.fatal

    bashio::exit.nok
}
