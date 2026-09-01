defmodule Systems.Fund.DormancyTest do
  use Core.DataCase
  use Bamboo.Test

  import Ecto.Query
  import Mox

  alias Core.Factories
  alias Systems.Fund
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  setup do
    euro = Fund.Factories.create_currency("euro", :legal, "€", 2)
    fund = Fund.Factories.create_fund("euro-fund-#{unique()}", euro)
    {:ok, fund: fund, donor: Factories.insert!(:member, %{creator: false})}
  end

  defp unique, do: System.unique_integer([:positive])

  defp insert_reward(user, fund, amount, status \\ :approved) do
    Factories.insert!(:reward, %{
      user: user,
      fund: fund,
      amount: amount,
      status: status,
      idempotence_key: "dormancy-#{status}-#{amount}-#{unique()}"
    })
  end

  defp touch(reward), do: stamp(reward, NaiveDateTime.utc_now())

  defp backdate(reward, days_ago),
    do:
      stamp(reward, NaiveDateTime.add(NaiveDateTime.utc_now(), -days_ago * 24 * 60 * 60, :second))

  defp stamp(%Fund.RewardModel{id: id} = reward, %NaiveDateTime{} = timestamp) do
    from(r in Fund.RewardModel, where: r.id == ^id)
    |> Repo.update_all(set: [updated_at: NaiveDateTime.truncate(timestamp, :second)])

    reward
  end

  defp past, do: NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :day)
  defp future, do: NaiveDateTime.add(NaiveDateTime.utc_now(), 1, :day)
  defp deadline, do: Date.add(Date.utc_today(), 30)

  defp age_warnings(days_ago) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> NaiveDateTime.truncate(:second)

    Repo.update_all(Systems.Notify.EventModel, set: [inserted_at: timestamp])
  end

  defp stub_partner_charge_ok(amount) do
    expect(ProviderMock, :charge_to_partner, fn _from, ^amount, _key ->
      {:ok, %{uid: "chg_dormant_#{unique()}", status: :pending, raw_status: "created", amount: 0}}
    end)
  end

  describe "remind/2" do
    test "warns the participant once and covers every dormant reward in one mail",
         %{donor: donor, fund: fund} do
      r1 = insert_reward(donor, fund, 600)
      r2 = insert_reward(donor, fund, 400)

      assert [_, _] = Fund.Dormancy.remind(future(), deadline())

      assert_email_delivered_with(
        to: [{nil, donor.email}],
        subject: "Your unclaimed reward expires soon"
      )

      # Re-running finds nothing left to warn about.
      assert [] = Fund.Dormancy.remind(future(), deadline())

      assert %{status: :approved} = Repo.reload!(r1)
      assert %{status: :approved} = Repo.reload!(r2)
    end

    test "leaves rewards touched after the cutoff alone", %{donor: donor, fund: fund} do
      insert_reward(donor, fund, 600)

      assert [] = Fund.Dormancy.remind(past(), deadline())
      assert_no_emails_delivered()
    end

    test "ignores rewards that are not approved", %{donor: donor, fund: fund} do
      insert_reward(donor, fund, 600, :pending_approval)
      insert_reward(donor, fund, 700, :paid)

      assert [] = Fund.Dormancy.remind(future(), deadline())
    end
  end

  describe "donate/1" do
    test "does not donate a reward whose warning is younger than the notice period",
         %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())

      # Warned just now, so nothing has aged past a cutoff in the past.
      assert [] = Fund.Dormancy.donate(past())
      assert %{status: :approved} = Repo.reload!(reward)
    end

    test "never donates a reward that was never warned about", %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)

      assert [] = Fund.Dormancy.donate(future())
      assert %{status: :approved} = Repo.reload!(reward)
    end

    test "donates the warned balance once the notice period has passed",
         %{donor: donor, fund: fund} do
      r1 = insert_reward(donor, fund, 600)
      r2 = insert_reward(donor, fund, 400)
      Fund.Dormancy.remind(future(), deadline())
      assert_email_delivered_with(subject: "Your unclaimed reward expires soon")
      stub_partner_charge_ok(1000)

      assert [{:ok, %Fund.DonationModel{amount_cents: 1000}}] = Fund.Dormancy.donate(future())

      assert %{status: :donated} = Repo.reload!(r1)
      assert %{status: :donated} = Repo.reload!(r2)

      assert_email_delivered_with(
        to: [{nil, donor.email}],
        subject: "Your reward has been donated"
      )
    end

    test "is idempotent: a second sweep finds nothing to donate",
         %{donor: donor, fund: fund} do
      insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())
      stub_partner_charge_ok(600)

      assert [{:ok, _}] = Fund.Dormancy.donate(future())
      assert [] = Fund.Dormancy.donate(future())
    end

    test "leaves the rewards claimable when the provider rejects the charge",
         %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())

      expect(ProviderMock, :charge_to_partner, fn _from, _amount, _key ->
        {:error,
         %Systems.Payment.Error{code: :api_error, message: "nope", details: %{status: 400}}}
      end)

      assert [{:error, _}] = Fund.Dormancy.donate(future())
      assert %{status: :approved} = Repo.reload!(reward)
    end

    test "does not retry a rejected charge on the next sweep",
         %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())
      backdate(reward, 2)
      age_warnings(1)

      expect(ProviderMock, :charge_to_partner, fn _from, _amount, _key ->
        {:error,
         %Systems.Payment.Error{code: :api_error, message: "nope", details: %{status: 400}}}
      end)

      assert [{:error, _}] = Fund.Dormancy.donate(future())
      assert [] = Fund.Dormancy.donate(future())
    end

    test "does not donate a reward touched after its warning", %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())
      backdate(reward, 2)
      age_warnings(1)
      touch(reward)

      assert [] = Fund.Dormancy.donate(future())
      assert %{status: :approved} = Repo.reload!(reward)
    end
  end

  describe "remind/2 after activity" do
    test "warns again once a touched reward has gone dormant anew",
         %{donor: donor, fund: fund} do
      reward = insert_reward(donor, fund, 600)
      Fund.Dormancy.remind(future(), deadline())
      assert_email_delivered_with(subject: "Your unclaimed reward expires soon")
      backdate(reward, 2)
      age_warnings(1)
      touch(reward)

      assert [%{id: id}] = Fund.Dormancy.remind(future(), deadline())
      assert id == reward.id
      assert_email_delivered_with(subject: "Your unclaimed reward expires soon")
    end
  end
end
