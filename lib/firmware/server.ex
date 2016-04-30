defmodule Nerves.Firmware.Server do
  @moduledoc false

  use GenServer
  alias Nerves.Firmware.Fwup
  require Logger

  @device Application.get_env(:nerves_firmware, :device, "/dev/mmcblk0")
  @type reason :: term
  @type state :: Struct.t

  defmodule State do
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
    {:reply, (state.status == :active), state}
  end

  def handle_call({:apply, firmware, action}, _from, state) do
    case Fwup.apply(firmware, @device, action) do
      :ok ->
        {:reply, :ok, %{state | status: :await_restart}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # return the public "state" of the firmware (not genserver state)
  defp public_state(state) do
    %{status: state.status, device: @device}
  end

end
