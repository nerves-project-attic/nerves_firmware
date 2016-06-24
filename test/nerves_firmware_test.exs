defmodule Nerves.Firmware.Test do
  @moduledoc false
  use ExUnit.Case
  doctest Nerves.Firmware
  require Logger
  alias Nerves.Firmware

  @app_id :nerves_firmware
  @device Application.get_env(:nerves_firmware, :device, "/tmp/test_firmware.fw")

  test "Firmware app started succesfully" do
    assert Application.start(@app_id) == {:error, {:already_started, @app_id}}
  end

  test "returning proper status before and after firmware upgrade" do
    fw = firmware_file("test_1.fw")
    assert :ok == Firmware.Fwup.apply(fw, @device, :complete)
    assert Firmware.state()[:status] == :active
    #now, try installing firmware upgrade
    metrics1 = read_firmware_metrics(@device)
    assert metrics1 == read_firmware_metrics(@device)
    #assert Firmware.apply(fw, :upgrade) == :ok
    assert Firmware.upgrade_and_finalize(fw) == :ok
    metrics2 = read_firmware_metrics(@device)
    assert metrics1 != metrics2
    # now that we've update firmware, we should be in await_restart state
    assert Firmware.state()[:status] == :await_restart
    #assert Firmware.apply(fw, :upgrade) == :error
    assert Firmware.upgrade_and_finalize(fw) == {:error, :await_restart}
    metrics3 = read_firmware_metrics(@device)
    # and firmware should not be updated
    assert metrics2 == metrics3
    assert metrics1 != metrics3
  end

  # HELPER FUNCTIONS

  defp read_firmware_metrics(device) do
    {read_mbr(device)}
  end

  defp read_mbr(device) do
    File.open device, [:read], fn(file) ->
      IO.binread(file, 512)
    end
  end

  defp firmware_file(filename) do
    Path.join "test/firmware_files", filename
  end

end
