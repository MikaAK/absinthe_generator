defmodule AbsintheGenerator.QueryTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Query{
    app_name: "MyApp",
    query_name: "user",
    queries: [
      %AbsintheGenerator.Schema.Field{
        description: "Lists the current users",
        name: "me",
        post_middleware: ["SharedMiddleware.ChangesetErrorFormatter"],
        pre_middleware: ["SharedMiddleware.Auth"],
        resolver_module_function: "&Resolvers.User.me/2",
        return_type: ":user"
      },

      %AbsintheGenerator.Schema.Field{
        description: "Lists all the current users",
        name: "users",
        resolver_module_function: "&Resolvers.User.list_users/2",
        return_type: "list_of(:user)",
        post_middleware: [
          "SharedMiddleware.ChangesetErrorFormatter",
          "SharedMiddleware.PostProcessor"
        ],

        pre_middleware: [
          "SharedMiddleware.PreProcessor",
          "SharedMiddleware.Auth, roles: [:ADMIN]"
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
        middleware SharedMiddleware.Auth

        resolve &Resolvers.User.me/2

        middleware SharedMiddleware.ChangesetErrorFormatter
      end

      @desc "Lists all the current users"
      field :users, list_of(:user) do
        arg :name, :string
        arg :email, :string

        middleware SharedMiddleware.PreProcessor
        middleware SharedMiddleware.Auth, roles: [:ADMIN]

        resolve &Resolvers.User.list_users/2

        middleware SharedMiddleware.ChangesetErrorFormatter
        middleware SharedMiddleware.PostProcessor
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
