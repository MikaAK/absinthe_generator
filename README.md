AbsintheGenerator
===

[![Test](https://github.com/MikaAK/absinthe_generator/actions/workflows/test-action.yml/badge.svg)](https://github.com/MikaAK/absinthe_generator/actions/workflows/test-action.yml)
[![Hex pm](http://img.shields.io/hexpm/v/absinthe_generator.svg?style=flat)](https://hex.pm/packages/absinthe_generator)

Collection of mix tasks to help generate absinthe
projects and schemas

This can be used to generate either individiual parts
of your application or full sections

## Installation

[Available in Hex](https://hex.pm/packages/absinthe_generator), the package can be installed
by adding `absinthe_generator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_generator, "~> 0.1"}
  ]
end
```

## Using via Mix Task
We have a few commands we gain access to using this package:

```bash
mix absinthe              # Lists help for absinthe.gen. commands
mix absinthe.gen          # Lists help for absinthe.gen. commands
mix absinthe.gen.mutation # Generates an absinthe mutation schema and inserts the record in the base schema.ex
mix absinthe.gen.query    # Generates an absinthe query schema and inserts the record in the base schema.ex
mix absinthe.gen.resolver # Generates an absinthe resolver
mix absinthe.gen.schema   # Generates an absinthe schema
mix absinthe.gen.type     # Generates an absinthe type
```

## Using via Code
This library also enables developers to create configs that pass into each portion
and those configs can be utilized to generate absinthe portions. To see more on this
please checkout the docs for:

- `AbsintheGenerator.Schema`
- `AbsintheGenerator.Mutation`
- `AbsintheGenerator.Query`
- `AbsintheGenerator.Resolver`
- `AbsintheGenerator.Type`

Each of these modules defines a struct, when passed to the `&AbsintheGenerator.Schema.run/1` function
this will generate a string template for your file


### Contributing
This library favors output format over template format and
therefore has some sacrifices made in the favor of well formatted output code
