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
    bashio::cache.flush_all
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
# Returns if the Host have internet connectivity.
# ------------------------------------------------------------------------------
function bashio::network.host_internet() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network 'network.info.host_internet' '.host_internet'
}

# ------------------------------------------------------------------------------
# Returns if the Supervisor have internet connectivity.
# ------------------------------------------------------------------------------
function bashio::network.supervisor_internet() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network 'network.info.supervisor_internet' '.supervisor_internet'
}

# ------------------------------------------------------------------------------
# Returns a list of all network interfaces.
# ------------------------------------------------------------------------------
function bashio::network.interfaces() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network 'network.info.interfaces.interface' '.interfaces[] | .interface'
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
        info=$(bashio::cache.get "network.interface.${interface}.info")
    else
        info=$(bashio::api.supervisor GET "/network/interface/${interface}/info" false)
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
# Returns a name of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.name() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.interface" "${interface}" '.interface'
}

# ------------------------------------------------------------------------------
# Returns the type of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.type() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.type" "${interface}" '.type'
}

# ------------------------------------------------------------------------------
# Returns if the interface is enabled.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.enabled() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.enabled" "${interface}" '.enabled'
}

# ------------------------------------------------------------------------------
# Returns if the interface is connected.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.enabled() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.connected" "${interface}" '.connected'
}

# ------------------------------------------------------------------------------
# Returns the ipv4 method of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv4_method() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv4.method" "${interface}" '.ipv4.method'
}

# ------------------------------------------------------------------------------
# Returns the ipv6 method of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv6_method() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv6.method" "${interface}" '.ipv6.method'
}

# ------------------------------------------------------------------------------
# Returns a list of the ipv4 address of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv4_address() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv4.address" "${interface}" '.ipv4.address[]'
}

# ------------------------------------------------------------------------------
# Returns a list of the ipv6 address of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv6_address() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv6.address" "${interface}" '.ipv6.address[]'
}

# ------------------------------------------------------------------------------
# Returns a list of ipv4 nameservers of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv4_nameservers() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv4.nameservers" "${interface}" '.ipv4.nameservers[]'
}

# ------------------------------------------------------------------------------
# Returns a list ipv6 nameservers of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv6_nameservers() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv6.nameservers" "${interface}" '.ipv6.nameservers[]'
}

# ------------------------------------------------------------------------------
# Returns the ipv4 gateway of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv4_gateway() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv4.gateway" "${interface}" '.ipv4.gateway'
}

# ------------------------------------------------------------------------------
# Returns the ipv6 gateway of the network interfaces.
#
# Arguments:
#   $1 Interface name for this operation (optional)
# ------------------------------------------------------------------------------
function bashio::network.ipv6_gateway() {
    local interface=${1:-'default'}

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::network.interface "network.interface.${interface}.info.ipv6.gateway" "${interface}" '.ipv6.gateway'
}
