defmodule AbsintheGenerator.Schema.Field do
  @enforce_keys [:name, :return_type, :resolver_module_function]
  defstruct @enforce_keys ++ [
    :description,
    arguments: [],
    pre_middleware: [],
    post_middleware: []
  ]

  defmodule Argument do
    @enforce_keys [:name, :type]
    defstruct @enforce_keys

    @type t :: %AbsintheGenerator.Schema.Field.Argument{
      name: String.t,
      type: String.t
    }
  end

  @type t :: %AbsintheGenerator.Schema.Field{
    name: String.t,
    return_type: String.t,
    resolver_module_function: String.t,
    description: String.t,
    arguments: list(Argument.t),
    pre_middleware: list(String.t),
    post_middleware: list(String.t)
  }

  def maybe_add_non_null_argument(%Argument{type: type} = argument_struct) do
    if type =~ ~r/^non_null/ do
      argument_struct
    else
      %{argument_struct | type: "non_null(#{AbsintheGenerator.Type.maybe_string_atomize_type(type)})"}
    end
  end
end
