defmodule AbsintheGenerator.Resolver do
  @enforce_keys [:app_name, :resolver_name]
  defstruct @enforce_keys ++ [
    :moduledoc,
    resolver_functions: []
  ]

  @type t :: %AbsintheGenerator.Resolver{
    app_name: String.t,
    resolver_name: String.t,
    moduledoc: String.t,
    resolver_functions: list(String.t)
  }
end
