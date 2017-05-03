defmodule Nerves.Firmware.Fwup do
  use GenServer
  require Logger

  @timeout 120_000

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :callback, self())
    GenServer.start_link(__MODULE__, opts)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def stream_chunk(pid, chunk, opts \\ [await: false]) do
    Logger.debug "Sending Chunk: #{inspect chunk}"
    GenServer.call(pid, {:stream_chunk, chunk, opts}, @timeout)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)
    device = opts[:device] || Application.get_env(:nerves_firmware, :device, "/dev/mmcblk0")
    task = opts[:task] || "upgrade"
    fwup = System.find_executable("fwup")
    callback = opts[:callback]
    port = Port.open({:spawn_executable, fwup},
      [{:args, ["-aFU", "-d", device, "-t", task]},
        {:packet, 4},
        :use_stdio,
        :binary,
        :exit_status])
    {:ok, %{
      port: port,
      byte_size: 0,
      callback: callback
    }}
  end

  def handle_call({:stream_chunk, chunk, opts}, from, s) do
    send s.port, {self(), {:command, chunk}}
    case opts[:await] do
      true -> {:noreply, %{s | callback: from}}
      false -> {:reply, :ok, s}
    end
  end

  def handle_info({_port, {:data, <<"OK", code :: integer-16>>}}, s) do
    Logger.debug "FWUP Done"
    GenServer.reply(s.callback, :ok)
    {:noreply, s}
  end

  def handle_info({_port, {:data, <<"ER", code :: integer-16, message :: binary>>}}, s) do
    Logger.debug "FWUP Error #{code}: #{message}"
    {:noreply, s}
  end

  def handle_info({_port, {:data, <<warning :: binary-2, code :: integer-16, message :: binary>>}}, s)
    when warning in ["WA", "WN"] do
    Logger.debug "FWUP Warning #{code}: #{message}"
    {:noreply, s}
  end

  def handle_info({_port, {:data, <<"PR", progress :: integer-16>>}}, s) do
    Logger.debug "FWUP Progress: #{progress}%"
    {:noreply, s}
  end

  def handle_info({_port, {:data, resp}}, s) do
    Logger.debug "FWUP unknown response: #{inspect resp}"
    {:noreply, s}
  end

  def handle_info(msg, s) do
    {:noreply, s}
  end

  @doc """
  Apply the firmware in <input> to the given <device>, executing <task>.

  `args` is a list of arguments to be passed to fwup.

  Not implemented using ports, because ports cant send EOF, so it's not possible
  to stream firmware through a port.  Porcelain doesn't work because `goon` isn't
  easy to compile for the target in Nerves.

  The simple file-based I/O allows using named pipes to solve the streaming issues.
  """
  @spec apply(String.t, String.t, String.t, [binary]) :: :ok | {:error, term}
  def apply(input, device, task, args \\ []) do
    Logger.info "Firmware: applying #{task} to #{device}"
    fwup_args =
      ["-aqU", "--no-eject", "-i", input, "-d", device, "-t", task] ++ args
    case System.cmd("fwup", fwup_args) do
      {_out, 0} ->
        :ok
      {error, _} ->
        Logger.error error
        {:error, :fwup_error}
    end
  end
end
