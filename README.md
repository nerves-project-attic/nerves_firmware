# Nerves.Firmware

Elixir API for upgrading and managing firmware on a Nerves device.

**Looking for over-the-network firmware updates?** see
[nerves_firmware_http](https://github.com/nerves-project/nerves_firmware_http), which provides an HTTP micro-service providing over-network firmware management.

Leans heavily on Frank Hunleth's excellent [fwup](https://github.com/fhunleth/fwup), which is included of the standard Nerves configurations.

For more, read the [documentation](https://hexdocs.pm/nerves_firmware).

## Installation

It's published in [Hex](https://hex.pm/nerves_firmware), so..

  1. Add nerves_firmware to your list of dependencies in `mix.exs`:

          def deps do
            [{:nerves_firmware, "~> 0.3.0"}]
          end

  2. Ensure nerves_firmware is started before your application:

          def application do
            [applications: [:nerves_firmware]]
          end

## Usage
in `config.exs` you can configure the block device and signing of the firmware.

``` elixir
use Mix.Config

config :nerves_firmware,
  device: "/dev/mmcblk0",
  pub_key_path: "/etc/fwup-key.pub"
```
