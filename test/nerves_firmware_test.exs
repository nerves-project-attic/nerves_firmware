defmodule Nerves.Firmware.Test do
  @moduledoc false

  use ExUnit.Case
  import Helpers

  doctest Nerves.Firmware

  @app_id :nerves_firmware
  @device Application.get_env(:nerves_firmware, :device, "/dev/mmcblk0")

  test "Firmware app started succesfully" do
    assert Application.start(@app_id) == {:error, {:already_started, @app_id}}
  end

  test "Creating the initial low level image file from test firmware" do
    assert :ok =
      firmware_file("test_1.fw")
      |> Nerves.Firmware.Fwup.apply(@device, :complete)
  end

end
