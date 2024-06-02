defmodule Systems.Pool.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Pool
  alias Systems.Budget
  alias Systems.Account

  def pool_query() do
    from(Pool.Model, as: :pool)
  end

  def pool_query(%Pool.Model{id: pool_id}) do
    build(pool_query(), :pool, [
      id == ^pool_id
    ])
  end

  def pool_query(%Budget.CurrencyModel{id: currency_id}) do
    build(pool_query(), :pool, [
      currency_id == ^currency_id
    ])
  end

  def pool_query(%Account.User{id: user_id}, role) when is_atom(role) do
    build(pool_query(), :pool,
      auth_node: [
        role_assignments: [
          role == ^role,
          principal_id == ^user_id
        ]
      ]
    )
  end

  def pool_query(%Budget.CurrencyModel{id: currency_id}, %Account.User{} = user, role) do
    build(pool_query(user, role), :pool, [
      currency_id == ^currency_id
    ])
  end

  def pool_query(%Pool.Model{id: pool_id}, %Account.User{} = user, role) do
    build(pool_query(user, role), :pool, [
      id == ^pool_id
    ])
  end
end
