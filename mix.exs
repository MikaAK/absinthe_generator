defmodule AbsintheGenerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_generator,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Generators for absinthe to help reduce writing boilerplate",
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/MikaAK/absinthe_generator"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib)
    ]
  end

  defp docs do
    [
      main: "AbsintheGenerator",
      source_url: "https://github.com/MikaAK/absinthe_generator",
    ]
  end
end
