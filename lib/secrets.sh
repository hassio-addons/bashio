#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Gets a secret value by key from secrets.yaml.
#
# Arguments:
#   $1 Secret key
# ------------------------------------------------------------------------------
bashio::secret() {
    local key=${1}
    local secret
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::fs.directory_exists "$(dirname "${__BASHIO_HA_SECRETS}")"; then
        bashio::log.error "This add-on does not support secrets!"
        return "${__BASHIO_EXIT_NOK}"
    fi

    if ! bashio::fs.file_exists "${__BASHIO_HA_SECRETS}"; then
        bashio::log.error \
            "A secret was requested, but could not find a secrets.yaml"
        return "${__BASHIO_EXIT_NOK}"
    fi

    secret="${key#'!secret '}"
    value=$(yq read "${__BASHIO_HA_SECRETS}" "${secret}" )

    if [[ "${value}" = "null" ]]; then
        bashio::log.error "Secret ${secret} not found in secrets.yaml file."
        return "${__BASHIO_EXIT_NOK}"
    fi

    printf "%s" "${value}"
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Tells whether or not a string might be a secret.
#
# Arguments:
#   $1 String to check for a secret
# ------------------------------------------------------------------------------
bashio::is_secret() {
    local string="${1}"

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ "${string}" != '!secret '* ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi
    return "${__BASHIO_EXIT_OK}"
}
