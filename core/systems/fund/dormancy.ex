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
  use Gettext, backend: CoreWeb.Gettext

  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Email
  alias Systems.Fund
  alias Systems.Notification

  @currency "euro"
  @signal :fund_dormancy_warning

  @doc """
  Warns every participant holding rewards untouched since before `cutoff`, and
  marks those rewards as warned. One mail per participant, however many rewards
  it covers. Already-warned rewards are skipped, so re-running is harmless.

  Returns the rewards that were warned about.
  """
  def remind(%NaiveDateTime{} = cutoff, %Date{} = deadline) do
    cutoff
    |> dormant_rewards()
    |> Enum.reject(&warned?/1)
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
  #
  # ponytail: the warned set is filtered in Elixir rather than joined against
  # the notification log, which belongs to another system. Fine for a daily
  # sweep over the approved balance; push it into the query if that grows.
  defp warned_rewards(cutoff) do
    @currency
    |> Fund.Queries.approved_rewards()
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.filter(&warned_before?(&1, cutoff))
  end

  defp participant(%Fund.RewardModel{user: user}), do: user

  defp warned?(%Fund.RewardModel{} = reward),
    do: Notification.Public.marked_as_notified?(reward, @signal)

  defp warned_before?(%Fund.RewardModel{} = reward, cutoff),
    do: Notification.Public.notified_before?(reward, @signal, cutoff)

  # Mail first, mark second: a lost mark costs a duplicate reminder, while a
  # mark without a mail would start the donation clock on a silent warning.
  defp warn_participant({user, rewards}, deadline) do
    rewards
    |> total_amount()
    |> warning_mail(user, deadline)
    |> Email.Public.deliver_later!()

    Enum.each(rewards, &mark_warned/1)
    log_warning(user, rewards, deadline)
    rewards
  end

  defp mark_warned(%Fund.RewardModel{} = reward),
    do: Notification.Public.mark_as_notified(reward, @signal)

  defp donate_balance({user, rewards}) do
    case Fund.Public.donate_rewards(user, rewards) do
      {:ok, donation} -> donated(user, rewards, donation)
      {:error, reason} = error -> failed_to_donate(user, reason, error)
    end
  end

  defp donated(user, rewards, %Fund.DonationModel{} = donation) do
    donation
    |> donated_mail(user)
    |> Email.Public.deliver_later!()

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

  defp warning_mail(amount, user, deadline) do
    Email.Factory.notification(
      dgettext("eyra-fund", "dormancy.warning.title"),
      dgettext("eyra-fund", "dormancy.warning.byline", amount: format(amount)),
      dgettext("eyra-fund", "dormancy.warning.message",
        amount: format(amount),
        date: Date.to_string(deadline)
      ),
      user
    )
  end

  defp donated_mail(%Fund.DonationModel{amount_cents: amount}, user) do
    Email.Factory.notification(
      dgettext("eyra-fund", "dormancy.donated.title"),
      dgettext("eyra-fund", "dormancy.donated.byline", amount: format(amount)),
      dgettext("eyra-fund", "dormancy.donated.message", amount: format(amount)),
      user
    )
  end

  defp format(amount), do: CurrencyHelpers.format_cents(amount)

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
