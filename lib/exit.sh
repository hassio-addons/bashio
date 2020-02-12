#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Exit the script with as failed with an optional error message.
#
# Arguments:
#   $1 Error message (optional)
# ------------------------------------------------------------------------------
function bashio::exit.nok() {
    local message=${1:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

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

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

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
function hass.die_if_true() {
    local value=${1:-}
    local message=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.true "${value}"; then
        bashio::exit.nok "${message}"
    fi
}

# ------------------------------------------------------------------------------
# Exit the script when given value is empty, with an optional error message.
#
# Arguments:
#   $1 Value to check if true
#   $2 Error message (optional)
# ------------------------------------------------------------------------------
function hass.die_if_empty() {
    local value=${1:-}
    local message=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::var.is_empty "${value}"; then
        bashio::exit.nok "${message}"
    fi
}

# ------------------------------------------------------------------------------
# Exit the script nicely.
# ------------------------------------------------------------------------------
function bashio::exit.ok() {
    bashio::log.trace "${FUNCNAME[0]}" "$@"
    exit "${__BASHIO_EXIT_OK}"
}
