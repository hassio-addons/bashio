#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Converts a string to lower case.
#
# Arguments:
#   $1 String to convert
# ------------------------------------------------------------------------------
function bashio::string.lower() {
    local string="${1}"

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    printf "%s" "${string,,}"
}

# ------------------------------------------------------------------------------
# Converts a string to upper case.
#
# Arguments:
#   $1 String to convert
# ------------------------------------------------------------------------------
function bashio::string.upper() {
    local string="${1}"

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    printf "%s" "${string^^}"
}

# ------------------------------------------------------------------------------
# Replaces parts of the string with another string.
#
# Arguments:
#   $1 String to make replacements in
#   $2 String part to replace
#   $3 String replacement
# ------------------------------------------------------------------------------
function bashio::string.replace() {
    local string="${1}"
    local needle="${2}"
    local replacement="${3}"

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    printf "%s" "${string//"${needle}"/${replacement}}"
}

# ------------------------------------------------------------------------------
# Returns the length of a string.
#
# Arguments:
#   $1 String to determine the length of
# ------------------------------------------------------------------------------
bashio::string.length() {
    local string="${1}"

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    printf "%s" "${#string}"
}

# ------------------------------------------------------------------------------
# Returns a substring of a string.
#
# stringZ=abcABC123ABCabc
# bashio::string.substring "${stringZ}" 0      # abcABC123ABCabc
# bashio::string.substring "${stringZ}" 1      # bcABC123ABCabc
# bashio::string.substring "${stringZ}" 7      # 23ABCabc
# bashio::string.substring "${stringZ}" 7 3    # 23A
#
# Arguments:
#   $1 String to return a substring of
#   $2 Position to start
#   $3 Length of the substring (optional)
# ------------------------------------------------------------------------------
bashio::string.substring() {
    local string="${1}"
    local position="${2}"
    local length="${3:-}"

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::var.has_value "${length}"; then
        printf "%s" "${string:${position}:${length}}"
    else
        printf "%s" "${string:${position}}"
    fi
}
