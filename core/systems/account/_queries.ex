defmodule Systems.Account.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Account.User
  alias Systems.Account.FeaturesModel
  alias Systems.Account.UserProfileModel
  alias Systems.Affiliate

  # User

  def users() do
    user_query()
  end

  def users_by_pattern(field, pattern) when is_atom(field) and is_binary(pattern) do
    users()
    |> where([user: u], like(field(u, ^field), ^pattern))
  end

  def users_by_prefix(field, prefix) when is_atom(field) and is_binary(prefix) do
    users_by_pattern(field, "#{prefix}-%")
  end

  def user_query() do
    from(User, as: :user)
  end

  def user_query(user_id) when is_integer(user_id) do
    build(user_query(), :user, [
      id == ^user_id
    ])
  end

  def user_query(creator?: creator?) do
    build(user_query(), :user, [
      creator == ^creator?
    ])
  end

  def user_query(affiliate?: true) do
    user_query()
    |> join(:left, [user: u], a in Affiliate.User, on: u.id == a.user_id, as: :affiliate)
    |> where([affiliate: a], not is_nil(a.id))
  end

  def user_query(external?: true) do
    user_query()
    |> join(:left, [user: u], e in ExternalSignIn.User, on: u.id == e.user_id, as: :external)
    |> where([external: e], not is_nil(e.id))
  end

  def user_query(internal?: true) do
    user_query()
    |> join(:left, [user: u], a in Affiliate.User, on: u.id == a.user_id, as: :affiliate)
    |> join(:left, [user: u], e in ExternalSignIn.User, on: u.id == e.user_id, as: :external)
    |> where([affiliate: a, external: e], is_nil(a.id) and is_nil(e.id))
  end

  def user_query_by_email(email_fragment) do
    user_query()
    |> where([user: u], like(u.email, ^email_fragment))
  end

  # Features

  def features do
    from(FeaturesModel, as: :features)
  end

  def features_by_users(%Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)

    features()
    |> where([features: f], f.user_id in subquery(user_ids))
  end

  # Profile

  def profiles do
    from(UserProfileModel, as: :profile)
  end

  def profiles_by_users(%Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)

    profiles()
    |> where([profile: p], p.user_id in subquery(user_ids))
  end
end
