defmodule Systems.Fund.Dormancy do
  @moduledoc """
  Auto-donation of dormant reward balances
  """

  use Core, :public

  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Fund
  alias Systems.Notify

  @currency "euro"
  @warning :reward_dormancy_warning
  @donated :reward_auto_donated

  @doc """
  Warns every participant holding rewards untouched since before `cutoff`, and
  marks those rewards as warned. One mail per participant, however many rewards
  it covers. A reward still untouched since its last warning is skipped, so
  re-running is harmless.

  Returns the rewards that were warned about.
  """
  def remind(%NaiveDateTime{} = cutoff, %Date{} = deadline) do
    warnings = warning_times()

    cutoff
    |> dormant_rewards()
    |> Enum.reject(&warned_since?(&1, warnings))
    |> Enum.group_by(&participant/1)
    |> Enum.flat_map(&warn_participant(&1, deadline))
  end

  @doc """
  Donates every reward warned about before `cutoff` and still unclaimed.

  Returns one `Fund.Public.donate_rewards/2` result per participant.
  """
  def donate(%NaiveDateTime{} = cutoff) do
    cutoff
    |> warned_rewards()
    |> Enum.group_by(&participant/1)
    |> Enum.map(&donate_balance/1)
  end

  defp dormant_rewards(cutoff) do
    @currency
    |> Fund.Queries.approved_rewards_before(cutoff)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp warned_rewards(cutoff) do
    warnings = warning_times(recorded_before: cutoff)

    @currency
    |> Fund.Queries.approved_rewards_before(cutoff)
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.filter(&warned_since?(&1, warnings))
  end

  defp warning_times(opts \\ []) do
    @warning
    |> Notify.Public.list_events(opts)
    |> Enum.flat_map(&covered_reward_times/1)
    |> Map.new()
  end

  defp covered_reward_times(%Notify.EventModel{
         metadata: %{"reward_ids" => ids},
         inserted_at: warned_at
       }),
       do: Enum.map(ids, &{&1, warned_at})

  defp covered_reward_times(%Notify.EventModel{}), do: []

  defp participant(%Fund.RewardModel{user: user}), do: user

  defp warned_since?(%Fund.RewardModel{id: id, updated_at: updated_at}, warnings) do
    case Map.fetch(warnings, id) do
      {:ok, warned_at} -> NaiveDateTime.compare(updated_at, warned_at) != :gt
      :error -> false
    end
  end

  defp warn_participant({user, rewards}, deadline) do
    case Notify.Public.record_event(warning_event(user, rewards, deadline)) do
      {:ok, _event} -> warned(user, rewards, deadline)
      {:error, reason} -> failed_to_warn(user, reason)
    end
  end

  defp warning_event(%Account.User{id: user_id} = user, rewards, deadline) do
    %Notify.EventAttrs{
      type: @warning,
      subject_user: user,
      correlation_id: "fund_dormancy:user:#{user_id}",
      source: __MODULE__,
      metadata: %{
        "reward_ids" => Enum.map(rewards, & &1.id),
        "amount_cents" => total_amount(rewards),
        "deadline" => Date.to_string(deadline)
      }
    }
  end

  defp warned(user, rewards, deadline) do
    log_warning(user, rewards, deadline)
    rewards
  end

  defp failed_to_warn(%Account.User{id: user_id}, reason) do
    Logger.error(
      "[Fund.Dormancy] failed to warn user ##{user_id} about dormant rewards: #{inspect(reason)}"
    )

    []
  end

  defp donate_balance({user, rewards}) do
    case Fund.Public.donate_rewards(user, rewards) do
      {:ok, donation} -> donated(user, rewards, donation)
      {:error, reason} = error -> failed_to_donate(user, reason, error)
    end
  end

  defp donated(user, rewards, %Fund.DonationModel{uid: uid, amount_cents: amount} = donation) do
    Notify.Public.record_event(%Notify.EventAttrs{
      type: @donated,
      subject_user: user,
      correlation_id: "fund_dormancy:donation:#{uid}",
      source: __MODULE__,
      metadata: %{"amount_cents" => amount}
    })

    log_donation(user, rewards, donation)
    {:ok, donation}
  end

  defp failed_to_donate(%Account.User{id: user_id}, reason, error) do
    Logger.warning(
      "[Fund.Dormancy] auto-donation failed for user ##{user_id}: #{inspect(reason)}"
    )

    error
  end

  defp total_amount(rewards),
    do: Enum.reduce(rewards, 0, fn %{amount: amount}, acc -> acc + amount end)

  defp log_warning(%Account.User{id: user_id}, rewards, deadline) do
    Logger.info(
      "[Fund.Dormancy] warned user ##{user_id} about #{length(rewards)} dormant reward(s) " <>
        "totalling #{total_amount(rewards)} cents, donated on #{Date.to_string(deadline)} " <>
        "unless claimed"
    )
  end

  defp log_donation(%Account.User{id: user_id}, rewards, %Fund.DonationModel{
         uid: uid,
         amount_cents: amount
       }) do
    Logger.info(
      "[Fund.Dormancy] auto-donated #{amount} cents for user ##{user_id} as donation=#{uid}, " <>
        "reason: #{length(rewards)} reward(s) unclaimed after the dormancy warning"
    )
  end
end
