defmodule Nerves.Firmware.Test do
  @moduledoc false

  use ExUnit.Case
  import Helpers

  doctest Nerves.Firmware

  @app_id :nerves_firmware

  test "Firmware app started succesfully" do
    assert Application.start(@app_id) == {:error, {:already_started, @app_id}}
  end

  test "Firmware installed the specified firmware file" do
#    Nerves.Firmware.apply firmware_file("test_1.fw"), :complete
#    Nerves.Firmware.apply firmware_file("test_1.fw"), :upgrade
  end

end
