#!/usr/bin/env bats
# ==============================================================================
# Tests for lib/config.sh.
#
# `bashio::config` reads the add-on options through `bashio::addon.config`
# (which normally calls the Supervisor API). That boundary is stubbed here with
# a fixed options document, so the real jq-based parsing logic is exercised.
#
# Functions that consult the Have I Been Pwned database do so through
# `bashio::pwned.is_safe_password`; that is the boundary stubbed for the
# password-safety helpers. SSL certificate presence is checked through
# `bashio::fs.file_exists`, which is the boundary stubbed for the SSL helper.
# ==============================================================================

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
    __BASHIO_CACHE_DIR="${BATS_TEST_TMPDIR}/cache"

    # The library's loggers write to a saved copy of the original STDOUT
    # (LOG_FD), captured when bashio was sourced, so their output bypasses
    # the redirection that bats' `run` installs. Capture the fatal and warning
    # messages to a file so tests can assert on the guidance text regardless of
    # where LOG_FD points.
    bashio::log.fatal() { printf '%s\n' "$*" >>"${BATS_TEST_TMPDIR}/log"; }
    bashio::log.warning() { printf '%s\n' "$*" >>"${BATS_TEST_TMPDIR}/log"; }

    bashio::addon.config() {
        printf '%s' '{
            "username": "frenck",
            "port": 1234,
            "ssl": true,
            "debug": false,
            "blank": "",
            "tags": ["one", "two", "three"],
            "empty_list": [],
            "settings": {"nested": "value"},
            "empty_object": {}
        }'
    }
}

# ------------------------------------------------------------------------------
# bashio::config (typed accessors)
# ------------------------------------------------------------------------------

@test "config returns a string value" {
    run bashio::config "username"
    [ "${status}" -eq 0 ]
    [ "${output}" = "frenck" ]
}

@test "config returns a numeric value" {
    run bashio::config "port"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1234" ]
}

