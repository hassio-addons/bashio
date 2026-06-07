#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates HassOS to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::os.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /os/update "${version}" || return "${__BASHIO_EXIT_NOK}"
    else
        bashio::api.supervisor POST /os/update || return "${__BASHIO_EXIT_NOK}"
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Load HassOS host configuration from USB stick.
# ------------------------------------------------------------------------------
function bashio::os.config_sync() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /os/config/sync
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic Home Assistant information.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os() {
    local cache_key=${1:-'os.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        bashio::cache.get "${cache_key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::cache.exists 'os.info'; then
        info=$(bashio::cache.get 'os.info')
    else
        info=$(bashio::api.supervisor GET /os/info false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get os info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'os.info' "${info}"
    fi

    response="${info}"
    if bashio::var.has_value "${filter}"; then
        response=$(bashio::jq "${info}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    # Never overwrite the base info blob with a filtered result: the
    # base blob is already cached above, so only cache under a distinct
    # caller-provided key.
    if [[ "${cache_key}" != 'os.info' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the version of HassOS.
# ------------------------------------------------------------------------------
function bashio::os.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of HassOS.
# ------------------------------------------------------------------------------
function bashio::os.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the OS.
# ------------------------------------------------------------------------------
function bashio::os.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::os 'os.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the board running HassOS.
# ------------------------------------------------------------------------------
function bashio::os.board() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.board' '.board'
}

# ------------------------------------------------------------------------------
# Returns the active boot.
# ------------------------------------------------------------------------------
function bashio::os.boot() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::os 'os.info.boot' '.boot'
}
