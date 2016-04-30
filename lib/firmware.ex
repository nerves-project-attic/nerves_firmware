defmodule Nerves.Firmware do
  @moduledoc """
  Manages firmware for Nerves, including upgrading and getting status.

  The model that Nerves.Firmware takes is that it manages firmware for
  a single block device, which is set in elixir configuration at compile
  time.

  ## Firmware States

  `:active` - Currently running the latest firmware received.  Firmware
  must be in this state to be updated.

  `:await_restart` - Firmware has been updated since restart, and a restart is
  needed to start running from the new firmware.
  """

  use Application

  @server Nerves.Firmware.Server

  @doc """
  Application start callback (just starts Nerves.Firmware.Server)
  """
  @spec start(atom, term) :: {:ok, pid} | {:error, String.t}
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    opts = [strategy: :one_for_one, name: Nerves.Firmware.Supervisor]
    children = [ worker(Nerves.Firmware.Server, []) ]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Return a map of information about the current firmware.

  This is derived from the key/value pairs encoded in the firmware itself.
  """
  def metadata(), do: GenServer.call @server, {:metadata}

  @doc """
  Returns `true` if new firmware can currently be installed.

  The firmware module usually allows new firmware to be installed, but there
  are situations where installing new firmware is dangerous.  Generally, these
  situations are:

  - If the currently running firmware is running in "provisional" (boot-once)
  mode, our next boot will fall back to the previous version of firmware, and
  allowing an install would overwrite the previous version.

  - If the firmware is currently in the process of being updated.
  """
  def allow_upgrade?(), do: GenServer.call @server, {:allow_upgrade?}

  @doc """
  Installs firmware from a stream and prepares it for use.

  Streams firmware to the "update" partition of a Nerves device, validates the
  firmware, updates boot information, and prepares for switching to the newly
  installed firmware.

  Behind the scenes, `install` heavily depends on Frank Hunleth's excellent
  [fwup](https://github.com/fhunleth/fwup), which is included of the standard Nerves
  configurations.

  ## Example using File.stream! (raw mode, readahead, 2K blocks)
  ```
  File.stream!(my_firmware.fw", [], 2048)
  |> Nerves.Firmware.install
  ```

  ## Example using File.open and IO.binstream instead
  ```
  File.open("my_firmware.fw", [:read], fn(io_device) ->
    io_device
    |> IO.binstream(2048)       # stream 2k chunks at a time
    |> Nerves.Firmware.install
  end
  ```

  """

  @spec apply(String.t, atom) :: :ok | {:error, term}
  def apply(firmware, action) do
    GenServer.call @server, {:apply, firmware, action}
  end

end
