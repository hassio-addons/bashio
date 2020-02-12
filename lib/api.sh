#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Makes a call to the Supervisor API.
#
# Arguments:
#   $1 HTTP Method (GET/POST)
#   $2 API Resource requested
#   $3 Whether or not this resource returns raw data instead of json (optional)
#   $3 In case of a POST method, this parameter is the JSON to POST (optional)
#   $4 jq filter command (optional)
# ------------------------------------------------------------------------------
function bashio::api.supervisor() {
    local method=${1}
    local resource=${2}
    local raw=${3:-}
    local filter=${4:-}
    local auth_header='Authorization: Bearer'
    local response
    local status
    local data='{}'
    local result

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if [[ -n "${__BASHIO_SUPERVISOR_TOKEN:-}" ]]; then
        auth_header="Authorization: Bearer ${__BASHIO_SUPERVISOR_TOKEN}"
    fi

    if [[ "${method}" = "POST" ]] && bashio::var.has_value "${raw}"; then
        data="${raw}"
    fi

    if ! response=$(curl --silent --show-error \
        --write-out '\n%{http_code}' --request "${method}" \
        -H "${auth_header}" \
        -H "Content-Type: application/json" \
        -d "${data}" \
        "${__BASHIO_SUPERVISOR_API}${resource}"
    ); then
        bashio::log.debug "${response}"
        bashio::log.error "Something went wrong contacting the API"
        return "${__BASHIO_EXIT_NOK}"
    fi

    status=${response##*$'\n'}
    response=${response%$status}

    bashio::log.debug "Requested API resource: ${__BASHIO_SUPERVISOR_API}${resource}"
    bashio::log.debug "Request method: ${method}"
    bashio::log.debug "Request data: ${data}"
    bashio::log.debug "API HTTP Response code: ${status}"
    bashio::log.debug "API Response: ${response}"

    if [[ "${status}" -eq 401 ]]; then
        bashio::log.error "Unable to authenticate with the API, permission denied"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -eq 404 ]]; then
        bashio::log.error "Requested resource ${resource} was not found"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -eq 405 ]]; then
        bashio::log.error "Requested resource ${resource} was called using an" \
            "unallowed method."
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ $(bashio::jq "${response}" ".result") = "error" ]]; then
        bashio::log.error "Got unexpected response from the API:" \
            "$(bashio::jq "${response}" '.message // empty')"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -ne 200 ]]; then
        bashio::log.error "Unknown HTTP error occured"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if bashio::var.true "${raw}"; then
        echo "${response}"
        return "${__BASHIO_EXIT_NOK}"
    fi

    result=$(bashio::jq "${response}" 'if .data == {} then empty else .data end')

    if bashio::var.has_value "${filter}"; then
        bashio::log.debug "Filtering response using: ${filter}"
        result=$(bashio::jq "${result}" "${filter}")
    fi

    echo "${result}"
    return "${__BASHIO_EXIT_OK}"
}
