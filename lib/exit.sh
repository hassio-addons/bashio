#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Exit the script as failed with an optional error message.
#
# Arguments:
#   $1 Error message (optional)
# ------------------------------------------------------------------------------
function bashio::exit.nok() {
    local message=${1:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${message}"; then
        bashio::log.fatal "${message}"
    fi

    exit "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Exit the script when given value is false, with an optional error message.
#
# Arguments:
#   $1 Value to check if false
#   $2 Error message (optional)
# ------------------------------------------------------------------------------
function bashio::exit.die_if_false() {
    local value=${1:-}
    local message=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.false "${value}"; then
        bashio::exit.nok "${message}"
    fi
}

# ------------------------------------------------------------------------------
# Exit the script when given value is true, with an optional error message.
#
# Arguments:
#   $1 Value to check if true
#   $2 Error message (optional)
# ------------------------------------------------------------------------------
function bashio::exit.die_if_true() {
    local value=${1:-}
    local message=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.true "${value}"; then
        bashio::exit.nok "${message}"
    fi
}

# ------------------------------------------------------------------------------
# Deprecated alias for bashio::exit.die_if_false.
# ------------------------------------------------------------------------------
function hass.die_if_false() { # codespell:ignore
    bashio::log.warning \
        "${FUNCNAME[0]} is deprecated, use bashio::exit.die_if_false instead."
    bashio::exit.die_if_false "$@"
}

# ------------------------------------------------------------------------------
# Deprecated alias for bashio::exit.die_if_true.
# ------------------------------------------------------------------------------
function hass.die_if_true() { # codespell:ignore
    bashio::log.warning \
        "${FUNCNAME[0]} is deprecated, use bashio::exit.die_if_true instead."
    bashio::exit.die_if_true "$@"
}

# ------------------------------------------------------------------------------
# Exit the script when given value is empty, with an optional error message.
#
# Arguments:
#   $1 Value to check if empty
#   $2 Error message (optional)
# ------------------------------------------------------------------------------
function bashio::exit.die_if_empty() {
    local value=${1:-}
    local message=${2:-}

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.is_empty "${value}"; then
        bashio::exit.nok "${message}"
    fi
}

# ------------------------------------------------------------------------------
# Deprecated alias for bashio::exit.die_if_empty.
# ------------------------------------------------------------------------------
function hass.die_if_empty() { # codespell:ignore
    bashio::log.warning \
        "${FUNCNAME[0]} is deprecated, use bashio::exit.die_if_empty instead."
    bashio::exit.die_if_empty "$@"
}

# ------------------------------------------------------------------------------
# Exit the script nicely.
# ------------------------------------------------------------------------------
function bashio::exit.ok() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    exit "${__BASHIO_EXIT_OK}"
}
