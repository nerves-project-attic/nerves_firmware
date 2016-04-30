defmodule Nerves.Firmware.Adapters.Cowboy.Test do

  use ExUnit.Case, async: true
  import Helpers

  @device Application.get_env(:nerves_firmware, :device)

  defmodule TestServer do
    @moduledoc "configure cowboy to handle firmware on port 8088"

    @test_http_port 8088
    @test_http_path "/fw_http_test"
    @test_http_uri Path.join("localhost:#{@test_http_port}", @test_http_path)

    def uri, do: @test_http_uri

    def start do
      :ok = Application.start :ranch
      :ok = Application.start :cowlib
      :ok = Application.start :cowboy
      dispatch = :cowboy_router.compile [ {:_, [
        {@test_http_path, Nerves.Firmware.Adapters.Cowboy, []}
      ]} ]
      :cowboy.start_http(:http, 10, [port: @test_http_port], [env: [dispatch: dispatch]])
    end
  end

  {:ok, _} = HTTPotion.start
  {:ok, _} = TestServer.start

  test "returning status and installing firmware upgrade" do
    fw = firmware_file("test_1.fw")
    # create the low level firmware file
    assert :ok == Nerves.Firmware.Fwup.apply(fw, @device, :complete)    

    # now, test the firmware
    assert get_firmware_state[:status] == "active"
    #now, try installing firmware upgrade
   
    s = File.stat fw
    # delay 1500ms to force different mtime for updated firmware
    :timer.sleep 1500 
    assert 204 = send_firmware(fw)
    # REVIEW: SuperLame test
    s2 = File.stat(fw)
    assert s != s2
    # now that we've update firmware, we should be in await_restart state
    assert get_firmware_state[:status] == "await_restart"
    # this should fail with 403 since firmware is not yet rebooted
    assert 403 = send_firmware(fw)
    # and firmware should not be updated
    assert s != File.stat(fw)
  end

  defp get_firmware_state do
    resp = HTTPotion.get TestServer.uri, headers: ["Accept": "application/json"]
    assert resp.status_code == 200
    json_to_term(resp)
  end
  
  defp send_firmware(path) do
    resp = HTTPotion.put(TestServer.uri, [
           body: File.read!(path),
           headers: ["Content-Type": "application/x-firmware"]])
    resp.status_code
  end

  defp json_to_term(resp) do
    content_type = Keyword.fetch(resp.headers.hdrs, :'content-type')
    assert {:ok, "application/json"} == content_type
    {:ok, term} = JSX.decode(resp.body, [{:labels, :atom}])
    Enum.into term, []
  end

end
