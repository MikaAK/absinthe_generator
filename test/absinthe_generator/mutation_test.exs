defmodule AbsintheGenerator.MutationTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Mutation{
    app_name: "MyApp",
    mutation_name: "user",
    mutations: [
      %AbsintheGenerator.Schema.Field{
        description: "Updates the current user",
        name: "update_user",
        post_middleware: ["SharedMiddleware.ChangesetErrorFormatter"],
        pre_middleware: ["SharedMiddleware.Auth"],
        resolver_module_function: "&Resolvers.User.update_user/2",
        return_type: ":user"
      },

      %AbsintheGenerator.Schema.Field{
        description: "Updates all users",
        name: "update_users",
        resolver_module_function: "&Resolvers.User.update_all_users/2",
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
            name: "id",
            type: ":id"
          },

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
  defmodule MyApp.Schema.Mutations.User do
    @moduledoc false

    use Absinthe.Schema.Notation

    alias MyApp.Resolvers

    object :user_mutations do
      @desc "Updates the current user"
      field :update_user, :user do
        middleware SharedMiddleware.Auth

        resolve &Resolvers.User.update_user/2

        middleware SharedMiddleware.ChangesetErrorFormatter
      end

      @desc "Updates all users"
      field :update_users, list_of(:user) do
        arg :id, :id
        arg :name, :string
        arg :email, :string

        middleware SharedMiddleware.PreProcessor
        middleware SharedMiddleware.Auth, roles: [:ADMIN]

        resolve &Resolvers.User.update_all_users/2

        middleware SharedMiddleware.ChangesetErrorFormatter
        middleware SharedMiddleware.PostProcessor
      end
    end
  end
  """, "\n", "")

  describe "&run/1" do
    test "generates a fully setup mutation file" do
      assert Enum.join(AbsintheGenerator.Mutation.run(@test_struct)) === @expected_output
    end
  end
end
