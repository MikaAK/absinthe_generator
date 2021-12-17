defmodule AbsintheGenerator.Definitions do
  @moduledoc false

  def app_name, do: [
    type: :string,
    required: true,
    doc: "Application name you're generating the code under"
  ]

  def query_namespace, do: [
    type: :string,
    required: true,
    doc: "The query or mutation namespace to organize the code under"
  ]

  def moduledoc, do: [
    type: :string,
    doc: "Moduledoc message can be injected into the resulting output code"
  ]

  def schema_field, do: [
    resolver_module_function: [
      type: :string,
      required: true,
      doc: "Resolver function to run for field `&MyModule.my_function/2`"
    ],

    name: [type: :string, required: true, doc: "Name of field"],
    return_type: [type: :string, required: true, doc: "Return type of field (\":user\")"],

    description: [type: :string, doc: "sets @desc for the field"],

    arguments: [
      type: :keyword_list,
      keys: [
        name: [type: :string, required: true, doc: "Name of the argument (\"user\")"],
        type: [type: :string, required: true, doc: "Name of the type (\":string\")"]
      ]
    ],

    pre_middleware: [
      type: {:list, :string},
      doc: "List of middleware to run before the resolver"
    ],

    post_middleware: [
      type: {:list, :string},
      doc: "List of middleware to run after the resolver"
    ]
  ]
end
