defmodule Nerves.Firmware.Fwup do
  # Trivial wrapper around Frank Hunleth's FWUP package. Someday, this may be
  # useful as it's own module -- a porcelain for `fwup`, but it would need a lot
  # of cleanup and a much better API for streaming and return values.

  @moduledoc false
  @fwup_prog "fwup"

  require Logger

  @doc """
  Apply the firmware in <input> to the given <device>, executing <task>.

  Not implemented using ports, because ports cant send EOF, so it's not possible
  to stream firmware through a port.  Porcelain doesn't work because `goon` isn't
  easy to compile for the target in Nerves.

  The simple file-based I/O allows using named pipes to solve the streaming issues.
  """
  @spec apply(String.t, String.t, String.t) :: :ok | {:error, term}
  def apply(input, device, task) do
    Logger.info "Firmware: applying #{task} to #{device}"
    fwup_args = ["-aqU", "--no-eject", "-i", input, "-d", device, "-t", task]
    case System.cmd(@fwup_prog, fwup_args) do
      {_out, 0} ->
        :ok
      {error, _} ->
        Logger.error error
        {:error, :fwup_error}
    end
  end
end
