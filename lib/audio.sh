#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Updates the audio server to the latest version.
#
# Arguments:
#   $1 Version to update to (optional)
# ------------------------------------------------------------------------------
function bashio::audio.update() {
    local version=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${version}"; then
        version=$(bashio::var.json version "${version}")
        bashio::api.supervisor POST /audio/update "${version}" || return "${__BASHIO_EXIT_NOK}"
    else
        bashio::api.supervisor POST /audio/update || return "${__BASHIO_EXIT_NOK}"
    fi
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Reloads the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.reload() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /audio/reload || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Restarts the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.restart() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /audio/restart || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns the logs created by the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.logs() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor GET /audio/logs true
}

# ------------------------------------------------------------------------------
# Sets the volume on an audio stream.
#
# Arguments:
#   $1 Stream type ('input' or 'output')
#   $2 Stream index
#   $3 Volume level (a number between 0 and 1, e.g. 0.5)
#   $4 Apply to the application stream instead of the device (optional)
# ------------------------------------------------------------------------------
function bashio::audio.volume() {
    local source=${1}
    local index=${2}
    local volume=${3}
    local application=${4:-false}
    local resource
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if [[ ! "${source}" =~ ^(input|output)$ ]]; then
        bashio::log.error "Invalid stream type, expected 'input' or 'output'"
        return "${__BASHIO_EXIT_NOK}"
    fi
    if [[ ! "${index}" =~ ^(0|[1-9][0-9]*)$ ]]; then
        bashio::log.error "Invalid index, expected a non-negative integer"
        return "${__BASHIO_EXIT_NOK}"
    fi
    if [[ ! "${volume}" =~ ^(0|[1-9][0-9]*)(\.[0-9]+)?$ ]]; then
        bashio::log.error "Invalid volume, expected a non-negative number"
        return "${__BASHIO_EXIT_NOK}"
    fi

    resource="/audio/volume/${source}"
    if bashio::var.true "${application}"; then
        resource="${resource}/application"
    fi

    payload=$(bashio::var.json index "^${index}" volume "^${volume}")
    bashio::api.supervisor POST "${resource}" "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Mutes or unmutes an audio stream.
#
# Arguments:
#   $1 Stream type ('input' or 'output')
#   $2 Stream index
#   $3 Mute state (true to mute, false to unmute)
#   $4 Apply to the application stream instead of the device (optional)
# ------------------------------------------------------------------------------
function bashio::audio.mute() {
    local source=${1}
    local index=${2}
    local active=${3}
    local application=${4:-false}
    local resource
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if [[ ! "${source}" =~ ^(input|output)$ ]]; then
        bashio::log.error "Invalid stream type, expected 'input' or 'output'"
        return "${__BASHIO_EXIT_NOK}"
    fi
    if [[ ! "${index}" =~ ^(0|[1-9][0-9]*)$ ]]; then
        bashio::log.error "Invalid index, expected a non-negative integer"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if bashio::var.true "${active}"; then
        active='^true'
    else
        active='^false'
    fi

    resource="/audio/mute/${source}"
    if bashio::var.true "${application}"; then
        resource="${resource}/application"
    fi

    payload=$(bashio::var.json index "^${index}" active "${active}")
    bashio::api.supervisor POST "${resource}" "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Sets the default audio stream.
#
# Arguments:
#   $1 Stream type ('input' or 'output')
#   $2 Name of the stream to set as default
# ------------------------------------------------------------------------------
function bashio::audio.default() {
    local source=${1}
    local name=${2}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if [[ ! "${source}" =~ ^(input|output)$ ]]; then
        bashio::log.error "Invalid stream type, expected 'input' or 'output'"
        return "${__BASHIO_EXIT_NOK}"
    fi

    payload=$(bashio::var.json name "${name}")
    bashio::api.supervisor POST "/audio/default/${source}" "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Activates an audio profile on a card.
#
# Arguments:
#   $1 Card identifier
#   $2 Profile name to activate
# ------------------------------------------------------------------------------
function bashio::audio.profile() {
    local card=${1}
    local name=${2}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    payload=$(bashio::var.json card "${card}" name "${name}")
    bashio::api.supervisor POST /audio/profile "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with generic version information about the audio server.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::audio() {
    local cache_key=${1:-'audio.info'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'audio.info' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'audio.info'; then
        info=$(bashio::cache.get 'audio.info')
    else
        info=$(bashio::api.supervisor GET /audio/info false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get audio info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'audio.info' "${info}"
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
    if [[ "${cache_key}" != 'audio.info' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns the audio server version used.
# ------------------------------------------------------------------------------
function bashio::audio.version() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.version' '.version'
}

# ------------------------------------------------------------------------------
# Returns the latest version of the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.version_latest() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.version_latest' '.version_latest'
}

# ------------------------------------------------------------------------------
# Checks if there is an update available for the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.update_available() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::audio 'audio.info.update_available' '.update_available // false'
}

# ------------------------------------------------------------------------------
# Returns the host of the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.host() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio 'audio.info.host' '.host'
}

# ------------------------------------------------------------------------------
# List all available stats about the audio server.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::audio.stats() {
    local cache_key=${1:-'audio.stats'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'audio.stats' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'audio.stats'; then
        info=$(bashio::cache.get 'audio.stats')
    else
        info=$(bashio::api.supervisor GET /audio/stats false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get audio stats from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'audio.stats' "${info}"
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
    if [[ "${cache_key}" != 'audio.stats' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Returns CPU usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.cpu_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.cpu_percent' '.cpu_percent'
}

# ------------------------------------------------------------------------------
# Returns memory usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_usage() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_usage' '.memory_usage'
}

# ------------------------------------------------------------------------------
# Returns memory limit from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_limit() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_limit' '.memory_limit'
}

# ------------------------------------------------------------------------------
# Returns memory usage in percent from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.memory_percent() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.memory_percent' '.memory_percent'
}

# ------------------------------------------------------------------------------
# Returns outgoing network usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.network_tx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.network_tx' '.network_tx'
}

# ------------------------------------------------------------------------------
# Returns incoming network usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.network_rx() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.network_rx' '.network_rx'
}

# ------------------------------------------------------------------------------
# Returns disk read usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.blk_read() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.blk_read' '.blk_read'
}

# ------------------------------------------------------------------------------
# Returns disk write usage from the audio server.
# ------------------------------------------------------------------------------
function bashio::audio.blk_write() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::audio.stats 'audio.stats.blk_write' '.blk_write'
}
