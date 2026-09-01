defmodule Systems.Fund.AutoDonateWorkerTest do
  use Core.DataCase
  use Oban.Testing, repo: Core.Repo
  use Bamboo.Test

  import Ecto.Query
  import Mox

  alias Core.Factories
  alias Core.Repo
  alias Systems.Fund
  alias Systems.Fund.AutoDonateWorker
  alias Systems.Payment.ProviderMock

  @dormant_days 180
  @notice_days 30

  setup :verify_on_exit!

  setup do
    euro = Fund.Factories.create_currency("euro", :legal, "€", 2)
    fund = Fund.Factories.create_fund("euro-fund-#{unique()}", euro)
    {:ok, fund: fund, donor: Factories.insert!(:member, %{creator: false})}
  end

  defp unique, do: System.unique_integer([:positive])

  defp insert_reward(user, fund, amount) do
    Factories.insert!(:reward, %{
      user: user,
      fund: fund,
      amount: amount,
      status: :approved,
      idempotence_key: "auto-donate-#{amount}-#{unique()}"
    })
  end

  defp backdate(%Fund.RewardModel{id: id} = reward, days_ago) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> NaiveDateTime.truncate(:second)

    from(r in Fund.RewardModel, where: r.id == ^id)
    |> Repo.update_all(set: [updated_at: timestamp])

    reward
  end

  defp age_warnings(days_ago) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> NaiveDateTime.truncate(:second)

    Repo.update_all(Systems.Notify.EventModel, set: [inserted_at: timestamp])
  end

  defp run, do: perform_job(AutoDonateWorker, %{})

  test "warns a dormant balance without donating it", %{donor: donor, fund: fund} do
    reward = insert_reward(donor, fund, 1000) |> backdate(@dormant_days - @notice_days + 1)

    assert :ok = run()

    assert_email_delivered_with(to: [{nil, donor.email}])
    assert %{status: :approved} = Repo.reload!(reward)
  end

  test "leaves a balance younger than the warning line alone", %{donor: donor, fund: fund} do
    reward = insert_reward(donor, fund, 1000) |> backdate(@dormant_days - @notice_days - 1)

    assert :ok = run()

    assert_no_emails_delivered()
    assert %{status: :approved} = Repo.reload!(reward)
  end

  test "donates once the warning has aged past the notice period",
       %{donor: donor, fund: fund} do
    reward = insert_reward(donor, fund, 1000) |> backdate(@dormant_days)

    assert :ok = run()
    assert %{status: :approved} = Repo.reload!(reward)

    age_warnings(@notice_days + 1)

    expect(ProviderMock, :charge_to_partner, fn _from, 1000, _key ->
      {:ok, %{uid: "chg_auto", status: :pending, raw_status: "created", amount: 1000}}
    end)

    assert :ok = run()
    assert %{status: :donated} = Repo.reload!(reward)
  end

  test "does not donate on the deadline date named in the warning",
       %{donor: donor, fund: fund} do
    reward = insert_reward(donor, fund, 1000) |> backdate(@dormant_days)

    assert :ok = run()
    age_warnings(@notice_days)

    assert :ok = run()
    assert %{status: :approved} = Repo.reload!(reward)
  end

  test "a backlog approved long ago still gets a full notice period first",
       %{donor: donor, fund: fund} do
    reward = insert_reward(donor, fund, 1000) |> backdate(10 * 365)

    assert :ok = run()
    assert %{status: :approved} = Repo.reload!(reward)
  end
end
