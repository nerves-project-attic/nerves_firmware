ExUnit.start()

defmodule Helpers do

  def firmware_file(filename) do
    Path.join "test/firmware_files", filename
  end
end