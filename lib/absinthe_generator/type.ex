defmodule AbsintheGenerator.Type do
  @enforce_keys [:app_name, :type_name]
  defstruct @enforce_keys ++ [
    :moduledoc,
    enums: [],
    objects: []
  ]

  defmodule EnumValue do
    @enforce_keys [:name, :values]
    defstruct @enforce_keys

    @type t :: %AbsintheGenerator.Type.EnumValue{name: String.t, values: list(String.t)}
  end

  defmodule Object do
    @enforce_keys [:name, :fields]
    defstruct @enforce_keys

    defmodule Field do
      @enforce_keys [:name, :type]
      defstruct [:resolver | @enforce_keys]

      @type t :: %AbsintheGenerator.Type.Object.Field{
        name: String.t,
        type: String.t,
        resolver: String.t
      }
    end

    @type t :: %AbsintheGenerator.Type.Object{
      name: String.t,
      fields: list(Field.t)
    }
  end

  @type t :: %AbsintheGenerator.Type{
    app_name: String.t,
    type_name: String.t,
    enums: list(AbsintheGenerator.Type.EnumValue.t),
    objects: list(AbsintheGenerator.Type.Object.t)
  }

  def run(%AbsintheGenerator.Type{
    enums: enums,
    objects: objects
  } = type_struct) do
    AbsintheGenerator.ensure_list_of_structs(enums, AbsintheGenerator.Type.EnumValue, "enums")
    AbsintheGenerator.ensure_list_of_structs(objects, AbsintheGenerator.Type.Object, "objects")

    Enum.each(
      objects,
      &(AbsintheGenerator.ensure_list_of_structs(&1.fields, AbsintheGenerator.Type.Object.Field, "fields"))
    )

    assigns = type_struct
      |> Map.from_struct
      |> Map.to_list

    "absinthe_type"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
