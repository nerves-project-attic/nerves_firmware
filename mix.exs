defmodule Nerves.Firmware.Mixfile do
  use Mix.Project

  def project do
    [app: :nerves_firmware,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(Mix.env)]
  end

  def application do
    [applications: [:logger, :exjsx], mod: {Nerves.Firmware, []}]
  end

  defp deps(:test), do: deps(:dev) ++ [
    { :httpotion, github: "myfreeweb/httpotion"},
    { :cowboy, "~> 1.0" }
  ]

  defp deps(_), do: [
    { :earmark, "~> 0.1", only: :dev },
    { :ex_doc, "~> 0.7", only: :dev },
    { :exjsx, "~> 3.2.0" }
  ]
end