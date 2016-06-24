# Nerves.Firmware

An API and HTTP/REST microservice to manage firmware on a nerves device.

Starts a small, cowboy-based microservice that returns status about the
current firmware, and accepts updates to the firmware via a REST-style interface.   Nerves.Firmware manages firmware for a single block device, which is configured at compile time.

Leans heavily on Frank Hunleth's excellent [fwup](https://github.com/fhunleth/fwup), which is included of the standard
Nerves configurations.

## Installation/Usage

Until we publish in hex or move officially to nerves_project:

  1. Add nerves_firmware to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_firmware, github: "ghitchens/nerves_firmware"}]
        end

  2. Ensure nerves_firmware is started before your application:

        def application do
          [applications: [:nerves_firmware]]
        end

That's all.  Your firmware is now queriable and updatable!
See the Nerves.Firmware module for API documentation.

## Configuration

You can configure the device that Nerves.Firmware manages in your config.exs:

      config :nerves_firmware, device: "/dev/mmcblk0"
