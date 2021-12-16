# AbsintheGenerator
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
```

## Using via Code
This library also enables developers to create configs that pass into each portion
and those configs can be utilized to generate absinthe portions. To see more on this
please checkout the [hexdocs](https://hex.pm/packages/absinthe_generator)


### Contributing
This library favors output format over template format and
therefore has some sacrifices made in the favor of well formatted output code
