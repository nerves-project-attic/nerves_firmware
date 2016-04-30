defmodule Nerves.Firmware.Adapters.Cowboy.Test do

  use ExUnit.Case
  import Helpers

  defmodule TestServer do
    @moduledoc "configure and start a basic http server on port 8088 using cowboy"

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

  test "adapter is up and returns json response about the firmware" do
    resp = HTTPotion.get TestServer.uri, headers: ["Accept": "application/json"]
    headers = resp.headers.hdrs
    assert resp.status_code == 200
    assert {:ok, "Cowboy"} = Keyword.fetch(headers, :server)
    assert {:ok, "application/json"} = Keyword.fetch(headers, :'content-type')
  end

  test "adapter accepts and installs a firmware update" do
    fw = firmware_file("test_1.fw")
    s = File.stat fw
    assert 204 = send_firmware(fw)
    # REVIEW: SuperLame test
    s2 = File.stat(fw)
    assert s != s2
    # this should fail with 403 since firmware is not yet rebooted
    assert 403 = send_firmware(fw)
    # and firmware should not be updated
    assert s != File.stat(fw)
  end

  defp send_firmware(path) do
    resp = HTTPotion.put(TestServer.uri, [
           body: File.read!(path),
           headers: ["Content-Type": "application/x-firmware"]])
    resp.status_code
  end

  defp header(resp, key) do
    unless is_atom(key) do
      key = String.to_atom(key)
    end
    assert {:ok, result} = Keyword.fetch(resp.headers, key)
    {:ok, result}
  end

  defp jterm(resp) do
    # {:ok, content_type} = header resp, "content-type"
    {:ok, term} = JSX.decode(resp.body, [{:labels, :atom}])
    Enum.into term, []
  end

end
