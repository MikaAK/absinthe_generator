defmodule AbsintheGenerator.Resolver do
  @enforce_keys [:app_name, :resolver_name]
  defstruct @enforce_keys ++ [
    resolver_functions: []
  ]
end
