defmodule AbsintheGenerator.TypeTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Type{
    app_name: "MyApp",
    type_name: "book",

    enums: [
      %AbsintheGenerator.Type.EnumValue{
        name: "author_region",
        values: ["NA1", "EUW1", "EUN1, as: :euw"]
      },

      %AbsintheGenerator.Type.EnumValue{
        name: "genre",
        values: ["FANTASY, as: :F", "STEM"]
      }
    ],

    objects: [
      %AbsintheGenerator.Type.Object{
        name: "book",
        fields: [
          %AbsintheGenerator.Type.Object.Field{name: "id", type: ":id"},
          %AbsintheGenerator.Type.Object.Field{name: "name", type: ":string"},
          %AbsintheGenerator.Type.Object.Field{name: "genre", type: ":string"}
        ]
      },

      %AbsintheGenerator.Type.Object{
        name: "author",
        fields: [
          %AbsintheGenerator.Type.Object.Field{name: "id", type: ":id"},
          %AbsintheGenerator.Type.Object.Field{name: "book_id", type: ":id"},

          %AbsintheGenerator.Type.Object.Field{
            name: "is_topseller",
            type: ":string",
            resolver: "fn %{author: author}, _ -> author.total_books > 10 end"
          },

          %AbsintheGenerator.Type.Object.Field{name: "books", type: "list_of(:book)"}
        ]
      }
    ]
  }

  @expected_output String.replace_suffix("""
  defmodule MyApp.Types.Book do
    @moduledoc false

    use Absinthe.Schema.Notation

    import Absinthe.Resolution.Helpers, only: [dataloader: 1]

    enum :author_region do
      value :NA1
      value :EUW1
      value :EUN1, as: :euw
    end

    enum :genre do
      value :FANTASY, as: :F
      value :STEM
    end

    object :book do
      field :id, :id
      field :name, :string
      field :genre, :string
    end

    object :author do
      field :id, :id
      field :book_id, :id
      field :is_topseller, :string, resolve: fn %{author: author}, _ -> author.total_books > 10 end

      field :books, list_of(:book)
    end
  end
  """, "\n", "")

  describe "&run/1" do
    test "generates a fully setup schema file" do
      assert Enum.join(AbsintheGenerator.Type.run(@test_struct)) === @expected_output
    end
  end
end
