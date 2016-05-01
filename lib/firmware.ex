defmodule Nerves.Firmware do
  @moduledoc """
  Manages firmware for Nerves, including upgrading and getting status.

  The model that Nerves.Firmware takes is that it manages firmware for
  a single block device, which is set in elixir configuration at compile
  time.

  ## Configuration

  :fw_tmp_path
  :http_port
  :http_path

  ## Firmware State

  status:  (one of the following)

  `:active` - Currently running the latest firmware received.  Firmware
  must be in this state to be updated.

  `:await_restart` - Firmware has been updated since restart, and a restart is
  needed to start running from the new firmware.

  device:  The device holding the firmware.
  """

  use Application
  require Logger

  @server Nerves.Firmware.Server

  @doc """
  Application Start

  Starts the Firmware GenServer (Firmware.Server) and HTTP Server (Firmware.HTTP)
  """
  @spec start(atom, term) :: {:ok, pid} | {:error, String.t}
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Logger.debug "#{__MODULE__}.start(...)"
    Nerves.Firmware.HTTP.start
    opts = [strategy: :one_for_one, name: Nerves.Firmware.Supervisor]
    children = [ worker(Nerves.Firmware.Server, []) ]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Return a map of information about the current firmware.

  This currently contains values showing the state of the firmware installation,
  as well as the key/value pairs encoded in the firmware itself.
  """
  def state(), do: GenServer.call @server, {:state}

  @doc """
  Returns `true` if new firmware can currently be installed.

  The firmware module usually allows new firmware to be installed, but there
  are situations where installing new firmware is dangerous.

  Currently, if the device has had an update applied without being restarted,
  we return false to prevent bricking.
  """
  def allow_upgrade?(), do: GenServer.call @server, {:allow_upgrade?}

  @spec apply(String.t, atom) :: :ok | {:error, term}
  def apply(firmware, action) do
    GenServer.call @server, {:apply, firmware, action}
  end

end
