#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Fetches a configuration value from the add-on config file.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config() {
    local key=${1}
    local query
    local result

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

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

    result=$(bashio::jq "${__BASHIO_ADDON_CONFIG}" "${query}")

    printf "%s" "${result}"
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option exists in the config file
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.exists() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if [[ $(bashio::config "${key}") == "null" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option has an actual value.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.has_value() {
    local key=${1}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::config "${key}")
    if [[ "${value}" == "null" ]]; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    if ! bashio::var.has_value "${value}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option has an empty value.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.is_empty() {
    local key=${1}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::config "${key}")
    if bashio::var.is_empty "${value}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    if [[ "${value}" == "null" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option equals a value.
#
# Arguments:
#   $1 Key of the config option
#   $2 Checks if the configuration option matches
# ------------------------------------------------------------------------------
function bashio::config.equals() {
    local key=${1}
    local equals=${2}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::config "${key}")
    if ! bashio::var.equals "${value}" "${equals}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option is true.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.true() {
    local key=${1}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::config "${key}")
    if ! bashio::var.true "${value}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a configuration option is false.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.false() {
    local key=${1}
    local value

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    value=$(bashio::config "${key}")
    if ! bashio::var.false "${value}"; then
        return "${__BASHIO_EXIT_NOK}"
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if a password is safe to use, using IHaveBeenPwned.
#
# Arguments:
#   $1 Key of the config option
# ------------------------------------------------------------------------------
function bashio::config.is_safe_password() {
    local key=${1}
    local password

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    # If the password is safe, we'll accept it anyways.
    password=$(bashio::config "${key}")
    if bashio::pwned.is_safe_password "${password}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    # If the bypass is enabled, we'll return OK.
    if bashio::config.true "i_like_to_be_pwned"; then
        bashio::log.warning "Have I Been Pwned bypass enabled."
        return "${__BASHIO_EXIT_OK}"
    fi

    # If we reach this point, we'll just fail.
    return "${__BASHIO_EXIT_NOK}"
}

# ------------------------------------------------------------------------------
# Require a configuration option to be set by the user.
#
# Arguments:
#   $1 Key of the config option
#   $2 Addition reason why this is needed
# ------------------------------------------------------------------------------
function bashio::config.require() {
    local key=${1}
    local reason=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::config.has_value "${key}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal
    bashio::log.fatal "A required add-on configuration option is missing!"
    bashio::log.fatal
    bashio::log.fatal "Please set a value for the '${key}' option."
    if bashio::var.has_value "${reason}"; then
        bashio::log.fatal
        bashio::log.fatal "This option is required because:"
        bashio::log.fatal "${reason}"
    fi
    bashio::log.fatal
    bashio::log.fatal "If unsure, check the add-on manual for more information."
    bashio::log.fatal

    bashio::exit.nok
}

