defmodule Nerves.Firmware.Server do
  @moduledoc false

  use GenServer
  alias Nerves.Firmware.Fwup

  @device Application.get_env(:nerves_firmware, :device, "/dev/mmcblk0")
  @type reason :: term
  @type state :: Struct.t

  defmodule State do
    defstruct state: :active
  end

  def start_link() do
    GenServer.start __MODULE__, :ok, name: __MODULE__
  end

  @spec init(term) :: {:ok, state} | {:error, reason}
  def init(_arg) do
    {:ok, %State{}}
  end

  def handle_call({:allow_upgrade?}, _from, state) do
    {:reply, (state.state == :active), state}
  end

  def handle_call({:apply, firmware, action}, _from, state) do
    case Fwup.apply(firmware, @device, action) do
      :ok ->
        {:reply, :ok, %{state | state: :await_restart}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

end
