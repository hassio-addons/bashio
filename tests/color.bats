#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/color.sh.
#
# The color functions write escape sequences directly to stdout (no LOG_FD
# indirection), so bats' `run` captures them without any extra setup.
# Each function emits exactly the ANSI escape sequence stored in the matching
# __BASHIO_COLORS_* constant and nothing else (no newline - echo -n).
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

# ---------------------------------------------------------------------------
# Foreground color helpers
# ---------------------------------------------------------------------------

@test "color.reset emits the reset escape sequence" {
    run bashio::color.reset
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_RESET}")" ]
}

@test "color.default emits the default foreground escape sequence" {
    run bashio::color.default
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_DEFAULT}")" ]
}

@test "color.black emits the black foreground escape sequence" {
    run bashio::color.black
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BLACK}")" ]
}

@test "color.red emits the red foreground escape sequence" {
    run bashio::color.red
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_RED}")" ]
}

@test "color.green emits the green foreground escape sequence" {
    run bashio::color.green
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_GREEN}")" ]
}

@test "color.yellow emits the yellow foreground escape sequence" {
    run bashio::color.yellow
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_YELLOW}")" ]
}

@test "color.blue emits the blue foreground escape sequence" {
    run bashio::color.blue
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BLUE}")" ]
}

@test "color.magenta emits the magenta foreground escape sequence" {
    run bashio::color.magenta
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_MAGENTA}")" ]
}

@test "color.cyan emits the cyan foreground escape sequence" {
    run bashio::color.cyan
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_CYAN}")" ]
}

# ---------------------------------------------------------------------------
# Background color helpers
# ---------------------------------------------------------------------------

@test "color.bg.default emits the default background escape sequence" {
    run bashio::color.bg.default
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_DEFAULT}")" ]
}

@test "color.bg.black emits the black background escape sequence" {
    run bashio::color.bg.black
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_BLACK}")" ]
}

@test "color.bg.red emits the red background escape sequence" {
    run bashio::color.bg.red
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_RED}")" ]
}

@test "color.bg.green emits the green background escape sequence" {
    run bashio::color.bg.green
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_GREEN}")" ]
}

@test "color.bg.yellow emits the yellow background escape sequence" {
    run bashio::color.bg.yellow
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_YELLOW}")" ]
}

@test "color.bg.blue emits the blue background escape sequence" {
    run bashio::color.bg.blue
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_BLUE}")" ]
}

@test "color.bg.magenta emits the magenta background escape sequence" {
    run bashio::color.bg.magenta
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_MAGENTA}")" ]
}

@test "color.bg.cyan emits the cyan background escape sequence" {
    run bashio::color.bg.cyan
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_CYAN}")" ]
}

@test "color.bg.white emits the white background escape sequence" {
    run bashio::color.bg.white
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf '%b' "${__BASHIO_COLORS_BG_WHITE}")" ]
}

# ---------------------------------------------------------------------------
# Sanity: each escape sequence begins with the ESC character (\033[)
# ---------------------------------------------------------------------------

@test "every foreground escape sequence starts with the ANSI CSI prefix" {
    local csi
    csi="$(printf '%b' "${__BASHIO_COLORS_ESCAPE}")"
    for fn in reset default black red green yellow blue magenta cyan; do
        run "bashio::color.${fn}"
        [ "${status}" -eq 0 ]
        [[ "${output}" == "${csi}"* ]]
    done
}

@test "every background escape sequence starts with the ANSI CSI prefix" {
    local csi
    csi="$(printf '%b' "${__BASHIO_COLORS_ESCAPE}")"
    for fn in default black red green yellow blue magenta cyan white; do
        run "bashio::color.bg.${fn}"
        [ "${status}" -eq 0 ]
        [[ "${output}" == "${csi}"* ]]
    done
}

# ---------------------------------------------------------------------------
# Sanity: the color functions emit no trailing newline (echo -n)
# ---------------------------------------------------------------------------

@test "color.reset produces no trailing newline" {
    # printf %b preserves the raw bytes; wc -c counts them.
    # echo -n means the output length must equal the escape-sequence length.
    local expected actual
    expected="$(printf '%b' "${__BASHIO_COLORS_RESET}" | wc -c)"
    actual="$(bashio::color.reset | wc -c)"
    [ "${actual}" -eq "${expected}" ]
}

@test "color.red produces no trailing newline" {
    local expected actual
    expected="$(printf '%b' "${__BASHIO_COLORS_RED}" | wc -c)"
    actual="$(bashio::color.red | wc -c)"
    [ "${actual}" -eq "${expected}" ]
}

# ---------------------------------------------------------------------------
# Sanity: foreground and background codes are distinct from each other
# and from the reset code
# ---------------------------------------------------------------------------

@test "foreground and background red codes are different" {
    local fg bg
    fg="$(printf '%b' "${__BASHIO_COLORS_RED}")"
    bg="$(printf '%b' "${__BASHIO_COLORS_BG_RED}")"
    [ "${fg}" != "${bg}" ]
}

@test "reset code is distinct from all color codes" {
    local reset red green
    reset="$(printf '%b' "${__BASHIO_COLORS_RESET}")"
    red="$(printf '%b' "${__BASHIO_COLORS_RED}")"
    green="$(printf '%b' "${__BASHIO_COLORS_GREEN}")"
    [ "${reset}" != "${red}" ]
    [ "${reset}" != "${green}" ]
}