# ------------------------------------------------------------------------------
# Suggest on setting a configuration option to the user.
#
# Arguments:
#   $1 Key of the config option
#   $2 Addition reason why this is needed
# ------------------------------------------------------------------------------
function bashio::config.suggest() {
    local key=${1}
    local reason=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::config.has_value "${key}"; then
        bashio::log.warning
        bashio::log.warning \
            "A recommended add-on configuration option is not set."
        bashio::log.warning
        bashio::log.warning "The configuration key '${key}' seems to be empty."
        bashio::log.warning
        if bashio::var.has_value "${reason}"; then
            bashio::log.warning
            bashio::log.warning "Consider configuring this because:"
            bashio::log.warning "${reason}"
        fi
        bashio::log.warning "Check the add-on manual for more information."
        bashio::log.warning
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Suggest on enabling a configuration option to the user.
#
# Arguments:
#   $1 Key of the config option
#   $2 Addition reason why this is needed
# ------------------------------------------------------------------------------
function bashio::config.suggest.true() {
    local key=${1}
    local reason=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::config.true "${key}"; then
        bashio::log.warning
        bashio::log.warning \
            "A recommended add-on configuration option is not enabled."
        if bashio::var.has_value "${reason}"; then
            bashio::log.warning
            bashio::log.warning "Consider enabling this because:"
            bashio::log.warning "${reason}"
        fi
        bashio::log.warning
        bashio::log.warning "Enable config option '${key}' hide this message."
        bashio::log.warning
        bashio::log.warning "Check the add-on manual for more information."
        bashio::log.warning
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Suggest on disabling a configuration option to the user.
#
# Arguments:
#   $1 Key of the config option
#   $2 Addition reason why this is needed
# ------------------------------------------------------------------------------
function bashio::config.suggest.false() {
    local key=${1}
    local reason=${2:-}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::config.false "${key}"; then
        bashio::log.warning
        bashio::log.warning \
            "A recommended add-on configuration option is not disabled."
        if bashio::var.has_value "${reason}"; then
            bashio::log.warning
            bashio::log.warning "Consider disabling this because:"
            bashio::log.warning "${reason}"
        fi
        bashio::log.warning
        bashio::log.warning "Disable config option '${key}' hide this message."
        bashio::log.warning
        bashio::log.warning "Check the add-on manual for more information."
        bashio::log.warning
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Require the user to configure a username.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'username')
# ------------------------------------------------------------------------------
function bashio::config.require.username() {
    local key=${1:-"username"}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::config.has_value "${key}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal
    bashio::log.fatal "Setting a username is required!"
    bashio::log.fatal
    bashio::log.fatal "Please username in the '${key}' option."
    bashio::log.fatal
    bashio::log.fatal "If unsure, check the add-on manual for more information."
    bashio::log.fatal

    bashio::exit.nok
}

# ------------------------------------------------------------------------------
# Suggest to the user to set a username, in case it is not.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'username')
# ------------------------------------------------------------------------------
function bashio::config.suggest.username() {
    local key=${1}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::config.has_value "${key}"; then
        bashio::log.warning
        bashio::log.warning \
            "Setting a username is highly recommended!"
        bashio::log.warning
        bashio::log.warning "Define a username in the '${key}' option."
        bashio::log.warning
        bashio::log.warning "Check the add-on manual for more information."
        bashio::log.warning
    fi

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Checks if the password has been set and exits when it is not.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'password')
# ------------------------------------------------------------------------------
function bashio::config.require.password() {
    local key=${1:-"password"}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::config.has_value "${key}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal
    bashio::log.fatal "Setting a password is required!"
    bashio::log.fatal
    bashio::log.fatal "Please set a password in the '${key}' option."
    bashio::log.fatal
    bashio::log.fatal "If unsure, check the add-on manual for more information."
    bashio::log.fatal

    bashio::exit.nok
}

# ------------------------------------------------------------------------------
# Suggest to set a password if it was not set.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'password')
# ------------------------------------------------------------------------------
function bashio::config.suggest.password() {
    local key=${1:-"password"}

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if bashio::config.has_value "${key}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.warning
    bashio::log.warning "Setting a password is highly recommended!"
    bashio::log.warning
    bashio::log.warning "Please set a password in the '${key}' option."
    bashio::log.warning
    bashio::log.warning \
        "If unsure, check the add-on manual for more information."
    bashio::log.warning

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Require to set a password which is not in HaveIBeenPwned database.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'password')
# ------------------------------------------------------------------------------
function bashio::config.require.safe_password() {
    local key=${1:-"password"}
    local password

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    bashio::config.require.password "${key}"

    password=$(bashio::config "${key}")

    if bashio::pwned.is_safe_password "${password}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.fatal
    bashio::log.fatal "We are trying to help you to protect your system the"
    bashio::log.fatal "best we can. Therefore, this add-on checks your"
    bashio::log.fatal "configured password against the HaveIBeenPwned database."
    bashio::log.fatal
    bashio::log.fatal "Unfortunately, your configured password is considered"
    bashio::log.fatal "unsafe. We highly recommend you to pick a different one."
    bashio::log.fatal
    bashio::log.fatal "Please change the password in the '${key}' option."
    bashio::log.fatal
    bashio::log.fatal "Check the add-on manual for more information."
    bashio::log.fatal

    bashio::exit.nok
}

# ------------------------------------------------------------------------------
# Suggest to set a password which is not in HaveIBeenPwned database.
#
# Arguments:
#   $1 Key of the config option (optional: defaults to 'password')
# ------------------------------------------------------------------------------
function bashio::config.suggest.safe_password() {
    local key=${1:-"password"}
    local password

    bashio::log.trace "${FUNCNAME[0]}:" "$@"

    if ! bashio::config.has_value "${key}"; then
        bashio::config.suggest.password "${key}"
        return "${__BASHIO_EXIT_OK}"
    fi

    password=$(bashio::config "${key}")

    if bashio::pwned.is_safe_password "${password}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    bashio::log.warning
    bashio::log.warning "We are trying to help you to protect your system the"
    bashio::log.warning "best we can. Therefore, this add-on checks your"
    bashio::log.warning "configured password against the HaveIBeenPwned database."
    bashio::log.warning
    bashio::log.warning "Unfortunately, your configured password is considered"
    bashio::log.warning "unsafe. It is recommended to pick a different one."
    bashio::log.warning
    bashio::log.warning "Please change the password in the '${key}' option."
    bashio::log.warning
    bashio::log.warning "Check the add-on manual for more information."
    bashio::log.warning

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Check if certificate files exists when SSL is enabled.
#
# Arguments:
#   $1 Key of the ssl config option (optional: defaults to 'ssl')
#   $2 Key of the cert file config option (optional: defaults to 'certfile')
#   $3 Key of the cert key file config option (optional: defaults to 'keyfile')
# ------------------------------------------------------------------------------
function bashio::config.require.ssl() {
    local key=${1:-"ssl"}
    local certfile=${2:-"certfile"}
    local keyfile=${3:-"keyfile"}

    if ! bashio::config.true "${key}"; then
        return "${__BASHIO_EXIT_OK}"
    fi

    if bashio::config.is_empty "${certfile}"; then
        bashio::log.fatal
        bashio::log.fatal "SSL has been enabled using the '${key}' option,"
        bashio::log.fatal "this requires a SSL certificate file which is"
        bashio::log.fatal "configured using the '${certfile}' option in the"
        bashio::log.fatal "add-on configuration."
        bashio::log.fatal
        bashio::log.fatal "Unfortunately, the '${certfile}' option is empty."
        bashio::log.fatal
        bashio::log.fatal "Consider configuring or getting a SSL certificate"
        bashio::log.fatal "or setting the '${key}' option to 'false' in case"
        bashio::log.fatal "you are not planning on using SSL with this add-on."
        bashio::log.fatal
        bashio::log.fatal "Check the add-on manual for more information."
        bashio::log.fatal

        bashio::exit.nok
    fi

    if bashio::config.is_empty "${keyfile}"; then
        bashio::log.fatal
        bashio::log.fatal "SSL has been enabled using the '${key}' option,"
        bashio::log.fatal "this requires a SSL certificate key file which is"
        bashio::log.fatal "configured using the '${keyfile}' option in the"
        bashio::log.fatal "add-on configuration."
        bashio::log.fatal
        bashio::log.fatal "Unfortunately, the '${keyfile}' option is empty."
        bashio::log.fatal
        bashio::log.fatal "Consider configuring or getting a SSL certificate"
        bashio::log.fatal "or setting the '${key}' option to 'false' in case"
        bashio::log.fatal "you are not planning on using SSL with this add-on."
        bashio::log.fatal
        bashio::log.fatal "Check the add-on manual for more information."
        bashio::log.fatal

        bashio::exit.nok
    fi

    if ! bashio::fs.file_exists "/ssl/$(bashio::config "${certfile}")"; then
        bashio::log.fatal
        bashio::log.fatal "SSL has been enabled using the '${key}' option,"
        bashio::log.fatal "this requires a SSL certificate file which is"
        bashio::log.fatal "configured using the '${certfile}' option in the"
        bashio::log.fatal "add-on configuration."
        bashio::log.fatal
        bashio::log.fatal "Unfortunately, the file specified in the"
        bashio::log.fatal "'${certfile}' option does not exists."
        bashio::log.fatal
        bashio::log.fatal "Please ensure the certificate file exists and"
        bashio::log.fatal "is placed in the '/ssl/' directory."
        bashio::log.fatal
        bashio::log.fatal "In case you don't have SSL yet, consider getting"
        bashio::log.fatal "a SSL certificate or setting the '${key}' option"
        bashio::log.fatal "to 'false' in case you are not planning on using"
        bashio::log.fatal "SSL with this add-on."
        bashio::log.fatal
        bashio::log.fatal "Check the add-on manual for more information."
        bashio::log.fatal

        bashio::exit.nok
    fi

    if ! bashio::fs.file_exists "/ssl/$(bashio::config "${keyfile}")"; then
        bashio::log.fatal
        bashio::log.fatal "SSL has been enabled using the '${key}' option,"
        bashio::log.fatal "this requires a SSL certificate key file which is"
        bashio::log.fatal "configured using the '${keyfile}' option in the"
        bashio::log.fatal "add-on configuration."
        bashio::log.fatal
        bashio::log.fatal "Unfortunately, the file specified in the"
        bashio::log.fatal "'${keyfile}' option does not exists."
        bashio::log.fatal
        bashio::log.fatal "Please ensure the certificate key file exists and"
        bashio::log.fatal "is placed in the '/ssl/' directory."
        bashio::log.fatal
        bashio::log.fatal "In case you don't have SSL yet, consider getting"
        bashio::log.fatal "a SSL certificate or setting the '${key}' option"
        bashio::log.fatal "to 'false' in case you are not planning on using"
        bashio::log.fatal "SSL with this add-on."
        bashio::log.fatal
        bashio::log.fatal "Check the add-on manual for more information."
        bashio::log.fatal

        bashio::exit.nok
    fi

    return "${__BASHIO_EXIT_OK}"
}
