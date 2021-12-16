defmodule MyApp.Schema.Mutations.User do
  use Absinthe.Schema.Notation

  alias MyApp.Resolvers

  object :user_mutations do
    @desc "Lists all the current users"
    field :users, list_of(:users) do
      arg :id, :id

      resolve &Resolvers.User.list_users/2
    end
  end
end