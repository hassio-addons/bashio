#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# ------------------------------------------------------------------------------
# Publish a new configuration object for discovery.
#
# Arguments:
#   $1 Service name
#   $2 Configuration object (JSON)
# ------------------------------------------------------------------------------
function bashio::discovery() {
    local service=${1}
    local config=${2}
    local payload

    # The configuration object can carry credentials (for example MQTT broker
    # username and password), so trace only the function name and the service,
    # never the configuration payload.
    bashio::log.trace "${FUNCNAME[0]}" "${service}"

    payload=$(
        bashio::var.json \
            service "${service}" \
            config "^${config}"
    )

    bashio::api.supervisor "POST" "/discovery" "${payload}" ".uuid" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}

# ------------------------------------------------------------------------------
# Deletes configuration object for this discovery.
#
# Arguments:
#   $1 Discovery UUID
# ------------------------------------------------------------------------------
function bashio::discovery.delete() {
    local uuid=${1}

    bashio::log.trace "${FUNCNAME[0]}" "$@"
    bashio::api.supervisor "DELETE" "/discovery/${uuid}" ||
        return "${__BASHIO_EXIT_NOK}"
    bashio::cache.flush_all
}
