# Community Hass.io Add-ons: Bashio

[![GitHub Release][releases-shield]][releases]
![Project Stage][project-stage-shield]
[![License][license-shield]](LICENSE.md)

[![GitLab CI][gitlabci-shield]][gitlabci]
![Project Maintenance][maintenance-shield]
[![GitHub Activity][commits-shield]][commits]

[![Discord][discord-shield]][discord]

[![Buy me a coffee][buymeacoffee-shield]][buymeacoffee]

[![Support my work on Patreon][patreon-shield]][patreon]

## About

Bashio is an bash function library for use with Hass.io add-ons.

It contains a set of commonly used operations and can be used
to be included in add-ons to reduce code duplication across add-ons and
therefore making it easier to develop and maintain add-ons.

Main goals:

- Reduce the number of operations needed in add-ons.
- Reduce the amount of code needed in add-ons.
- Make add-on code more readable.
- Providing an trusted and tested code base.

Quicker add-on development, by allowing you to focus on the add-on logic
instead of other things.

## Installation

The library is installed in the Community Hass.io Add-ons base images and
the official Hassio base images by Home Assistant.

Currently available base images:

- [Community Hassio Add-ons Alpine Base Image][base-alpine]
- [Community Hassio Add-ons Alpine Python Base Image][base-alpine-python]
- [Community Hassio Add-ons Ubuntu Base Image][base-ubuntu]
- [Official Hassio Alpine Base Image][hassio-base]
- [Official Hassio Alpine Python Base Image][hassio-base]
- [Official Hassio Ubuntu Base Image][hassio-base]
- [Official Hassio Raspbian Base Image][hassio-base]

Using those images as the base for your Hass.io add-on, will provide this
function library out of the box. Our base images are updated frequently and
provides the minimal needed base image for a great add-on.

If you want to add Bashio to your own images, please take a look at the
Dockerfile of the above base images to see how they are added at build time.

## Configuration

Configuring an Bash script to use the Bashio library is fairly easy. Simply
replace the shebang of your script file, from `bash` to `bashio`.

Before example:

```bash
#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json

USERNAME=$(jq --raw-output '.username // empty' $CONFIG_PATH)

echo "${USERNAME}"
```

After example with Bashio:

```bash
#!/usr/bin/env bashio

USERNAME=$(bashio::config 'username')

bashio::log.info "${USERNAME}"
```

## Functions

Bashio has more then 250+ functions available: communicating with
the Hass.io API, Have I Been Pwned, file system, logging, configuration handling
and a lot more!

The best way to get around, would be by looking at the different modules
available in the [`lib`](lib) folder. Each module has its own file, and each
function has been documented inside the code base.

Further more, Bashio is used by the
[Community Hass.io Add-ons project][repository], those add-ons will be a great
resource of practical examples.

## Known issues and limitations

- Some parts of the Hass.io API are not implemented yet.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality. The format of the log is based on
[Keep a Changelog][keepchangelog].

Releases are based on [Semantic Versioning][semver], and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several options to get them answered:

- The [Community Hass.io Add-ons Discord chat server][discord] for add-on
  support and feature requests.
- You could also [open an issue here][issue] GitHub.

## Contributing

This is an active open-source project. We are always open to people who want to
use the code or contribute to it.

We have set up a separate document containing our
[contribution guidelines](CONTRIBUTING.md).

Thank you for being involved! :heart_eyes:

## Authors & contributors

The original setup of this repository is by [Franck Nijhof][frenck].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

MIT License

Copyright (c) 2019-2020 Franck Nijhof

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[base-alpine-python]: https://github.com/hassio-addons/addon-base-python
[base-alpine]: https://github.com/hassio-addons/addon-base
[base-ubuntu]: https://github.com/hassio-addons/addon-ubuntu-base
[buymeacoffee-shield]: https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg
[buymeacoffee]: https://www.buymeacoffee.com/frenck
[commits-shield]: https://img.shields.io/github/commit-activity/y/hassio-addons/bashio.svg
[commits]: https://github.com/hassio-addons/bashio/commits/master
[contributors]: https://github.com/hassio-addons/bashio/graphs/contributors
[discord-shield]: https://img.shields.io/discord/478094546522079232.svg
[discord]: https://discord.me/hassioaddons
[frenck]: https://github.com/frenck
[gitlabci-shield]: https://gitlab.com/hassio-addons/bashio/badges/master/pipeline.svg
[gitlabci]: https://gitlab.com/hassio-addons/bashio/pipelines
[hassio-base]: https://github.com/home-assistant/hassio-base
[issue]: https://github.com/hassio-addons/bashio/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[license-shield]: https://img.shields.io/github/license/hassio-addons/bashio.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2020.svg
[patreon]: https://www.patreon.com/frenck
[project-stage-shield]: https://img.shields.io/badge/project%20stage-experimental-yellow.svg
[releases-shield]: https://img.shields.io/github/release/hassio-addons/bashio.svg
[releases]: https://github.com/hassio-addons/bashio/releases
[repository]: https://github.com/hassio-addons/repository
[semver]: http://semver.org/spec/v2.0.0.htm
