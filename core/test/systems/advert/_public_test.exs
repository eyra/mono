defmodule Systems.Advert.PublicTest do
  use Core.DataCase

  describe "assignments" do
    alias Systems.Advert
    alias Systems.Crew
    alias Systems.Bookkeeping
    alias Systems.Fund

    alias CoreWeb.UI.Timestamp
    alias Core.Factories

    setup do
      currency = Fund.Factories.create_currency("fake_currency", :legal, "ƒ", 2)
      fund = Fund.Factories.create_fund("test", currency)
      user = Factories.insert!(:member)
      {:ok, currency: currency, fund: fund, user: user}
    end

    test "mark_expired_debug?/0 should mark 1 expired task in online advert", %{
      fund: fund,
      user: user
    } do
      %{assignment: %{crew: crew}} = Advert.Factories.create_advert(user, :accepted, 1, fund)

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 0 expired tasks in submitted advert", %{
      fund: fund,
      user: user
    } do
      %{assignment: %{crew: crew}} = Advert.Factories.create_advert(user, :submitted, 1, fund)

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug()

      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in closed advert", %{
      fund: fund,
      user: user
    } do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{assignment: %{crew: crew}} =
        Advert.Factories.create_advert(user, :accepted, 1, fund, nil, schedule_end)

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in scheduled advert", %{
      fund: fund,
      user: user
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{assignment: %{crew: crew}} =
        Advert.Factories.create_advert(
          user,
          :accepted,
          1,
          fund,
          schedule_start,
          schedule_end
        )

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug(true)

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in submitted advert", %{
      fund: fund,
      user: user
    } do
      %{assignment: %{crew: crew}} = Advert.Factories.create_advert(user, :submitted, 1, fund)

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug(true)

      assert %{expired: false} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/1 should mark 1 expired tasks in closed advert", %{
      fund: fund,
      user: user
    } do
      schedule_end = yesterday() |> Timestamp.format_user_input_date()

      %{assignment: %{crew: crew}} =
        Advert.Factories.create_advert(user, :accepted, 1, fund, nil, schedule_end)

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug(true)

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "mark_expired_debug?/0 should mark 1 expired tasks in scheduled advert", %{
      fund: fund,
      user: user
    } do
      schedule_start = tomorrow() |> Timestamp.format_user_input_date()
      schedule_end = next_week() |> Timestamp.format_user_input_date()

      %{assignment: %{crew: crew}} =
        Advert.Factories.create_advert(
          user,
          :accepted,
          1,
          fund,
          schedule_start,
          schedule_end
        )

      task = Advert.Factories.create_task(["task1"], crew, :pending, false, 31)

      Advert.Public.mark_expired_debug()

      assert %{expired: true} = Crew.Public.get_task!(task.id)
    end

    test "payout_participant/2 One transaction of one participant", %{fund: fund, user: user} do
      participant = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew} = assignment} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      Advert.Factories.create_task(["task1"], participant, crew, :accepted, false, 31)
      Fund.Factories.create_reward(assignment, participant, fund)

      Advert.Public.payout_participant(assignment, participant)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant.id})
             ) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant.id})
    end

    test "payout_participant/2 Two transactions of one participant", %{fund: fund, user: user} do
      participant = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew1} = assignment1} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      %{assignment: %{crew: crew2} = assignment2} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      Advert.Factories.create_task(["task1"], participant, crew1, :accepted, false, 31)
      Advert.Factories.create_task(["task2"], participant, crew2, :accepted, false, 31)

      Fund.Factories.create_reward(assignment1, participant, fund)
      Fund.Factories.create_reward(assignment2, participant, fund)

      Advert.Public.payout_participant(assignment1, participant)
      Advert.Public.payout_participant(assignment2, participant)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant.id})
             ) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 2

      assert %{credit: 10_000, debit: 5004} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant.id})
    end

    test "payout_participant/2 Two transactions of two participants", %{
      fund: fund,
      user: user
    } do
      participant1 = Factories.insert!(:member, %{creator: false})
      participant2 = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew1} = assignment1} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      %{assignment: %{crew: crew2} = assignment2} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      Advert.Factories.create_task(["task1"], participant1, crew1, :accepted, false, 31)
      Advert.Factories.create_task(["task2"], participant1, crew2, :accepted, false, 31)
      Advert.Factories.create_task(["task3"], participant2, crew1, :accepted, false, 31)
      Advert.Factories.create_task(["task4"], participant2, crew2, :accepted, false, 31)

      Fund.Factories.create_reward(assignment1, participant1, fund)
      Fund.Factories.create_reward(assignment2, participant1, fund)
      Fund.Factories.create_reward(assignment1, participant2, fund)
      Fund.Factories.create_reward(assignment2, participant2, fund)

      Advert.Public.payout_participant(assignment1, participant1)
      Advert.Public.payout_participant(assignment2, participant1)
      Advert.Public.payout_participant(assignment1, participant2)
      Advert.Public.payout_participant(assignment2, participant2)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant1.id})
             ) ==
               2

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant2.id})
             ) ==
               2

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 4

      assert %{credit: 10_000, debit: 5008} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant1.id})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant2.id})
    end

    test "payout_participant/2 One transaction of one participant (via signals)", %{
      fund: fund,
      user: user
    } do
      participant = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew} = assignment} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      task = Advert.Factories.create_task(["task1"], participant, crew, :pending, false, 31)
      Fund.Factories.create_reward(assignment, participant, fund)

      # accept task should send signal to advert to reward participant
      Crew.Public.accept_task(task)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 1
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant.id})
             ) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 1

      assert %{credit: 10_000, debit: 5002} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant.id})
    end

    test "payout_participant/2 One transaction of one participant failed: task already accepted (via signals)",
         %{fund: fund, user: user} do
      participant = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew} = assignment} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      task = Advert.Factories.create_task(["task1"], participant, crew, :accepted, false, 31)
      Fund.Factories.create_reward(assignment, participant, fund)

      # accept task should send signal to advert to reward participant
      Crew.Public.accept_task(task)

      Bookkeeping.Public.list_accounts(["wallet"])

      assert Enum.empty?(Bookkeeping.Public.list_accounts(["wallet"]))

      assert Enum.empty?(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant.id})
             )
    end

    test "payout_participant/2 Multiple transactions of two participants (via signals)", %{
      fund: fund,
      user: user
    } do
      participant1 = Factories.insert!(:member, %{creator: false})
      participant2 = Factories.insert!(:member, %{creator: false})

      %{assignment: %{crew: crew1} = assignment1} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      %{assignment: %{crew: crew2} = assignment2} =
        Advert.Factories.create_advert(user, :accepted, 1, fund)

      task1 = Advert.Factories.create_task(["task1"], participant1, crew1, :pending, false, 31)
      task2 = Advert.Factories.create_task(["task2"], participant1, crew2, :pending, false, 31)
      task3 = Advert.Factories.create_task(["task3"], participant2, crew1, :pending, false, 31)
      _task4 = Advert.Factories.create_task(["task4"], participant2, crew2, :pending, false, 31)

      Fund.Factories.create_reward(assignment1, participant1, fund)
      Fund.Factories.create_reward(assignment2, participant1, fund)
      Fund.Factories.create_reward(assignment1, participant2, fund)
      Fund.Factories.create_reward(assignment2, participant2, fund)

      # accept task should send signal to advert to reward participant
      Crew.Public.accept_task(task1)
      Crew.Public.accept_task(task2)
      Crew.Public.accept_task(task3)

      assert Enum.count(Bookkeeping.Public.list_accounts(["wallet"])) == 2
      assert Enum.count(Bookkeeping.Public.list_accounts(["fund"])) == 1

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant1.id})
             ) ==
               2

      assert Enum.count(
               Bookkeeping.Public.list_entries({:wallet, "fake_currency", participant2.id})
             ) ==
               1

      assert Enum.count(Bookkeeping.Public.list_entries({:fund, "test"})) == 3

      assert %{credit: 10_000, debit: 5006} = Bookkeeping.Public.balance({:fund, "test"})

      assert %{credit: 4, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant1.id})

      assert %{credit: 2, debit: 0} =
               Bookkeeping.Public.balance({:wallet, "fake_currency", participant2.id})
    end

    defp yesterday() do
      Advert.Factories.timestamp(-24 * 60)
    end

    defp tomorrow() do
      Advert.Factories.timestamp(24 * 60)
    end

    defp next_week() do
      Advert.Factories.timestamp(7 * 24 * 60)
    end
  end

  describe "pool_visibility" do
    alias Systems.Advert
    alias Systems.Crew
    alias Systems.Fund
    alias Core.Factories

    setup do
      currency = Fund.Factories.create_currency("vis_currency", :legal, "ƒ", 2)
      user = Factories.insert!(:member)
      {:ok, currency: currency, user: user}
    end

    defp reload(advert), do: Advert.Public.get!(advert.id, Advert.Model.preload_graph(:down))

    defp online(advert) do
      advert |> Ecto.Changeset.change(status: :online) |> Core.Repo.update!()
      reload(advert)
    end

    defp empty_fund(advert) do
      advert.assignment.fund.available
      |> Ecto.Changeset.change(%{balance_credit: 0, balance_debit: 0})
      |> Core.Repo.update!()
    end

    test "is :invisible when the advert is not online", %{currency: currency, user: user} do
      fund = Fund.Factories.create_fund("draft", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund) |> reload()

      assert advert.status != :online
      assert Advert.Public.pool_visibility(advert) == nil
    end

    test "is :visible when online and the fund covers the reward", %{
      currency: currency,
      user: user
    } do
      fund = Fund.Factories.create_fund("funded", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund) |> online()

      assert Advert.Public.pool_visibility(advert) == :visible
    end

    test "is :not_funded when online and the fund is empty", %{currency: currency, user: user} do
      fund = Fund.Factories.create_fund("empty", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund) |> online()
      empty_fund(advert)

      assert Advert.Public.pool_visibility(reload(advert)) == :not_funded
    end

    test "is :visible for an online free study even with an empty fund", %{
      currency: currency,
      user: user
    } do
      fund = Fund.Factories.create_fund("free", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund) |> online()

      advert.submission
      |> Ecto.Changeset.change(%{reward_value: 0})
      |> Core.Repo.update!()

      empty_fund(advert)

      assert Advert.Public.pool_visibility(reload(advert)) == :visible
    end

    test "is :not_funded when online and funded but all spots are filled", %{
      currency: currency,
      user: user
    } do
      fund = Fund.Factories.create_fund("filled", currency)
      advert = Advert.Factories.create_advert(user, :accepted, 1, fund) |> online()

      # Fill the single subject slot, mimicking one completed participant.
      participant = Factories.insert!(:member)
      Crew.Factories.create_member(advert.assignment.crew, participant)

      assert Advert.Public.pool_visibility(reload(advert)) == :not_funded
    end
  end
end
