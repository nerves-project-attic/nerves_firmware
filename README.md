# Nerves.Firmware

Manages firmware on a Nerves device, including upgrading, certificates, status.
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

## TODO List

- [ ] device working

- [ ] re-integrate status updates
- [ ] understand :permanent app start supervision

### Think List

- ability to understand state of firmware (was via /sys/firmware)
- ability to request update to firmware (via post to ...)
- ability to "normalize" provisional firmware
- ability to "rollback" updated firmware (before further update)
