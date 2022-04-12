defmodule AbsintheGenerator.Type do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    type_name: [type: :string, required: true, doc: "name of the type"],
    moduledoc: Definitions.moduledoc(),
    enums: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.Type.EnumValue`{}"
    ],

    objects: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.Type.Object`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate resolver files which
  are then used in the mutations/queries/subscriptions

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator
  @behaviour AbsintheGenerator.FileWriter

  def definitions, do: @definition

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
    defstruct [{:input?, false} | @enforce_keys]

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


  @impl AbsintheGenerator.FileWriter
  def file_path(%AbsintheGenerator.Type{app_name: app_name, type_name: type_name}) do
    "./lib/#{Macro.underscore(app_name)}/types/#{Macro.underscore(type_name)}.ex"
  end

  @impl AbsintheGenerator
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

    type_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = type_struct
      |> Map.from_struct
      |> maybe_add_dataloader_import
      |> Map.to_list

    "absinthe_type"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end

  def maybe_add_non_null(%AbsintheGenerator.Type.Object.Field{type: type} = type_struct) do
    if type =~ ~r/^non_null/ do
      type_struct
    else
      %{type_struct | type: "non_null(#{maybe_string_atomize_type(type)})"}
    end
  end

  def maybe_string_atomize_type(field_type) do
    if field_type =~ ~r/[\(\):]/ do
      field_type
    else
      ":#{field_type}"
    end
  end

  defp maybe_add_dataloader_import(%{objects: objects} = type_arguments) do
    dataloader_used? = Enum.any?(objects, fn object ->
      Enum.any?(object.fields, &(&1.resolver))
    end)

    Map.put(type_arguments, :dataloader_used?, dataloader_used?)
  end
end
