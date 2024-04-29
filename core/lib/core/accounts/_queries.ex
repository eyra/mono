defmodule Core.Accounts.Queries do
  import Ecto.Query, warn: false

  alias Core.Accounts.User
  alias Core.Accounts.Features
  alias Core.Accounts.Profile

  # User

  def users() do
    from(User, as: :user)
  end

  def users_by_pattern(field, pattern) when is_atom(field) and is_binary(pattern) do
    users()
    |> where([user: u], like(field(u, ^field), ^pattern))
  end

  def users_by_prefix(field, prefix) when is_atom(field) and is_binary(prefix) do
    users_by_pattern(field, "#{prefix}-%")
  end

  # Features

  def features do
    from(Features, as: :features)
  end

  def features_by_users(%Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)

    features()
    |> where([features: f], f.user_id in subquery(user_ids))
  end

  # Profile

  def profiles do
    from(Profile, as: :profile)
  end

  def profiles_by_users(%Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)

    profiles()
    |> where([profile: p], p.user_id in subquery(user_ids))
  end
end