@test "config returns a boolean true value" {
    run bashio::config "ssl"
    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "config returns a boolean false value" {
    run bashio::config "debug"
    [ "${status}" -eq 0 ]
    [ "${output}" = "false" ]
}

@test "config returns an empty string for a blank string value" {
    run bashio::config "blank"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "config returns each element of an array on its own line" {
    run bashio::config "tags"
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "one" ]
    [ "${lines[1]}" = "two" ]
    [ "${lines[2]}" = "three" ]
}

@test "config returns empty output for an empty array" {
    run bashio::config "empty_list"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "config returns the object as JSON for an object value" {
    run bashio::config "settings"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"nested":"value"}' ]
}

@test "config returns empty output for an empty object" {
    run bashio::config "empty_object"
    [ "${status}" -eq 0 ]
    [ "${output}" = "" ]
}

@test "config returns the default for a missing key" {
    run bashio::config "missing" "fallback"
    [ "${status}" -eq 0 ]
    [ "${output}" = "fallback" ]
}

@test "config returns the literal 'null' default for a missing key without a default" {
    run bashio::config "missing"
    [ "${status}" -eq 0 ]
    [ "${output}" = "null" ]
}

@test "config does not leak its options variable into the caller's scope" {
    # A caller may legitimately use a variable named 'options'; bashio::config
    # must not clobber it.
    options="caller-value"
    bashio::config "username" >/dev/null
    [ "${options}" = "caller-value" ]
}

# ------------------------------------------------------------------------------
# bashio::config.exists
# ------------------------------------------------------------------------------

@test "config.exists succeeds for a present key" {
    run bashio::config.exists "username"
    [ "${status}" -eq 0 ]
}

@test "config.exists succeeds for a present key holding an empty string" {
    run bashio::config.exists "blank"
    [ "${status}" -eq 0 ]
}

@test "config.exists fails for a missing key" {
    run bashio::config.exists "missing"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.has_value
# ------------------------------------------------------------------------------

@test "config.has_value succeeds for a present non-empty value" {
    run bashio::config.has_value "username"
    [ "${status}" -eq 0 ]
}

@test "config.has_value fails for an empty value" {
    run bashio::config.has_value "blank"
    [ "${status}" -ne 0 ]
}

@test "config.has_value fails for a missing key" {
    run bashio::config.has_value "missing"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.is_empty
# ------------------------------------------------------------------------------

@test "config.is_empty succeeds for an empty value" {
    run bashio::config.is_empty "blank"
    [ "${status}" -eq 0 ]
}

@test "config.is_empty succeeds for a missing key" {
    run bashio::config.is_empty "missing"
    [ "${status}" -eq 0 ]
}

@test "config.is_empty fails for a present non-empty value" {
    run bashio::config.is_empty "username"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.equals
# ------------------------------------------------------------------------------

@test "config.equals matches a numeric value" {
    run bashio::config.equals "port" "1234"
    [ "${status}" -eq 0 ]
}

@test "config.equals matches a string value" {
    run bashio::config.equals "username" "frenck"
    [ "${status}" -eq 0 ]
}

@test "config.equals fails when the value differs" {
    run bashio::config.equals "username" "someone-else"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.true / bashio::config.false
# ------------------------------------------------------------------------------

@test "config.true succeeds for a true option" {
    run bashio::config.true "ssl"
    [ "${status}" -eq 0 ]
}

@test "config.true fails for a false option" {
    run bashio::config.true "debug"
    [ "${status}" -ne 0 ]
}

@test "config.true fails for a missing key" {
    run bashio::config.true "missing"
    [ "${status}" -ne 0 ]
}

@test "config.false succeeds for a false option" {
    run bashio::config.false "debug"
    [ "${status}" -eq 0 ]
}

@test "config.false fails for a true option" {
    run bashio::config.false "ssl"
    [ "${status}" -ne 0 ]
}

@test "config.false fails for a missing key" {
    run bashio::config.false "missing"
    [ "${status}" -ne 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.is_safe_password
# ------------------------------------------------------------------------------

@test "config.is_safe_password succeeds when the password is safe" {
    bashio::pwned.is_safe_password() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/pwned"
        return 0
    }
    run bashio::config.is_safe_password "username"
    [ "${status}" -eq 0 ]
    # The configured value must be the one that gets checked.
    [ "$(cat "${BATS_TEST_TMPDIR}/pwned")" = "frenck" ]
}

@test "config.is_safe_password fails for an unsafe password when bypass is off" {
    bashio::pwned.is_safe_password() { return 1; }
    # 'i_like_to_be_pwned' is not in the options document, so the bypass is off.
    run bashio::config.is_safe_password "username"
    [ "${status}" -ne 0 ]
}

@test "config.is_safe_password succeeds for an unsafe password when bypass is enabled" {
    bashio::addon.config() {
        printf '%s' '{"password":"secret","i_like_to_be_pwned":true}'
    }
    bashio::pwned.is_safe_password() { return 1; }
    run bashio::config.is_safe_password "password"
    [ "${status}" -eq 0 ]
}

# ------------------------------------------------------------------------------
# bashio::config.require
# ------------------------------------------------------------------------------

@test "config.require succeeds when the option has a value" {
    run bashio::config.require "username"
    [ "${status}" -eq 0 ]
}

@test "config.require fails when the option is missing" {
    run bashio::config.require "missing"
    [ "${status}" -ne 0 ]
}

@test "config.require fails when the option is empty" {
    run bashio::config.require "blank"
    [ "${status}" -ne 0 ]
}

@test "config.require includes the reason in its fatal output" {
    run bashio::config.require "missing" "the daemon needs it"
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"the daemon needs it"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.suggest
# ------------------------------------------------------------------------------

@test "config.suggest stays silent when the option has a value" {
    run bashio::config.suggest "username"
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest warns when the option is missing" {
    run bashio::config.suggest "missing"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"missing"* ]]
}

@test "config.suggest includes the reason when the option is missing" {
    run bashio::config.suggest "missing" "improves performance"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"improves performance"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.suggest.true / bashio::config.suggest.false
# ------------------------------------------------------------------------------

@test "config.suggest.true stays silent when the option is enabled" {
    run bashio::config.suggest.true "ssl"
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest.true warns when the option is not enabled" {
    run bashio::config.suggest.true "debug"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"debug"* ]]
}

@test "config.suggest.true includes the reason when not enabled" {
    run bashio::config.suggest.true "debug" "needed for logs"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"needed for logs"* ]]
}

@test "config.suggest.false stays silent when the option is disabled" {
    run bashio::config.suggest.false "debug"
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest.false warns when the option is not disabled" {
    run bashio::config.suggest.false "ssl"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"ssl"* ]]
}

