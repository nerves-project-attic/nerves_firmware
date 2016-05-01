# Nerves.Firmware

An API and HTTP/REST microservice to manage firmware on a nerves device.

Starts a small, cowboy-based microservice that returns status about the
current firmware, and accepts updates to the firmware.

The model that Nerves.Firmware takes is that it manages firmware for
a single block device, which is set in elixir configuration at compile
time.

Depends, and delegates a lot, to Frank Hunleth's excellent
[fwup](https://github.com/fhunleth/fwup), which is included of the standard
Nerves configurations.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add nerves_firmware to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_firmware, "~> 0.0.1"}]
        end

  2. Ensure nerves_firmware is started before your application:

        def application do
          [applications: [:nerves_firmware]]
        end

## Configuration

In your app's config.exs, you can change a number of the default settings
for Nerves.Firmware:

| key          | default              | comments                            |
|--------------|----------------------|-------------------------------------|
| :device      | platform-dependent   | "/dev/mmcblk0" for ARM              |
| :http_port   | 8988                 |                                     |
| :http_path   | "/firmware"          |                                     |
| :upload_path | "/tmp/uploaded.fw"   | Firmware will be uploaded here before install, and deleted afterward |

## REST API

See Nerves.Firmware.HTTP

## Firmware State

Both the Nerves.Firmware.state() function and the GET HTTP/REST API return
the state of the firmware.  The keys/values

__status:__

`:active` - Currently running the latest firmware received.  Firmware
must be in this state to be updated.

`:await_restart` - Firmware has been updated since restart, and a restart is
needed to start running from the new firmware.

__device:__

The device file that holds the firmware, e.g. /dev/mmcblk0

## TODO

- [ ] understand :permanent app start supervision
- [ ] build in auto-restart option