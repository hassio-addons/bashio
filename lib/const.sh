#!/usr/bin/env bash
# shellcheck disable=SC2034
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# Defaults
readonly __BASHIO_DEFAULT_ADDON_CONFIG="/data/options.json"
readonly __BASHIO_DEFAULT_CACHE_DIR="/tmp/.bashio"
readonly __BASHIO_DEFAULT_HIBP_ENDPOINT="https://api.pwnedpasswords.com/range"
readonly __BASHIO_DEFAULT_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
readonly __BASHIO_DEFAULT_LOG_LEVEL=5 # Defaults to INFO
readonly __BASHIO_DEFAULT_LOG_TIMESTAMP="%T"
readonly __BASHIO_DEFAULT_SUPERVISOR_API="http://supervisor"
readonly __BASHIO_DEFAULT_SUPERVISOR_TOKEN=""

# Exit codes
readonly __BASHIO_EXIT_OK=0    # Successful termination
readonly __BASHIO_EXIT_NOK=1   # Termination with errors

# Log levels
readonly __BASHIO_LOG_LEVEL_ALL=8
readonly __BASHIO_LOG_LEVEL_DEBUG=6
readonly __BASHIO_LOG_LEVEL_ERROR=2
readonly __BASHIO_LOG_LEVEL_FATAL=1
readonly __BASHIO_LOG_LEVEL_INFO=5
readonly __BASHIO_LOG_LEVEL_NOTICE=4
readonly __BASHIO_LOG_LEVEL_OFF=0
readonly __BASHIO_LOG_LEVEL_TRACE=7
readonly __BASHIO_LOG_LEVEL_WARNING=3
readonly -A __BASHIO_LOG_LEVELS=(
    [${__BASHIO_LOG_LEVEL_OFF}]="OFF"
    [${__BASHIO_LOG_LEVEL_FATAL}]="FATAL"
    [${__BASHIO_LOG_LEVEL_ERROR}]="ERROR"
    [${__BASHIO_LOG_LEVEL_WARNING}]="WARNING"
    [${__BASHIO_LOG_LEVEL_NOTICE}]="NOTICE"
    [${__BASHIO_LOG_LEVEL_INFO}]="INFO"
    [${__BASHIO_LOG_LEVEL_DEBUG}]="DEBUG"
    [${__BASHIO_LOG_LEVEL_TRACE}]="TRACE"
    [${__BASHIO_LOG_LEVEL_ALL}]="ALL"
)

# Colors
readonly __BASHIO_COLORS_ESCAPE="\033[";
readonly __BASHIO_COLORS_RESET="${__BASHIO_COLORS_ESCAPE}0m"
readonly __BASHIO_COLORS_DEFAULT="${__BASHIO_COLORS_ESCAPE}39m"
readonly __BASHIO_COLORS_BLACK="${__BASHIO_COLORS_ESCAPE}30m"
readonly __BASHIO_COLORS_RED="${__BASHIO_COLORS_ESCAPE}31m"
readonly __BASHIO_COLORS_GREEN="${__BASHIO_COLORS_ESCAPE}32m"
readonly __BASHIO_COLORS_YELLOW="${__BASHIO_COLORS_ESCAPE}33m"
readonly __BASHIO_COLORS_BLUE="${__BASHIO_COLORS_ESCAPE}34m"
readonly __BASHIO_COLORS_MAGENTA="${__BASHIO_COLORS_ESCAPE}35m"
readonly __BASHIO_COLORS_CYAN="${__BASHIO_COLORS_ESCAPE}36m"
readonly __BASHIO_COLORS_LIGHT_GRAY="${__BASHIO_COLORS_ESCAPE}37m"
readonly __BASHIO_COLORS_BG_DEFAULT="${__BASHIO_COLORS_ESCAPE}49m"
readonly __BASHIO_COLORS_BG_BLACK="${__BASHIO_COLORS_ESCAPE}40m"
readonly __BASHIO_COLORS_BG_RED="${__BASHIO_COLORS_ESCAPE}41m"
readonly __BASHIO_COLORS_BG_GREEN="${__BASHIO_COLORS_ESCAPE}42m"
readonly __BASHIO_COLORS_BG_YELLOW="${__BASHIO_COLORS_ESCAPE}43m"
readonly __BASHIO_COLORS_BG_BLUE="${__BASHIO_COLORS_ESCAPE}44m"
readonly __BASHIO_COLORS_BG_MAGENTA="${__BASHIO_COLORS_ESCAPE}45m"
readonly __BASHIO_COLORS_BG_CYAN="${__BASHIO_COLORS_ESCAPE}46m"
readonly __BASHIO_COLORS_BG_WHITE="${__BASHIO_COLORS_ESCAPE}47m"
