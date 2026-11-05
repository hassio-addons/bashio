#!/usr/bin/env bash
# shellcheck disable=SC2004,SC2034
# ==============================================================================
# Home Assistant Community Apps: Bashio
# Bashio is a bash function library for use with Home Assistant apps.
#
# It contains a set of commonly used operations and can be used
# to be included in app scripts to reduce code duplication across apps.
# ==============================================================================

# Version
# `git archive` fills in the placeholder below with the release tag (see
# export-subst in .gitattributes), so the release tarballs that images install
# carry their own version. It stays unexpanded in a git checkout, which is
# reported as "dev". Keep this the only format placeholder in this file:
# export-subst would also rewrite any other one.
# shellcheck disable=SC2016 # expanded by git archive, not by the shell
readonly __BASHIO_VERSION_DESCRIBE='$Format:%(describe:tags=true,match=v[0-9]*)$'
if [[ "${__BASHIO_VERSION_DESCRIBE}" =~ ^v([0-9].*)$ ]]; then
    readonly __BASHIO_VERSION="${BASH_REMATCH[1]}"
else
    readonly __BASHIO_VERSION="dev"
fi

# User-Agent for every HTTP request bashio makes, so they can be told apart
# from other curl calls, e.g. in the Supervisor's error reports.
readonly __BASHIO_USER_AGENT="bashio/${__BASHIO_VERSION}"

# Defaults
readonly __BASHIO_DEFAULT_CACHE_DIR="/tmp/.bashio"
readonly __BASHIO_DEFAULT_HIBP_ENDPOINT="https://api.pwnedpasswords.com/range"
readonly __BASHIO_DEFAULT_LOG_FORMAT="[{TIMESTAMP}] {LEVEL}: {MESSAGE}"
readonly __BASHIO_DEFAULT_LOG_LEVEL=5 # Defaults to INFO
readonly __BASHIO_DEFAULT_LOG_TIMESTAMP="%T"
readonly __BASHIO_DEFAULT_SUPERVISOR_API="http://supervisor"
readonly __BASHIO_DEFAULT_SUPERVISOR_TOKEN=""

# Exit codes
readonly __BASHIO_EXIT_OK=0  # Successful termination
readonly __BASHIO_EXIT_NOK=1 # Termination with errors

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
readonly __BASHIO_COLORS_ESCAPE="\033["
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
