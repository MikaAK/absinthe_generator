defmodule AbsintheGenerator.SchemaTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Schema{
    app_name: "MyApp",
    mutations: ["user", "summoner"],
    queries: ["user", "summoner"],
    subscriptions: ["user"],
    types: ["User", "Summoner"],
    post_middleware: [
      "SharedMiddleware.ChangesetErrorFormatter",
      "SharedMiddleware.AuthorizationMiddleware"
    ],

    pre_middleware: [
      "SharedMiddleware.IDIntegerConverter",
      "SharedMiddleware.ChampionIDValidator"
    ],

    data_sources: [
      %AbsintheGenerator.Schema.DataSource{
        query: "Dataloader.Ecto.new(Repo.CMS)",
        source: "CMS"
      },

      %AbsintheGenerator.Schema.DataSource{
        query: "Dataloader.Ecto.new(Repo.Auth)",
        source: "AuthAccounts"
      }
    ],
  }

  @expected_output String.replace_suffix("""
  defmodule MyApp.Schema do
    @moduledoc false

    use Absinthe.Schema

    alias MyApp.Types
    alias MyApp.Schema.{Mutations, Queries}

    # Types
    import_types Types.User
    import_types Types.Summoner

    # Queries
    import_types Queries.User
    import_types Queries.Summoner

    # Mutations
    import_types Mutations.User
    import_types Mutations.Summoner

    query do
      import_fields :user_queries
      import_fields :summoner_queries
    end

    mutations do
      import_fields :user_mutations
      import_fields :summoner_mutations
    end

    subscriptions do
      import_fields :user_subscriptions
    end

    def context(ctx) do
      loader =
        Dataloader.new()
        |> Dataloader.add_source(CMS, Dataloader.Ecto.new(Repo.CMS))
        |> Dataloader.add_source(AuthAccounts, Dataloader.Ecto.new(Repo.Auth))
    end

    def middleware(middleware, _, _) do
      middleware
    end

    def plugins do
      [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
    end
  end
  """, "\n", "")

  describe "&run/1" do
    test "generates a fully setup schema file" do
      assert Enum.join(AbsintheGenerator.Schema.run(@test_struct)) === @expected_output
    end
  end
end
