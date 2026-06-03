#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Makes a call to the Supervisor API.
#
# Arguments:
#   $1 HTTP Method (GET/POST)
#   $2 API Resource requested
#   $3 For GET: whether this resource returns raw data instead of JSON (optional)
#      For POST: the JSON document to send as the request body (optional)
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
    local data_file=''
    local result

    # The request body can carry secrets (for example app options), so it is
    # deliberately kept out of the trace log.
    bashio::log.trace "${FUNCNAME[0]}" "${method}" "${resource}"

    if [[ -n "${__BASHIO_SUPERVISOR_TOKEN:-}" ]]; then
        auth_header="Authorization: Bearer ${__BASHIO_SUPERVISOR_TOKEN}"
    fi

    # Use a plain emptiness test (not bashio::var.has_value) so the request
    # body, which can carry secrets, is never passed to a helper that traces
    # its arguments.
    if [[ "${method}" = "POST" ]] && [[ -n "${raw}" ]]; then
        data="${raw}"
        raw=
    fi

    # Only a POST body can carry secrets, so just that case is routed through a
    # temporary file (curl --data-binary @file) instead of a command-line
    # argument, keeping it out of the process list (/proc/<pid>/cmdline). The
    # file is created with restrictive permissions by mktemp and removed right
    # after the call. Other methods send their constant, non-sensitive body
    # inline and therefore do not depend on mktemp.
    local data_args
    if [[ "${method}" = "POST" ]]; then
        if ! data_file=$(mktemp); then
            bashio::log.error "Could not create a temporary file for the API request"
            return "${__BASHIO_EXIT_NOK}"
        fi
        printf '%s' "${data}" >"${data_file}"
        data_args=(--data-binary @"${data_file}")
    else
        data_args=(--data-binary "${data}")
    fi

    if ! response=$(
        # Pass the authorization header via stdin (curl -H @-) instead of a
        # command-line argument, so the Supervisor token is not exposed in the
        # process list (/proc/<pid>/cmdline). Reading the header from stdin keeps
        # the value literal, so tokens with special characters are handled safely.
        curl --silent --show-error \
            --write-out '\n%{http_code}' --request "${method}" \
            -H @- \
            -H "Content-Type: application/json" \
            "${data_args[@]}" \
            "${__BASHIO_SUPERVISOR_API}${resource}" <<<"${auth_header}"
    ); then
        [[ -n "${data_file}" ]] && rm -f "${data_file}"
        bashio::log.debug "${response}"
        bashio::log.error "Something went wrong contacting the API"
        return "${__BASHIO_EXIT_NOK}"
    fi
    [[ -n "${data_file}" ]] && rm -f "${data_file}"

    status=${response##*$'\n'}
    response=${response%"$status"}

    bashio::log.debug "Requested API resource: ${__BASHIO_SUPERVISOR_API}${resource}"
    bashio::log.debug "Request method: ${method}"
    bashio::log.debug "API HTTP Response code: ${status}"
    bashio::log.debug "API Response: ${response}"

    if [[ "${status}" -eq 401 ]]; then
        bashio::log.error "Unable to authenticate with the API, permission denied"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if [[ "${status}" -eq 403 ]]; then
        bashio::log.error "Unable to access the API, forbidden"
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

    if ! bashio::var.true "${raw}"; then
        result=$(bashio::jq "${response}" ".result")
        if bashio::var.equals "${result}" "error"; then
            bashio::log.error "Got unexpected response from the API:" \
                "$(bashio::jq "${response}" '.message // empty')"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    if [[ "${status}" -ne 200 ]]; then
        bashio::log.error "Unknown HTTP error occurred"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if bashio::var.true "${raw}"; then
        echo "${response}"
        return "${__BASHIO_EXIT_OK}"
    fi

    result=$(bashio::jq "${response}" 'if .data == {} then empty else .data end')

    if bashio::var.has_value "${filter}"; then
        bashio::log.debug "Filtering response using: ${filter}"
        result=$(bashio::jq "${result}" "${filter}")
        if [ "$?" -ne "${__BASHIO_EXIT_OK}" ]; then
            bashio::log.error "Failed to execute the jq filter"
            return "${__BASHIO_EXIT_NOK}"
        fi
    fi

    echo "${result}"
    return "${__BASHIO_EXIT_OK}"
}
