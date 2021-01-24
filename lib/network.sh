#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reload the network controller.
# ------------------------------------------------------------------------------
function bashio::network.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /network/reload
}

# ------------------------------------------------------------------------------
# Returns a JSON object with host network information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::network() {
    local cache_key=${1:-'network.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'network.info'; then
        info=$(bashio::cache.get 'network.info')
    else
        info=$(bashio::api.supervisor GET /network/info false)
        bashio::cache.set 'network.info' "${info}"
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
# Returns a JSON object with host network interface information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 Network interface name (optional)
#   $3 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::network.interface() {
    local cache_key=${1:-'network.interface.info'}
    local interface=${2:-'default'}
    local filter=${3:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists "network.interface.${interface}.info"; then
        info=$(bashio::cache.get "network.${interface}.info")
    else
        info=$(bashio::api.supervisor GET /network/interface/${interface}/info false)
        bashio::cache.set "network.interface.${interface}.info" "${info}"
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
# Returns if the Host have internet connectivity.
# ------------------------------------------------------------------------------
function bashio::network.host_internet() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'network.info.host_internet' '.host_internet'
}

# ------------------------------------------------------------------------------
# Returns if the Supervisor have internet connectivity.
# ------------------------------------------------------------------------------
function bashio::network.supervisor_internet() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'network.info.supervisor_internet' '.supervisor_internet'
}

# ------------------------------------------------------------------------------
# Returns a list of all network interfaces.
# ------------------------------------------------------------------------------
function bashio::network.interfaces() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'network.info.interfaces.interface' '.interfaces[] | .interface'
}

# ------------------------------------------------------------------------------
# Returns a name of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.name() {
    local interface=${2:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host.interface "network.interface.$interface.info.interface" '.interface'
}

