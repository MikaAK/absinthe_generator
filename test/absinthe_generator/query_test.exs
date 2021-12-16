defmodule AbsintheGenerator.QueryTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Query{
    app_name: "MyApp",
    query_name: "user",
    queries: [
      %AbsintheGenerator.Schema.Field{
        description: "Lists the current users",
        name: "me",
        post_middleware: ["BlitzSharedMiddleware.ChangesetErrorFormatter"],
        pre_middleware: ["BlitzSharedMiddleware.Auth"],
        resolver_module_function: "&Resolvers.User.me/2",
        return_type: ":user"
      },

      %AbsintheGenerator.Schema.Field{
        description: "Lists all the current users",
        name: "users",
        resolver_module_function: "&Resolvers.User.list_users/2",
        return_type: "list_of(:user)",
        post_middleware: [
          "BlitzSharedMiddleware.ChangesetErrorFormatter",
          "BlitzSharedMiddleware.PostProcessor"
        ],

        pre_middleware: [
          "BlitzSharedMiddleware.PreProcessor",
          "BlitzSharedMiddleware.Auth, roles: [:ADMIN]"
        ],

        arguments: [
          %AbsintheGenerator.Schema.Field.Argument{
            name: "name",
            type: ":string"
          },

          %AbsintheGenerator.Schema.Field.Argument{
            name: "email",
            type: ":string"
          },
        ]
      }
    ]
  }

  @expected_output String.replace_suffix("""
  defmodule MyApp.Schema.Queries.User do
    @moduledoc false

    use Absinthe.Schema.Notation

    alias MyApp.Resolvers

    object :user_queries do
      @desc "Lists the current users"
      field :me, :user do
        middleware BlitzSharedMiddleware.Auth

        resolve &Resolvers.User.me/2

        middleware BlitzSharedMiddleware.ChangesetErrorFormatter
      end

      @desc "Lists all the current users"
      field :users, list_of(:user) do
        arg :name, :string
        arg :email, :string

        middleware BlitzSharedMiddleware.PreProcessor
        middleware BlitzSharedMiddleware.Auth, roles: [:ADMIN]

        resolve &Resolvers.User.list_users/2

        middleware BlitzSharedMiddleware.ChangesetErrorFormatter
        middleware BlitzSharedMiddleware.PostProcessor
      end
    end
  end
  """, "\n", "")

  describe "&run/1" do
    test "generates a fully setup query file" do
      assert Enum.join(AbsintheGenerator.Query.run(@test_struct)) === @expected_output
    end
  end
end
