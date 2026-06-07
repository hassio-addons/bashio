#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Returns a JSON object listing the components that have an update available.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::updates() {
    local cache_key=${1:-'updates.available'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'updates.available' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'updates.available'; then
        info=$(bashio::cache.get 'updates.available')
    else
        info=$(bashio::api.supervisor GET /available_updates false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get available updates from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'updates.available' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    # Never overwrite the base blob with a filtered result: the
    # base blob is already cached above, so only cache under a distinct
    # caller-provided key.
    if [[ "${cache_key}" != 'updates.available' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Refreshes the cache of the latest software versions from the version server.
# ------------------------------------------------------------------------------
function bashio::updates.refresh() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /refresh_updates || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reloads the add-on stores and reads the latest version information.
# ------------------------------------------------------------------------------
function bashio::updates.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /reload_updates || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
