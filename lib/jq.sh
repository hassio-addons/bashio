#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Execute a JSON query.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ -f "${data}" ]]; then
        jq --raw-output -c -M "$filter" "${data}"
    else
        jq --raw-output -c -M "$filter" <<< "${data}"
    fi
}

# ------------------------------------------------------------------------------
# Checks if variable exists (optionally after filtering).
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.exists() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ $(bashio::jq "${data}" "${filter}") = "null" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if data exists (optionally after filtering).
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.has_value() {
    local data=${1}
    local filter=${2:-}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::jq "${data}" \
        "${filter} | if (. == {} or . == []) then empty else . end // empty")

    if ! bashio::var.has_value "${value}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is of a specific type.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter
#   $3 type (boolean, string, number, array, object, null)
# ------------------------------------------------------------------------------
function bashio::jq.is() {
    local data=${1}
    local filter=${2}
    local type=${3}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::jq "${data}" \
        "${filter} | if type==\"${type}\" then true else false end")

    if [[ "${value}" = "false" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is a boolean.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.is_boolean() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::jq.is "${data}" "${filter}" "boolean"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is a string.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.is_string() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::jq.is "${data}" "${filter}" "string"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is an object.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.is_object() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::jq.is "${data}" "${filter}" "object"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is a number.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.is_number() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::jq.is "${data}" "${filter}" "number"
}

# ------------------------------------------------------------------------------
# Checks if resulting data is an array.
#
# Arguments:
#   $1 JSON string or path to a JSON file
#   $2 jq filter (optional)
# ------------------------------------------------------------------------------
function bashio::jq.is_array() {
    local data=${1}
    local filter=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::jq.is "${data}" "${filter}" "array"
}
