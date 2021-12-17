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