#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Checks if a give value is true.
#
# Arguments:
#   $1 value
# ------------------------------------------------------------------------------
function bashio::var.true() {
    local value=${1:-null}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ "${value}" = "true" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Checks if a give value is false.
#
# Arguments:
#   $1 value
# ------------------------------------------------------------------------------
function bashio::var.false() {
    local value=${1:-null}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ "${value}" = "false" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Checks if a global variable is defined.
#
# Arguments:
#   $1 Name of the variable
# ------------------------------------------------------------------------------
bashio::var.defined() {
    local variable=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    [[ "${!variable-X}" = "${!variable-Y}" ]]
}

# ------------------------------------------------------------------------------
# Checks if a value has actual value.
#
# Arguments:
#   $1 Value
# ------------------------------------------------------------------------------
function bashio::var.has_value() {
    local value=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ -n "${value}" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Checks if a value is empty.
#
# Arguments:
#   $1 Value
# ------------------------------------------------------------------------------
function bashio::var.is_empty() {
    local value=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ -z "${value}" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Checks if a value equals.
#
# Arguments:
#   $1 Value
#   $2 Equals value
# ------------------------------------------------------------------------------
function bashio::var.equals() {
    local value=${1}
    local equals=${2}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ "${value}" = "${equals}" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Creates JSON based on function arguments.
#
# Arguments:
#   $@ Bash array of key/value pairs, prefix integer or boolean values with ^
# ------------------------------------------------------------------------------
function bashio::var.json() {
    local data=("$@");
    local number_of_items=${#data[@]}
    local json=''
    local separator
    local counter
    local item

    if [[ ${number_of_items} -eq 0 ]]; then
        bashio::log.error "Length of input array needs to be at least 2"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ $((number_of_items%2)) -eq 1 ]]; then
        bashio::log.error "Length of input array needs to be even (key/value pairs)"
        return "${__BASHIO_EXIT_NOK}"
    fi

    counter=0;
    for i in "${data[@]}"; do
        separator=","
        if [ $((++counter%2)) -eq 0 ]; then
            separator=":";
        fi

        item="\"$i\""
        if [[ "${i:0:1}" == "^" ]]; then
            item="${i:1}"
        fi

        json="$json$separator$item";
    done

    echo "{${json:1}}";
    return "${__BASHIO_EXIT_OK}"
}

