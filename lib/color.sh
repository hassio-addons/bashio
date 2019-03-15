#!/usr/bin/env bash
# ==============================================================================
# Community Hass.io Add-ons: Bashio
# Bashio is an bash function library for use with Hass.io add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reset color output (background and foreground colors).
# ------------------------------------------------------------------------------
function bashio::color.reset() {
    printf "${__BASHIO_COLORS_RESET}" >&2
}

# ------------------------------------------------------------------------------
# Set default output color.
# ------------------------------------------------------------------------------
function bashio::color.default() {
    printf "${__BASHIO_COLORS_DEFAULT}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to black.
# ------------------------------------------------------------------------------
function bashio::color.black() {
    printf "${__BASHIO_COLORS_BLACK}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to red.
# ------------------------------------------------------------------------------
function bashio::color.red() {
    printf "${__BASHIO_COLORS_RED}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to green.
# ------------------------------------------------------------------------------
function bashio::color.green() {
    printf "${__BASHIO_COLORS_GREEN}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to yellow.
# ------------------------------------------------------------------------------
function bashio::color.yellow() {
    printf "${__BASHIO_COLORS_YELLOW}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to blue.
# ------------------------------------------------------------------------------
function bashio::color.blue() {
    printf "${__BASHIO_COLORS_BLUE}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to magenta.
# ------------------------------------------------------------------------------
function bashio::color.magenta() {
    printf "${__BASHIO_COLORS_MAGENTA}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color to cyan.
# ------------------------------------------------------------------------------
function bashio::color.cyan() {
    printf "${__BASHIO_COLORS_CYAN}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to default.
# ------------------------------------------------------------------------------
function bashio::color.bg.default() {
    printf "${__BASHIO_COLORS_BG_DEFAULT}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to black.
# ------------------------------------------------------------------------------
function bashio::color.bg.black() {
    printf "${__BASHIO_COLORS_BG_BLACK}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to red.
# ------------------------------------------------------------------------------
function bashio::color.bg.red() {
    printf "${__BASHIO_COLORS_BG_RED}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to green.
# ------------------------------------------------------------------------------
function bashio::color.bg.green() {
    printf "${__BASHIO_COLORS_BG_GREEN}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to yellow.
# ------------------------------------------------------------------------------
function bashio::color.bg.yellow() {
    printf "${__BASHIO_COLORS_BG_YELLOW}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to blue.
# ------------------------------------------------------------------------------
function bashio::color.bg.blue() {
    printf "${__BASHIO_COLORS_BG_BLUE}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to magenta.
# ------------------------------------------------------------------------------
function bashio::color.bg.magenta() {
    printf "${__BASHIO_COLORS_BG_MAGENTA}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to cyan.
# ------------------------------------------------------------------------------
function bashio::color.bg.cyan() {
    printf "${__BASHIO_COLORS_BG_CYAN}" >&2
}

# ------------------------------------------------------------------------------
# Set font output color background to white.
# ------------------------------------------------------------------------------
function bashio::color.bg.white() {
    printf "${__BASHIO_COLORS_BG_WHITE}" >&2
}
