defmodule AbsintheGenerator.Query do
  @enforce_keys [:name, :return_type, :resolver_module, :resolver_function]
  defstruct @enforce_keys

  def run(mutations) do
  end
end