@test "config.suggest.false includes the reason when not disabled" {
    run bashio::config.suggest.false "ssl" "saves resources"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"saves resources"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.require.username / bashio::config.suggest.username
# ------------------------------------------------------------------------------

@test "config.require.username succeeds with the default key when set" {
    run bashio::config.require.username
    [ "${status}" -eq 0 ]
}

@test "config.require.username fails with the default key when not set" {
    bashio::addon.config() { printf '%s' '{}'; }
    run bashio::config.require.username
    [ "${status}" -ne 0 ]
}

@test "config.require.username fails for a custom key that is not set" {
    run bashio::config.require.username "missing"
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"missing"* ]]
}

@test "config.suggest.username stays silent when a username is set" {
    run bashio::config.suggest.username
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest.username warns when no username is set" {
    bashio::addon.config() { printf '%s' '{}'; }
    run bashio::config.suggest.username
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"username"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.require.password / bashio::config.suggest.password
# ------------------------------------------------------------------------------

@test "config.require.password succeeds when a password is set" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    run bashio::config.require.password
    [ "${status}" -eq 0 ]
}

@test "config.require.password fails when no password is set" {
    bashio::addon.config() { printf '%s' '{}'; }
    run bashio::config.require.password
    [ "${status}" -ne 0 ]
}

@test "config.require.password reports the custom key when not set" {
    bashio::addon.config() { printf '%s' '{}'; }
    run bashio::config.require.password "secret_key"
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"secret_key"* ]]
}

@test "config.suggest.password stays silent when a password is set" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    run bashio::config.suggest.password
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest.password warns when no password is set" {
    bashio::addon.config() { printf '%s' '{}'; }
    run bashio::config.suggest.password
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"password"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.require.safe_password
# ------------------------------------------------------------------------------

@test "config.require.safe_password succeeds for a set and safe password" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    bashio::pwned.is_safe_password() {
        printf '%s' "$*" >"${BATS_TEST_TMPDIR}/pwned"
        return 0
    }
    run bashio::config.require.safe_password
    [ "${status}" -eq 0 ]
    [ "$(cat "${BATS_TEST_TMPDIR}/pwned")" = "secret" ]
}

@test "config.require.safe_password fails when no password is set" {
    bashio::addon.config() { printf '%s' '{}'; }
    # The pwned check must never run when the password is missing; record a
    # marker file (which survives the subshell) if it ever does.
    bashio::pwned.is_safe_password() {
        : >"${BATS_TEST_TMPDIR}/pwned-called"
        return 0
    }
    run bashio::config.require.safe_password
    [ "${status}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/pwned-called" ]
}

@test "config.require.safe_password fails for a set but unsafe password" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    bashio::pwned.is_safe_password() { return 1; }
    run bashio::config.require.safe_password
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"HaveIBeenPwned"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.suggest.safe_password
# ------------------------------------------------------------------------------

@test "config.suggest.safe_password stays silent for a set and safe password" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    bashio::pwned.is_safe_password() { return 0; }
    run bashio::config.suggest.safe_password
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/log" ]
}

