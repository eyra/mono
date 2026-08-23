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

  # Rewards for a user, scoped to a currency via the reward's fund. Shared base
  # for the per-status summary and the approved-payout list, both of which only
  # ever consider rewards payable in a single currency.
  def reward_query_in_currency(user_id, currency_name)
      when is_integer(user_id) and is_binary(currency_name) do
    from(reward in Fund.RewardModel,
      as: :reward,
      join: fund in assoc(reward, :fund),
      join: cur in assoc(fund, :currency),
      where: reward.user_id == ^user_id and cur.name == ^currency_name
    )
  end
end
