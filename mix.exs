defmodule Makina.MixProject do
  use Mix.Project

  def project do
    [
      app: :makina,
      version: "0.1.18",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: {Makina.Cli, [Mix.env()]}
    ]
  end

  def releases do
    [
      makina_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          debug: Mix.env() != :prod,
          targets: [
            macos_m1: [os: :darwin, cpu: :aarch64]
          ]
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_interactive, "~> 4.3", only: :dev, runtime: false},
      {:burrito, "~> 1.0"},
      {:owl, "~> 0.12"},
      {:ucwidth, "~> 0.2"},
      {:nimble_options, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
