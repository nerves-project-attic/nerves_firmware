defmodule Nerves.Firmware.Test do
  @moduledoc false
  use ExUnit.Case

  doctest Nerves.Firmware

  @app_id :nerves_firmware

  test "Firmware app started succesfully" do
    assert Application.start(@app_id) == {:error, {:already_started, @app_id}}
  end
end
