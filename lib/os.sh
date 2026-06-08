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
# Returns a JSON object with generic Home Assistant Operating System
# (HassOS) information.
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
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'os.info' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
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

    # Never overwrite the base blob with a filtered result: the
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

# ------------------------------------------------------------------------------
# Returns a JSON object with the swap settings (HassOS 15.0 or newer).
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os.swap() {
    local cache_key=${1:-'os.swap'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'os.swap' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'os.swap'; then
        info=$(bashio::cache.get 'os.swap')
    else
        info=$(bashio::api.supervisor GET /os/config/swap false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get swap settings from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'os.swap' "${info}"
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
    if [[ "${cache_key}" != 'os.swap' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Sets the swap settings (HassOS 15.0 or newer).
#
# Arguments:
#   $1 Options object (JSON), with swap_size and/or swappiness
# ------------------------------------------------------------------------------
function bashio::os.swap.options() {
    local options=${1}

    # The options object is an opaque caller-provided payload, so trace only
    # the function name, never the payload itself.
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /os/config/swap "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with the data disk targets available for migration.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os.datadisk.list() {
    local cache_key=${1:-'os.datadisk.list'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'os.datadisk.list' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'os.datadisk.list'; then
        info=$(bashio::cache.get 'os.datadisk.list')
    else
        info=$(bashio::api.supervisor GET /os/datadisk/list false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get data disk list from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'os.datadisk.list' "${info}"
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
    if [[ "${cache_key}" != 'os.datadisk.list' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Moves the data partition to another disk and reboots.
#
# Arguments:
#   $1 Target device id
# ------------------------------------------------------------------------------
function bashio::os.datadisk.move() {
    local device=${1}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    payload=$(bashio::var.json device "${device}")
    bashio::api.supervisor POST /os/datadisk/move "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Wipes the data disk and reboots into a factory-reset state.
# ------------------------------------------------------------------------------
function bashio::os.datadisk.wipe() {
    bashio::log.trace "${FUNCNAME[0]}"
    bashio::api.supervisor POST /os/datadisk/wipe || return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Changes the active boot slot and reboots into it.
#
# Arguments:
#   $1 Boot slot ('A' or 'B')
# ------------------------------------------------------------------------------
function bashio::os.boot_slot() {
    local slot=${1}
    local payload

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    payload=$(bashio::var.json boot_slot "${slot}")
    bashio::api.supervisor POST /os/boot-slot "${payload}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with the LED settings of a Home Assistant Green board.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os.boards.green() {
    local cache_key=${1:-'os.boards.green'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'os.boards.green' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'os.boards.green'; then
        info=$(bashio::cache.get 'os.boards.green')
    else
        info=$(bashio::api.supervisor GET /os/boards/green false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get green board info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'os.boards.green' "${info}"
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
    if [[ "${cache_key}" != 'os.boards.green' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Sets the LED settings of a Home Assistant Green board.
#
# Arguments:
#   $1 Options object (JSON), with activity_led, power_led and/or
#      system_health_led
# ------------------------------------------------------------------------------
function bashio::os.boards.green.options() {
    local options=${1}

    # The options object is an opaque caller-provided payload, so trace only
    # the function name, never the payload itself.
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /os/boards/green "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Returns a JSON object with the LED settings of a Home Assistant Yellow board.
#
# Arguments:
#   $1 Cache key to store results in (optional)
#   $2 jq Filter to apply on the result (optional)
# ------------------------------------------------------------------------------
function bashio::os.boards.yellow() {
    local cache_key=${1:-'os.boards.yellow'}
    local filter=${2:-}
    local info
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        # The base key holds the unfiltered blob, so only serve it from the
        # cache when no filter is requested; a filtered call must recompute.
        if [[ "${cache_key}" != 'os.boards.yellow' ]] ||
            ! bashio::var.has_value "${filter}"; then
            bashio::cache.get "${cache_key}"
            return "${__BASHIO_EXIT_OK}"
        fi
    fi

    if bashio::cache.exists 'os.boards.yellow'; then
        info=$(bashio::cache.get 'os.boards.yellow')
    else
        info=$(bashio::api.supervisor GET /os/boards/yellow false)
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to get yellow board info from Supervisor API"
            return "${__BASHIO_EXIT_NOK}"
        fi
        bashio::cache.set 'os.boards.yellow' "${info}"
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
    if [[ "${cache_key}" != 'os.boards.yellow' ]]; then
        bashio::cache.set "${cache_key}" "${response}"
    fi
    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Sets the LED settings of a Home Assistant Yellow board.
#
# Arguments:
#   $1 Options object (JSON), with disk_led, heartbeat_led and/or power_led
# ------------------------------------------------------------------------------
function bashio::os.boards.yellow.options() {
    local options=${1}

    # The options object is an opaque caller-provided payload, so trace only
    # the function name, never the payload itself.
    bashio::log.trace "${FUNCNAME[0]}"

    bashio::api.supervisor POST /os/boards/yellow "${options}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
