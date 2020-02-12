#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Community Add-ons: Bashio
# Bashio is an bash function library for use with Home Assistant add-ons.
#
# It contains a set of commonly used operations and can be used
# to be included in add-on scripts to reduce code duplication across add-ons.
# ==============================================================================

# ------------------------------------------------------------------------------
# Reset color output (background and foreground colors).
# ------------------------------------------------------------------------------
function bashio::color.reset() {
    echo -n -e "${__BASHIO_COLORS_RESET}"
}

# ------------------------------------------------------------------------------
# Set default output color.
# ------------------------------------------------------------------------------
function bashio::color.default() {
    echo -n -e "${__BASHIO_COLORS_DEFAULT}"
}

# ------------------------------------------------------------------------------
# Set font output color to black.
# ------------------------------------------------------------------------------
function bashio::color.black() {
    echo -n -e "${__BASHIO_COLORS_BLACK}"
}

# ------------------------------------------------------------------------------
# Set font output color to red.
# ------------------------------------------------------------------------------
function bashio::color.red() {
    echo -n -e "${__BASHIO_COLORS_RED}"
}

# ------------------------------------------------------------------------------
# Set font output color to green.
# ------------------------------------------------------------------------------
function bashio::color.green() {
    echo -n -e "${__BASHIO_COLORS_GREEN}"
}

# ------------------------------------------------------------------------------
# Set font output color to yellow.
# ------------------------------------------------------------------------------
function bashio::color.yellow() {
    echo -n -e "${__BASHIO_COLORS_YELLOW}"
}

# ------------------------------------------------------------------------------
# Set font output color to blue.
# ------------------------------------------------------------------------------
function bashio::color.blue() {
    echo -n -e "${__BASHIO_COLORS_BLUE}"
}

# ------------------------------------------------------------------------------
# Set font output color to magenta.
# ------------------------------------------------------------------------------
function bashio::color.magenta() {
    echo -n -e "${__BASHIO_COLORS_MAGENTA}"
}

# ------------------------------------------------------------------------------
# Set font output color to cyan.
# ------------------------------------------------------------------------------
function bashio::color.cyan() {
    echo -n -e "${__BASHIO_COLORS_CYAN}"
}

# ------------------------------------------------------------------------------
# Set font output color background to default.
# ------------------------------------------------------------------------------
function bashio::color.bg.default() {
    echo -n -e "${__BASHIO_COLORS_BG_DEFAULT}"
}

# ------------------------------------------------------------------------------
# Set font output color background to black.
# ------------------------------------------------------------------------------
function bashio::color.bg.black() {
    echo -n -e "${__BASHIO_COLORS_BG_BLACK}"
}

# ------------------------------------------------------------------------------
# Set font output color background to red.
# ------------------------------------------------------------------------------
function bashio::color.bg.red() {
    echo -n -e "${__BASHIO_COLORS_BG_RED}"
}

# ------------------------------------------------------------------------------
# Set font output color background to green.
# ------------------------------------------------------------------------------
function bashio::color.bg.green() {
    echo -n -e "${__BASHIO_COLORS_BG_GREEN}"
}

# ------------------------------------------------------------------------------
# Set font output color background to yellow.
# ------------------------------------------------------------------------------
function bashio::color.bg.yellow() {
    echo -n -e "${__BASHIO_COLORS_BG_YELLOW}"
}

# ------------------------------------------------------------------------------
# Set font output color background to blue.
# ------------------------------------------------------------------------------
function bashio::color.bg.blue() {
    echo -n -e "${__BASHIO_COLORS_BG_BLUE}"
}

# ------------------------------------------------------------------------------
# Set font output color background to magenta.
# ------------------------------------------------------------------------------
function bashio::color.bg.magenta() {
    echo -n -e "${__BASHIO_COLORS_BG_MAGENTA}"
}

# ------------------------------------------------------------------------------
# Set font output color background to cyan.
# ------------------------------------------------------------------------------
function bashio::color.bg.cyan() {
    echo -n -e "${__BASHIO_COLORS_BG_CYAN}"
}

# ------------------------------------------------------------------------------
# Set font output color background to white.
# ------------------------------------------------------------------------------
function bashio::color.bg.white() {
    echo -n -e "${__BASHIO_COLORS_BG_WHITE}"
}
