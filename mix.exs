defmodule Nerves.Firmware.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :nerves_firmware,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(Mix.env),
      description: "Manage and update firmware on a Nerves device",
      package: package(),
      name: "Nerves.Firmware",
      docs: docs()  ]
  end

  def application do
    [ applications: [:logger], mod: {Nerves.Firmware, []} ]
  end

  defp deps(_) do
    [{:ex_doc, "~> 0.15", only: :dev}]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "Nerves.Firmware",
      source_url: "https://github.com/nerves-project/nerves_firmware",
      extras: [ "README.md", "CHANGELOG.md"]
    ]
  end

  defp package do
    [ maintainers: ["Justin Schneck", "Garth Hitchens"],
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/nerves-project/nerves_firmware"}]
  end
end
