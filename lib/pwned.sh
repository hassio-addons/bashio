#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Checks if a given password is safe to use.
#
# Arguments:
#   $1 The password to check
# ------------------------------------------------------------------------------
function bashio::pwned.is_safe_password() {
    local password="${1}"
    local occurrences

    bashio::log.trace "${FUNCNAME[0]}" "<REDACTED PASSWORD>"

    if ! occurrences=$(bashio::pwned "${password}"); then
        bashio::log.warning "Could not check password, assuming it is safe."
        return "${__BASHIO_EXIT_OK}"
    fi

    if [[ "${occurrences}" -ne 0 ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Gets the number of occurrences of the password in the list.
#
# Arguments:
#   $1 The password to check
# ------------------------------------------------------------------------------
function bashio::pwned.occurances() {
    local password="${1}"
    local occurances

    bashio::log.trace "${FUNCNAME[0]}" "<REDACTED PASSWORD>"

    if ! occurances=$(bashio::pwned "${password}"); then
        occurances="0"
    fi

    echo -n "${occurances}"
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Makes a call to the Have I Been Pwned password database
#
# Arguments:
#   $1 The password to check
# ------------------------------------------------------------------------------
function bashio::pwned() {
    local password="${1}"
    local response
    local status
    local hibp_hash
    local count

    bashio::log.trace "${FUNCNAME[0]}" "${password//./x}"

    # Do not check empty password
    if ! bashio::var.has_value "${password}"; then
        bashio::log.warning 'Cannot check empty password against HaveIBeenPwned.'
        return "${__BASHIO_EXIT_NOK}"
    fi

    # Hash the password
    password=$(echo -n "${password}" \
        | sha1sum \
        | tr '[:lower:]' '[:upper:]' \
        | awk -F' ' '{ print $1 }'
    )
    bashio::log.debug "Password SHA1: ${password}"

    # Check with have I Been Pwned, only send the first 5 chars of the hash
    if ! response=$(curl \
        --silent \
        --show-error \
        --write-out '\n%{http_code}' \
        --request GET \
        "${__BASHIO_HIBP_ENDPOINT}/${password:0:5}"
    ); then
        bashio::log.debug "${response}"
        bashio::log.error "Something went wrong contacting the HIBP API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    status=${response##*$'\n'}
    response=${response%$status}

    bashio::log.debug "Requested API resource: ${__BASHIO_HIBP_ENDPOINT}/${password:0:5}"
    bashio::log.debug "API HTTP Response code: ${status}"
    bashio::log.trace "API Response: ${response}"

    if [[ "${status}" -eq 429 ]]; then
        bashio::log.error "HIBP Rate limit exceeded."
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -eq 503 ]]; then
        bashio::log.error "HIBP Service unavailable."
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -ne 200 ]]; then
        bashio::log.error "Unknown HIBP HTTP error occurred."
        return "${__BASHIO_EXIT_NOK}"
    fi

    # Check the list of returned hashes for a match
    for hibp_hash in ${response}; do
        if [[ "${password:5:35}" == "${hibp_hash%%:*}" ]]; then
            # Found a match! This is bad :(
            count=$(echo "${hibp_hash#*:}" | tr -d '\r')

            bashio::log.warning \
                "Password is in the Have I Been Pwned database!"
            bashio::log.warning \
                "Password appeared ${count} times!"
            echo "${count}"

            # Well, at least the execution of this function succeeded.
            return "${__BASHIO_EXIT_OK}"
        fi
    done

    # Password was not found
    echo "0"
    bashio::log.info "Password is NOT in the Have I Been Pwned database! Nice!"

    return "${__BASHIO_EXIT_OK}"
}
