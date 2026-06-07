#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object with information about the configured mounts.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::mounts() {
    local cache_key=${1:-'mounts.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'mounts.info'; then
        info=$(bashio::cache.get 'mounts.info')
    else
        info=$(bashio::api.supervisor GET /mounts false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get mounts info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'mounts.info' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    bashio::cache.set "${cache_key}" "${response}"
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns a list of the names of all configured mounts.
# ------------------------------------------------------------------------------
function bashio::mounts.list() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::mounts 'mounts.info.list' '.mounts[].name'
}

# ------------------------------------------------------------------------------
# Returns the name of the default backup mount.
# ------------------------------------------------------------------------------
function bashio::mounts.default_backup_mount() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::mounts 'mounts.info.default_backup_mount' '.default_backup_mount'
}

# ------------------------------------------------------------------------------
# Creates a new mount in the Supervisor.
#
# Arguments:
#   $1 Mount definition (JSON)
# ------------------------------------------------------------------------------
function bashio::mounts.create() {
    local mount=${1}

    # A mount definition can carry credentials (CIFS/NFS username and
    # password), so trace only the function name, never the payload.
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /mounts "${mount}" || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Sets the Mount Manager options.
#
# Arguments:
#   $1 Options object (JSON)
# ------------------------------------------------------------------------------
function bashio::mounts.options() {
    local options=${1}

    # The options object can carry mount credentials, so trace only the
    # function name, never the payload.
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /mounts/options "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reloads an existing mount in the Supervisor.
#
# Arguments:
#   $1 Mount name
# ------------------------------------------------------------------------------
function bashio::mount.reload() {
    local mount=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor POST "/mounts/${mount}/reload" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Deletes an existing mount from the Supervisor.
#
# Arguments:
#   $1 Mount name
# ------------------------------------------------------------------------------
function bashio::mount.delete() {
    local mount=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    bashio::api.supervisor DELETE "/mounts/${mount}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
