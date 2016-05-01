defmodule Nerves.Firmware do
  @moduledoc """
  An API and HTTP/REST microservice to manage firmware on a Nerves device.

  The model that Nerves.Firmware takes is that it manages firmware for
  a single block device, which is set in elixir configuration at compile
  time.

  Starts a small, cowboy-based microservice that returns status about the
  current firmware, and accepts updates to the firmware.

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

  """

  use Application
  require Logger

  @server Nerves.Firmware.Server

  @doc """
  Application start callback.

  Note that for HTTP functionality, Nerves.Firmware.HTTP.start must
  be invoked separately.
  """
  @spec start(atom, term) :: {:ok, pid} | {:error, String.t}
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.debug "#{__MODULE__}.start(...)"
    opts = [strategy: :one_for_one, name: Nerves.Firmware.Supervisor]
    children = [ worker(Nerves.Firmware.Server, []) ]
    supervisor = Supervisor.start_link(children, opts)
    Nerves.Firmware.HTTP.start
    supervisor
  end

  @doc """
  Return a map of information about the current firmware.

  This currently contains values showing the state of the firmware installation,
  as well as the key/value pairs encoded in the firmware itself.
  """
  def state(), do: GenServer.call @server, {:state}

  @doc """
  Applies a firmware file to the device media.

  This mostly just passes information through to Nerves.Firmware.Fwup.apply(..)
  which is a very thin wrapper around [fwup](https://github.com/fhunleth/fwup), but it
  also sets the firwmare state based on the action to reflect the update, and
  prevent multiple updates from overwriting known good firmware.
  """
  @spec apply(String.t, atom) :: :ok | {:error, term}
  def apply(firmware, action) do
    GenServer.call @server, {:apply, firmware, action}
  end

  @doc """
  Returns `true` if new firmware can currently be installed.

  The firmware module usually allows new firmware to be installed, but there
  are situations where installing new firmware is dangerous.

  Currently, if the device has had an update applied without being restarted,
  we return false to prevent bricking.
  """
  @spec allow_upgrade?() :: true | false
  def allow_upgrade?() do
    GenServer.call @server, {:allow_upgrade?}
  end

  @doc """
  Forces reboot of the device.
  """
  @spec reboot() :: :ok
  def reboot() do
    Logger.info "#{__MODULE__} : rebooting device"
    System.cmd("reboot", [])
    :ok
  end

end
