defmodule Systems.Fund.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Fund

  def currency_query() do
    from(Fund.CurrencyModel, as: :currency)
  end

  def currency_query(type) do
    build(currency_query(), :currency, [
      type == ^type
    ])
  end

  def reward_query() do
    from(Fund.RewardModel, as: :reward)
  end

  def reward_query(%Fund.Model{id: fund_id}) do
    build(reward_query(), :reward, [
      fund_id == ^fund_id
    ])
  end

  def reward_query(%Fund.Model{} = fund, status) when is_atom(status) do
    build(reward_query(fund), :reward, [
      status == ^status
    ])
  end
end
