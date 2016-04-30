defmodule Nerves.Firmware.Adapters.Cowboy do
  @moduledoc """
  Implements a Cowboy HTTP/REST adapter for Nerves.Firmware

  Defines an _acceptor_ that receives and installs firmware updates. Simply use
  use __HTTP PUT__ to send a firmware to the URI for the device, specifying
  Content-Type `application/x-firmware`

  Also defines a _provider_ for the `application/json` content type that allows
  an HTTP GET to reutrn information on the current firmware status and metadata
  in JSON form.

  ## Configuration Example

  Reference the adapter in your cowboy dispatch routes wherever you want.
  To place the resource at "/firmware", for instance, do:

  ```elixir
  cowboy_dispatch = :cowboy_router.compile [ {:_, [
    { "/firmware", Nerves.Firmware.Adapters.Cowboy, [] }
  ]} ]
  ```
  """

  require Logger

  @max_upload_chunk 100000        # 100K max chunks to keep memory reasonable
  @max_upload_size  100000000     # 100M max file to avoid using all of flash
  @tmp_fw_path "/tmp/uploaded.fw"

  def init(_transport, _req, _state) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def rest_init(req, handler_opts) do
    {:ok, req, handler_opts}
  end

  def allowed_methods(req, state) do
    {["GET", "PUT", "POST"], req, state}
  end

  def content_types_provided(req, state) do
    {[
      {"application/json", :json_provider}
    ], req, state}
  end

  def content_types_accepted(req, state) do
    {[
      {{"application", "x-firmware", []}, :upload_acceptor}
    ], req, state}
  end

  def json_provider(req, state) do
    term = Nerves.Firmware.state
    {:ok, body} = JSX.encode(term, [{:space, 1}, {:indent, 2}])
    { body <> "\n", req, state}
  end

  @doc """
  Acceptor for cowboy to update firmware via HTTP.

  Once firmware is streamed, it returns success (2XX) or failure (4XX/5XX).
  Calls `update_status()` to reflect status at `/sys/firmware`.
  Won't let you upload firmware on top of provisional (returns 403)
  """
  def upload_acceptor(req, state) do
		Logger.info "request to receive firmware"
    if Nerves.Firmware.allow_upgrade? do
      upload_and_apply_firmware(req, state)
    else
      {:halt, reply_with(403, req), state}
		end
  end

  # TODO:  Ideally we'd like to allow streaming directly to fwup, but its hard
  # due to limitations with ports and writing to fifo's from elixir
  # Right solution would be to get Porcelain fixed to avoid golang for goon.
  defp upload_and_apply_firmware(req, state) do
		Logger.info "receiving firmware"
		File.open!(@tmp_fw_path, [:write], &(stream_fw &1, req))
    Logger.info "firmware received"
    response = case Nerves.Firmware.apply(@tmp_fw_path, :upgrade) do
      {:error, _whatever} ->
        {:halt, reply_with(400, req), state}
      {:ok, _fw_metadata} ->  # TODO: consider returning metadata
        {true, req, state}
      :ok ->
        {true, req, state}
    end
    File.rm @tmp_fw_path
    response
  end

  # helper to return errors to requests from cowboy more easily
  defp reply_with(code, req) do
    {:ok, req} = :cowboy_req.reply(code, [], req)
    req
  end

  # copy from a cowboy req into a IO.Stream
  defp stream_fw(f, req, count \\ 0) do
    #  send an event about (bytes_uploaded: count)
    if count > @max_upload_size do
      {:error, :too_large}
    else
      case :cowboy_req.body(req, [:length, @max_upload_chunk]) do
        {:more, chunk, new_req} ->
          :ok = IO.binwrite f, chunk
          stream_fw(f, new_req, (count + byte_size(chunk)))
        {:ok, chunk, new_req} ->
          :ok = IO.binwrite f, chunk
          {:done, new_req}
      end
    end
  end
end
