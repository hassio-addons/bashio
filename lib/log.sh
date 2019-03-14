#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Log a message
#
# Arguments:
#   $1 Log level
#   $2 Message to display
# ------------------------------------------------------------------------------
function bashio::log.log() {
    local level=${1}
    local message=${2}
    local timestamp
    local output

    if [[ "${level}" -gt "${__BASHIO_LOG_LEVEL}" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    timestamp=$(date +"${__BASHIO_LOG_TIMESTAMP}")

    output="${__BASHIO_LOG_FORMAT}"
    output="${output//\{TIMESTAMP\}/${timestamp}}"
    output="${output//\{MESSAGE\}/${message}}"
    output="${output//\{LEVEL\}/${__BASHIO_LOG_LEVELS[$level]}}"

    echo "${output}" >&2

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message @ trace level
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.trace() {
    local message=$*
    bashio::color.dark_grey >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_TRACE}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ debug level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.debug() {
    local message=$*
    bashio::color.dark_grey >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_DEBUG}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ info level
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.info() {
    local message=$*
    bashio::color.light_blue >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_INFO}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ notice level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.notice() {
    local message=$*
    bashio::color.cyan >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_NOTICE}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ warning level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.warning() {
    local message=$*
    bashio::color.yellow >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_WARNING}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ error level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.error() {
    local message=$*
    bashio::color.magenta >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_ERROR}" "${message}"
    bashio::color.reset >&2
}

# ------------------------------------------------------------------------------
# Log a message @ fatal level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.fatal() {
    local message=$*
    bashio::color.red >&2
    bashio::log.log "${__BASHIO_LOG_LEVEL_FATAL}" "${message}"
    bashio::color.reset >&2
}