@test "config.suggest.safe_password suggests setting a password when none is set" {
    bashio::addon.config() { printf '%s' '{}'; }
    # When no password is set, it falls through to suggest.password (which
    # warns) and must not consult the pwned database.
    bashio::pwned.is_safe_password() {
        : >"${BATS_TEST_TMPDIR}/pwned-called"
        return 0
    }
    run bashio::config.suggest.safe_password
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/pwned-called" ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"password"* ]]
}

@test "config.suggest.safe_password warns for a set but unsafe password" {
    bashio::addon.config() { printf '%s' '{"password":"secret"}'; }
    bashio::pwned.is_safe_password() { return 1; }
    run bashio::config.suggest.safe_password
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"HaveIBeenPwned"* ]]
}

# ------------------------------------------------------------------------------
# bashio::config.require.ssl
# ------------------------------------------------------------------------------

@test "config.require.ssl succeeds without checks when SSL is disabled" {
    bashio::addon.config() { printf '%s' '{"ssl":false}'; }
    # No certificate files should be probed when SSL is off. Use a marker file
    # because the stub runs in run's subshell, where a shell variable would not
    # propagate back to this test.
    bashio::fs.file_exists() {
        : >"${BATS_TEST_TMPDIR}/fs-probed"
        return 0
    }
    run bashio::config.require.ssl
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/fs-probed" ]
}

@test "config.require.ssl succeeds when SSL is enabled and both files exist" {
    bashio::addon.config() {
        printf '%s' '{"ssl":true,"certfile":"cert.pem","keyfile":"key.pem"}'
    }
    bashio::fs.file_exists() { return 0; }
    run bashio::config.require.ssl
    [ "${status}" -eq 0 ]
}

@test "config.require.ssl fails when the certificate option is empty" {
    bashio::addon.config() {
        printf '%s' '{"ssl":true,"certfile":"","keyfile":"key.pem"}'
    }
    bashio::fs.file_exists() { return 0; }
    run bashio::config.require.ssl
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"certfile"* ]]
}

@test "config.require.ssl fails when the key file option is empty" {
    bashio::addon.config() {
        printf '%s' '{"ssl":true,"certfile":"cert.pem","keyfile":""}'
    }
    bashio::fs.file_exists() { return 0; }
    run bashio::config.require.ssl
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"keyfile"* ]]
}

@test "config.require.ssl fails when the certificate file is missing on disk" {
    bashio::addon.config() {
        printf '%s' '{"ssl":true,"certfile":"cert.pem","keyfile":"key.pem"}'
    }
    # Only the key file exists; the certificate file does not.
    bashio::fs.file_exists() {
        [ "${1}" = "/ssl/key.pem" ]
    }
    run bashio::config.require.ssl
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"does not exist"* ]]
    [[ "${output}" == *"certfile"* ]]
}

@test "config.require.ssl fails when the key file is missing on disk" {
    bashio::addon.config() {
        printf '%s' '{"ssl":true,"certfile":"cert.pem","keyfile":"key.pem"}'
    }
    # Only the certificate file exists; the key file does not.
    bashio::fs.file_exists() {
        [ "${1}" = "/ssl/cert.pem" ]
    }
    run bashio::config.require.ssl
    [ "${status}" -ne 0 ]
    run cat "${BATS_TEST_TMPDIR}/log"
    [[ "${output}" == *"does not exist"* ]]
    [[ "${output}" == *"keyfile"* ]]
}

@test "config.require.ssl honours custom option keys" {
    bashio::addon.config() {
        printf '%s' '{"tls":true,"crt":"my.crt","ky":"my.key"}'
    }
    bashio::fs.file_exists() {
        printf '%s\n' "${1}" >>"${BATS_TEST_TMPDIR}/probed"
        return 0
    }
    run bashio::config.require.ssl "tls" "crt" "ky"
    [ "${status}" -eq 0 ]
    run cat "${BATS_TEST_TMPDIR}/probed"
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "/ssl/my.crt" ]
    [ "${lines[1]}" = "/ssl/my.key" ]
}
