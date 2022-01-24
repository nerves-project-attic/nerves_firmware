defmodule Nerves.Firmware do
  @moduledoc """
  API for upgrading and managing firmware on a Nerves device.

  Handles firmware for a single block device (like /dev/mmcblk0). Delegates a
  lot to Frank Hunleth's excellent [fwup](https://github.com/fhunleth/fwup).

  Provides:
  - Firmware upgrades
  - Firmware status
  - Firmware-related activities (shutdown, reboot, halt)

  **Looking for over-the-network firmware updates?** see
  [nerves_firmware_http](https://github.com/nerves-project/nerves_firmware_http),
  which provides an HTTP micro-service providing over-network firmware management.

  ## Installation

    1. Add nerves_firmware to your list of dependencies in `mix.exs`:

          def deps do
            [{:nerves_firmware, "~> 0.4.0"}]
          end

    2. Ensure nerves_firmware is started before your application:

          def application do
            [applications: [:nerves_firmware]]
          end

  ## Configuration

  In your app's config.exs, you can configure the block device for your
  target that is managed by setting the device key as follows:

        config :nerves_firmware, device: "dev/mmcblk0"
  """

  use Application
  require Logger

  @type reason :: atom

  @typedoc """
  Arguments to be passed to FWUP.
  """
  @type args :: [binary]

  @server Nerves.Firmware.Server

  @doc """
  Application start callback.
  """
  @spec start(atom, term) :: {:ok, pid} | {:error, String.t}
  def start(_type, _args) do
    Logger.debug "#{__MODULE__}.start(...)"
    opts = [strategy: :one_for_one, name: Nerves.Firmware.Supervisor]
    children = [@server]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Return a map of information about the current firmware.

  This currently contains values showing the state of the firmware installation,
  as well as the key/value pairs encoded in the firmware itself.

  __status:__

  `:active` - Currently running the latest firmware received.  Firmware
  must be in this state to be updated.

  `:await_restart` - Firmware has been updated since restart, and a restart is
  needed to start running from the new firmware.

  __device:__

  The device file that holds the firmware, e.g. /dev/mmcblk0
  """
  @spec state() :: Map.t
  def state(), do: GenServer.call @server, {:state}

  @doc """
  Applies a firmware file to the device media.

  This mostly just passes information through to Nerves.Firmware.Fwup.apply(..)
  which is a very thin wrapper around [fwup](https://github.com/fhunleth/fwup), but it
  also sets the firwmare state based on the action to reflect the update, and
  prevent multiple updates from overwriting known good firmware.

  * `action` can be one of `:upgrade` or `:complete`
  * `args` is a list of extra arguments to be passed to fwup.

  Returns {:error, :await_restart} if the upgrade is requested after
  already updating an image without a reboot in-between.
  """
  @spec apply(String.t, atom, args) :: :ok | {:error, reason}
  def apply(firmware, action, args \\ []) do
    args = maybe_pub_key_args(args)
    GenServer.call @server, {:apply, firmware, action, args}
  end

  @doc """
  Returns `true` if new firmware can currently be installed.

  The firmware module usually allows new firmware to be installed, but there
  are situations where installing new firmware is dangerous.  Currently
  if the device has had an update applied without being restarted,
  this returns false, and update apis will return errors, to prevent bricking.
  """
  @spec allow_upgrade?() :: true | false
  def allow_upgrade?() do
    GenServer.call @server, {:allow_upgrade?}
  end

  @doc """
  Apply a 1 or 2-phase nerves update

  Applies firmware using `upgrade` task, then, if /tmp/finalize.fw exists,
  apply that file with `on-reboot` task.  Supports @fhunleth 2-phase format.

  * `args` is a list of extra arguments to be passed to fwup.

  Returns {:error, :await_restart} if the upgrade is requested after
  already updating an image without a reboot in-between.
  """
  @spec upgrade_and_finalize(String.t, args) :: :ok | {:error, reason}
  def upgrade_and_finalize(firmware, args \\ []) do
    args = maybe_pub_key_args(args)
    GenServer.call @server, {:upgrade_and_finalize, firmware, args}, :infinity
  end

  @doc """
  Applies /tmp/finalize.fw if with `on-reboot` task if exists,

  * `args` is a list of extra arguments to be passed to fwup, but is currently
  ignored for this function.

  Returns {:error, :await_restart} if the finalize is requested after
  already updating an image without a reboot in-between.
  """
  @spec finalize(args) :: :ok | {:error, reason}
  def finalize(args \\ []) do
    args = maybe_pub_key_args(args)
    # REVIEW args is ignored by the server for this call. What should they do?
    GenServer.call @server, {:finalize, args}, :infinity
  end

  @doc """
  Reboot the device.

  Issues the os-level `reboot` command, which reboots the device, even
  if erlinit.conf specifies not to reboot on exit of the Erlang VM.
  """
  @spec reboot() :: :ok
  def reboot(), do: logged_shutdown "reboot"

  @doc """
  Reboot the device gracefully

  Issues :init.stop command to gracefully shutdown all applications in the Erlang VM.
  All code is unloaded and ports closed before the system terminates by calling halt(Status).
  erlinit.config must be set to reboot on exit(default) for a graceful reboot to work.
  """
  @spec reboot(atom) :: :ok
  def reboot(:graceful), do: :init.stop

  @doc """
  Forces device to power off (without reboot).
  """
  @spec poweroff() :: :ok
  def poweroff(), do: logged_shutdown "poweroff"

  @doc """
  Forces device to halt (meaning hang, not power off, nor reboot).

  Note: this is different than :erlang.halt(), which exists BEAM, and
  may end up rebooting the device if erlinit.conf settings allow reboot on exit.
  """
  @spec halt() :: :ok
  def halt(), do: logged_shutdown "halt"

  # private helpers

  defp logged_shutdown(cmd, args \\ []) do
    Logger.info "#{__MODULE__} : device told to #{cmd}"

    # Invoke the appropriate command to tell erlinit that a shutdown
    # of the Erlang VM is imminent. erlinit 1.0+ gives some time
    # before the shutdown (10 seconds by default). Pre-erlinit 1.0
    # shuts down close to immediately.
    System.cmd(cmd, args)

    # Gracefully shut down
    :init.stop

    # If still shutting down and erlinit hasn't already killed
    # the Erlang VM, do so ourselves. This is set to a minute
    # since `:init.stop` and `erlinit` are expected to kill
    # the VM first.
    Process.sleep(60_000)
    System.halt
  end

  @spec maybe_pub_key_args(args) :: args
  defp maybe_pub_key_args(args) do
    pub_key_path = Application.get_env(:nerves_firmware, :pub_key_path)
    if pub_key_path do
      Logger.info "#{__MODULE__} using signature"
      ["-p", "#{pub_key_path}" | args]
    else
      args
    end
  end
end
