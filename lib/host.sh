#!/usr/bin/env bash
# ==============================================================================
# Community Home Assistant Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reload the host controller.
# ------------------------------------------------------------------------------
function bashio::host.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /host/reload
}

# ------------------------------------------------------------------------------
# Shuts down the host system.
# ------------------------------------------------------------------------------
function bashio::host.shutdown() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /host/shutdown
}

# ------------------------------------------------------------------------------
# Reboots the host system.
# ------------------------------------------------------------------------------
function bashio::host.reboot() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.hassio POST /host/reboot
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Host information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::host() {
    local cache_key=${1:-'host.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'host.info'; then
        info=$(bashio::cache.get 'host.info')
    else
        info=$(bashio::api.hassio GET /host/info false)
        bashio::cache.set 'host.info' "${info}"
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
# Returns the hostname of the host system.
# ------------------------------------------------------------------------------
function bashio::host.hostname() {
    local hostname=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.has_value "${hostname}"; then
        hostname=$(bashio::var.json hostname "${hostname}")
        bashio::api.hassio POST /host/options "${hostname}"
        bashio::cache.flush_all
    else
        bashio::host 'host.info.hostname' '.hostname'
    fi
}

# ------------------------------------------------------------------------------
# Returns a list of exposed features by the host.
# ------------------------------------------------------------------------------
function bashio::host.features() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.features' '.features[]'
}

# ------------------------------------------------------------------------------
# Returns the OS of the host system.
# ------------------------------------------------------------------------------
function bashio::host.operating_system() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.operating_system' '.operating_system'
}

# ------------------------------------------------------------------------------
# Returns the kernel of the host system.
# ------------------------------------------------------------------------------
function bashio::host.kernel() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.kernel' '.kernel'
}

# ------------------------------------------------------------------------------
# Returns the chassis of the host system.
# ------------------------------------------------------------------------------
function bashio::host.chassis() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.chassis' '.chassis'
}

# ------------------------------------------------------------------------------
# Returns the stability channel / deployment of the system.
# ------------------------------------------------------------------------------
function bashio::host.deployment() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.deployment' '.deployment'
}

# ------------------------------------------------------------------------------
# Returns the cpe from the host.
# ------------------------------------------------------------------------------
function bashio::host.cpe() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::host 'host.info.cpe' '.cpe'
}
