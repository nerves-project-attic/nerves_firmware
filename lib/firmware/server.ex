defmodule Nerves.Firmware.Server do
  @moduledoc false

  use GenServer
  alias Nerves.Firmware.Fwup
  require Logger

  @device Application.get_env(:nerves_firmware, :device, "/dev/mmcblk0")
  @finalize_fw Application.get_env(:nerves_firmware, :finalize_fw, "/tmp/finalize.fw")

  @type reason :: term
  @type state :: Struct.t

  defmodule State do
    @moduledoc false
    defstruct status: :active
  end

  def start_link() do
    GenServer.start __MODULE__, :ok, name: __MODULE__
  end

  @spec init(term) :: {:ok, state} | {:error, reason}
  def init(_arg) do
    Logger.debug "#{__MODULE__}.init"
    {:ok, %State{}}
  end

  def handle_call({:state}, _from, state) do
    {:reply, public_state(state), state}
  end

  def handle_call({:allow_upgrade?}, _from, state) do
    {:reply, allow_upgrade?(state), state}
  end

  def handle_call({:apply, firmware, action}, _from, state) do
    try_apply_if_allowed state, fn() ->
      apply(firmware, @device, action)
    end
  end

  def handle_call({:upgrade_and_finalize, firmware}, _from, state) do
    try_apply_if_allowed state, fn() ->
      do_upgrade_and_finalize(firmware)
    end
  end

  defp try_apply_if_allowed(state, afn) do
    if allow_upgrade?(state) do
      try_apply(state, afn)
    else
      {:reply, {:error, :await_restart}, state}
    end
  end

  defp try_apply(state, afn) do
    case afn.() do
      :ok ->
        {:reply, :ok, %{state | status: :await_restart}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp allow_upgrade?(state) do
    state.status == :active
  end

  @spec do_upgrade_and_finalize(String.t) :: :ok | {:error, reason}
  defp do_upgrade_and_finalize(firmware) do
    File.rm(@finalize_fw)
    case Fwup.apply(firmware, @device, "upgrade") do
      {:error, reason} ->
        Logger.error "#{__MODULE__} upgrade failed: #{inspect reason}"
        {:error, reason}
      :ok ->
        Logger.info "upgrade succeded"
        if File.exists?(@finalize_fw) do
          Logger.info "Found #{@finalize_fw}, applying finalize/on-reboot"
          try_finalize(@finalize_fw)
        else
          :ok
        end
    end
  end

  # called after upgrade to see if we have a finalize.fw for a 2-phase
  # firmware update.  If so, apply it by running the on-reboot task.
  @spec try_finalize(String.t) :: :ok | {:error, :reason}
  defp try_finalize(ffw) do
    case Fwup.apply(ffw, @device, "on-reboot") do
      :ok ->
        Logger.info "finalize/on-reboot succeded, ready for restart"
        :ok
      {:error, reason} ->
        Logger.info "finalize/on-reboot failed: #{inspect reason}"
        {:error, reason}
    end
  end

  # return the public "state" of the firmware (not genserver state)
  defp public_state(state) do
    %{status: state.status, device: @device}
  end

end
