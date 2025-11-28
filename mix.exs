defmodule GoveeLights.MixProject do
  use Mix.Project

  def project do
    [
      app: :govee_lights,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Govee Lights",
      source_url: "https://github.com/adia-dev/govee-lights-ex",
      docs: &docs/0
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.16"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp docs do
    [
      main: "GoveeLights",
      logo: "assets/logo.png",
      extras: ["README.md"]
    ]
  end
end
