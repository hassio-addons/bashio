# Security Policy

We take the security of this project seriously. We appreciate your efforts to
responsibly disclose your findings and will make every effort to acknowledge
your contributions.

## Supported Versions

Bashio is distributed as part of the Home Assistant base images. Only the
latest released version receives security fixes. Always make sure you are
running the most recent release before reporting an issue.

| Version        | Supported          |
| -------------- | ------------------ |
| Latest release | :white_check_mark: |
| Older releases | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues,
discussions, or pull requests.**

Instead, report them via GitHub's private vulnerability reporting:

1. Open the [**Report a vulnerability**][advisory-new] form
   (Security tab → "Report a vulnerability").
2. Provide a clear description of the vulnerability, including the affected
   module(s) in [`lib/`](../lib) and the version of Bashio.
3. Include step-by-step instructions to reproduce the issue and, if possible, a
   proof of concept.

If you are unable to use GitHub's reporting form, you may instead email
[opensource@frenck.dev][email].

## Disclosure Policy

- We will acknowledge receipt of your report within **48 hours**.
- We will keep you informed of the progress towards a fix and may ask for
  additional information or guidance.
- We aim to release a fix and publicly disclose the vulnerability within
  **90 days** of the initial report.
- We will credit you for the discovery in the published advisory, unless you
  prefer to remain anonymous.

## Out of Scope

The following are generally **not** considered vulnerabilities in Bashio
itself:

- Issues in versions other than the latest release.
- Vulnerabilities in third-party dependencies of the base images
  (e.g. `bash`, `curl`, `jq`); these are tracked and updated upstream.
- Misuse of Bashio in a way that exposes secrets through a consuming app's
  own configuration or logging.
- Findings that require an already-compromised Supervisor or host environment.

Thank you for helping keep Bashio and the Home Assistant community secure!

[advisory-new]: https://github.com/hassio-addons/bashio/security/advisories/new
[email]: mailto:opensource@frenck.dev
