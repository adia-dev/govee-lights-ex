defmodule GoveeLights.MixProject do
  use Mix.Project

  def project do
    [
      app: :govee_lights,
      version: "0.1.3",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Govee Lights",
      source_url: "https://github.com/adia-dev/govee-lights-ex",
      description: description(),
      package: package(),
      docs: &docs/0,
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.16"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp description do
    "Simple Elixir wrapper around the Govee Developer API for listing and controlling lights."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/adia-dev/govee-lights-ex"
      },
      files: ~w(
        lib
        assets
        mix.exs
        README.md
        LICENSE
      )
    ]
  end

  defp docs do
    [
      main: "GoveeLights",
      logo: "assets/logo.png",
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
