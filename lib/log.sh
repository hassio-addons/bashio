#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Log a message to output.
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log() {
    local message=$*
    echo -e "${message}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in red).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.red() {
    local message=$*
    echo -e "${__BASHIO_COLORS_RED}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in green).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.green() {
    local message=$*
    echo -e "${__BASHIO_COLORS_GREEN}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in yellow).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.yellow() {
    local message=$*
    echo -e "${__BASHIO_COLORS_YELLOW}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in blue).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.blue() {
    local message=$*
    echo -e "${__BASHIO_COLORS_BLUE}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in magenta).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.magenta() {
    local message=$*
    echo -e "${__BASHIO_COLORS_MAGENTA}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message to output (in cyan).
#
# Arguments:
#   $1 Message to display
# ------------------------------------------------------------------------------
bashio::log.cyan() {
    local message=$*
    echo -e "${__BASHIO_COLORS_CYAN}${message}${__BASHIO_COLORS_RESET}" >&2
    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message using a log level.
#
# Arguments:
#   $1 Log level
#   $2 Message to display
# ------------------------------------------------------------------------------
function bashio::log.log() {
    local level=${1}
    local message=${2}
    local timestamp
    local output

    if [[ "${level}" -gt "${__BASHIO_LOG_LEVEL}" ]]; then
        return "${__BASHIO_EXIT_OK}"
    fi

    timestamp=$(date +"${__BASHIO_LOG_TIMESTAMP}")

    output="${__BASHIO_LOG_FORMAT}"
    output="${output//\{TIMESTAMP\}/${timestamp}}"
    output="${output//\{MESSAGE\}/${message}}"
    output="${output//\{LEVEL\}/${__BASHIO_LOG_LEVELS[$level]}}"

    echo -e "${output}" >&2

    return "${__BASHIO_EXIT_OK}"
}

# ------------------------------------------------------------------------------
# Log a message @ trace level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.trace() {
    local message=$*
    bashio::log.log "${__BASHIO_LOG_LEVEL_TRACE}" "${message}"
}

# ------------------------------------------------------------------------------
# Log a message @ debug level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.debug() {
    local message=$*
    bashio::log.log "${__BASHIO_LOG_LEVEL_DEBUG}" "${message}"
}

# ------------------------------------------------------------------------------
# Log a message @ info level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.info() {
    local message=$*
    bashio::log.log \
        "${__BASHIO_LOG_LEVEL_INFO}" \
        "${__BASHIO_COLORS_GREEN}${message}${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Log a message @ notice level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.notice() {
    local message=$*
    bashio::log.log \
        "${__BASHIO_LOG_LEVEL_NOTICE}" \
        "${__BASHIO_COLORS_CYAN}${message}${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Log a message @ warning level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.warning() {
    local message=$*
    bashio::log.log \
        "${__BASHIO_LOG_LEVEL_WARNING}" \
        "${__BASHIO_COLORS_YELLOW}${message}${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Log a message @ error level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.error() {
    local message=$*
    bashio::log.log \
        "${__BASHIO_LOG_LEVEL_ERROR}" \
        "${__BASHIO_COLORS_MAGENTA}${message}${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Log a message @ fatal level.
#
# Arguments:
#   $* Message to display
# ------------------------------------------------------------------------------
function bashio::log.fatal() {
    local message=$*
    bashio::log.log \
        "${__BASHIO_LOG_LEVEL_FATAL}" \
        "${__BASHIO_COLORS_RED}${message}${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Changes the log level of Bashio on the fly.
#
# Arguments:
#   $1 Log level
# ------------------------------------------------------------------------------
function bashio::log.level() {
    local log_level=${1}

    # Find the matching log level
    case "$(bashio::string.lower "${log_level}")" in
        all)
            log_level="${__BASHIO_LOG_LEVEL_ALL}"
            ;;
        trace)
            log_level="${__BASHIO_LOG_LEVEL_TRACE}"
            ;;
        debug)
            log_level="${__BASHIO_LOG_LEVEL_DEBUG}"
            ;;
        info)
            log_level="${__BASHIO_LOG_LEVEL_INFO}"
            ;;
        notice)
            log_level="${__BASHIO_LOG_LEVEL_NOTICE}"
            ;;
        warning)
            log_level="${__BASHIO_LOG_LEVEL_WARNING}"
            ;;
        error)
            log_level="${__BASHIO_LOG_LEVEL_ERROR}"
            ;;
        fatal|critical)
            log_level="${__BASHIO_LOG_LEVEL_FATAL}"
            ;;
        off)
            log_level="${__BASHIO_LOG_LEVEL_OFF}"
            ;;
        *)
            bashio::exit.nok "Unknown log_level: ${log_level}"
    esac

    export __BASHIO_LOG_LEVEL="${log_level}"
}
