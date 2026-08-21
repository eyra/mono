defmodule Systems.Fund.Dormancy do
  @moduledoc """
  Auto-donation of dormant reward balances (SF-OPP-07).

  A participant who never claims an approved reward eventually has it donated to
  Eyra. Two passes, both driven by `Fund.AutoDonateWorker`:

    * `remind/2` warns a participant whose rewards have sat `:approved` since
      before the cutoff, and records the warning against each reward.
    * `donate/1` donates the rewards whose warning is older than the grace
      period.

  ## The clock is the warning, not the approval

  `donate/1` never looks at how long a reward has been approved — only at how
  long ago it was warned about. That is what makes the first run safe: a backlog
  of rewards approved years ago all get warned on day one and cannot be donated
  until a full grace period later. Worker downtime is covered the same way, and
  no participant can lose money without having been told first.

  ## Activity postpones on its own

  Every reward transition stamps `updated_at`, and a payout or donation attempt
  that fails reverts the reward to `:approved` with a fresh stamp. So a
  participant doing anything at all pushes their dormancy deadline out; the
  clock can only ever be delayed, never brought forward.

  Scoped to the euro balance, the only currency participants are ever paid in
  (see `Systems.Home.PageBuilder`) and the only one the provider charge is
  denominated in.
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
  it covers. Already-warned rewards are skipped, so re-running is harmless.

  Returns the rewards that were warned about.
  """
  def remind(%NaiveDateTime{} = cutoff, %Date{} = deadline) do
    warned = warned_reward_ids()

    cutoff
    |> dormant_rewards()
    |> Enum.reject(&warned?(&1, warned))
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

  # No age filter here on purpose: how long a reward has been approved is the
  # warning pass's business, and re-applying it would let a reward that was
  # warned about slip back out of reach.
  defp warned_rewards(cutoff) do
    warned = warned_reward_ids(recorded_before: cutoff)

    @currency
    |> Fund.Queries.approved_rewards()
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.filter(&warned?(&1, warned))
  end

  # The warning event *is* the durable mark: it names the rewards it covered,
  # so one event per participant carries one mail and however many marks.
  defp warned_reward_ids(opts \\ []) do
    @warning
    |> Notify.Public.list_events(opts)
    |> Enum.flat_map(&covered_reward_ids/1)
    |> MapSet.new()
  end

  defp covered_reward_ids(%Notify.EventModel{metadata: %{"reward_ids" => ids}}), do: ids
  defp covered_reward_ids(%Notify.EventModel{}), do: []

  defp participant(%Fund.RewardModel{user: user}), do: user

  defp warned?(%Fund.RewardModel{id: id}, warned), do: MapSet.member?(warned, id)

  defp warn_participant({user, rewards}, deadline) do
    Notify.Public.record_event(%Notify.EventAttrs{
      type: @warning,
      subject_user: user,
      correlation_id: "fund_dormancy:user:#{user.id}",
      source: __MODULE__,
      metadata: %{
        "reward_ids" => Enum.map(rewards, & &1.id),
        "amount_cents" => total_amount(rewards),
        "deadline" => Date.to_string(deadline)
      }
    })

    log_warning(user, rewards, deadline)
    rewards
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
