defmodule MyApp.Schema do
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
      |> Dataloader.add_source(BlitzPG.Challenges, Dataloader.Ecto.new(BlitzPG.Repo.CMS))
      |> Dataloader.add_source(BlitzPG.AuthAccounts, Dataloader.Ecto.new(BlitzPG.Repo.Auth))
  end

  def middleware(middleware, _, _) do
    middleware
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end
end