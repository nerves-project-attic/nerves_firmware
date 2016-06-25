# Nerves.Firmware

Elixir API for upgrading and managing firmware on a Nerves device.

**Looking for over-the-network firmware updates? see
[nerves_firmware_http](https://github.com/nerves-project/nerves_firmware_http),
which provides an HTTP micro-service providing over-network firmware management.

Leans heavily on Frank Hunleth's excellent
[fwup](https://github.com/fhunleth/fwup), which is included of the standard
Nerves configurations.

## Installation/Usage

Not yet published in hex, so...

  1. Add nerves_firmware to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_firmware, github: "nerves-project/nerves_firmware"}]
        end

  2. Ensure nerves_firmware is started before your application:

        def application do
          [applications: [:nerves_firmware]]
        end

See the Nerves.Firmware module for API and configuration documentation.