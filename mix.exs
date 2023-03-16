defmodule ExConfigurator.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_configurator,
      version: "0.1.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: "https://github.com/canuc/ex_configurator",
      homepage_url: "https://github.com/canuc/ex_configurator",
      docs: [
        # The main page in the docs
        main: "ExConfigurator",
        logo: "priv/ex_configurator.png",
        extras: ["README.md"]
      ],
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package() do
    [
      links: %{"GitHub" => "https://github.com/canuc/ex_configurator"},
      description: "Configuration tool.",
      licenses: ["Apache 2.0"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.5.7", only: :test, runtime: false}
    ]
  end
end
