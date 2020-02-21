#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Get configuration object or configuration options from a service.
#
# Arguments:
#   $1 Service name
#   $2 Config option to get (optional)
# ------------------------------------------------------------------------------
function bashio::services() {
    local service=${1}
    local key=${2:-}
    local cache_key="service.info.${service}"
    local config
    local query
    local response

    bashio::log.trace "${FUNCNAME[0]}" "$@"

    if bashio::cache.exists "${cache_key}"; then
        config=$(bashio::cache.get "${cache_key}")
    else
        config=$(bashio::api.supervisor GET "/services/${service}" false)
        bashio::cache.set "${cache_key}" "${config}"
    fi

    response="${config}"
    if bashio::var.has_value "${key}"; then

        read -r -d '' query << QUERY
            if (.${key} == null) then
                null
            elif (.${key} | type == "string") then
                .${key} // empty
            elif (.${key} | type == "boolean") then
                .${key} // false
            elif (.${key} | type == "array") then
                if (.${key} == []) then
                    empty
                else
                    .${key}[]
                end
            elif (.${key} | type == "object") then
                if (.${key} == {}) then
                    empty
                else
                    .${key}
                end
            else
                .${key}
            end
QUERY
        response=$(bashio::jq "${config}" "${query}")
    fi

    printf "%s" "${response}"

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Check if this service is available.
#
# Arguments:
#   $1 Service name
# ------------------------------------------------------------------------------
function bashio::services.available() {
    local service=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::api.supervisor GET "/services/${service}" > /dev/null 2>&1;
    then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Publish a new configuration object for this service.
#
# Arguments:
#   $1 Service name
#   $2 Configuration object (JSON)
# ------------------------------------------------------------------------------
function bashio::services.publish() {
    local service=${1}
    local config=${2}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    bashio::api.supervisor "POST" "/services/${service}" "${config}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Deletes configuration object for this service.
#
# Arguments:
#   $1 Service name
# ------------------------------------------------------------------------------
function bashio::services.delete() {
    local service=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"
    bashio::api.supervisor "DELETE" "/services/${service}"
    bashio::cache.flush_all
}
