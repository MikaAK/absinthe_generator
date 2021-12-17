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
    [
      {:nimble_options, "~> 0.4"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
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

      groups_for_modules: [
        "Mutations": [
          AbsintheGenerator.Mutation
        ],

        "Queries": [
          AbsintheGenerator.Query
        ],

        "Resolvers": [
          AbsintheGenerator.Resolver
        ],

        "Schemas": [
          AbsintheGenerator.Schema,
          AbsintheGenerator.Schema.Field,
          AbsintheGenerator.Schema.Field.Argument,
          AbsintheGenerator.Schema.DataSource,
          AbsintheGenerator.Schema.Middleware
        ],

        "Types": [
          AbsintheGenerator.Type,
          AbsintheGenerator.Type.Enum,
          AbsintheGenerator.Type.Object,
          AbsintheGenerator.Type.Object.Field
        ]
      ]
    ]
  end
end
