defmodule MicaSaas.Systems.Assignment.SwitchTest do
  use Mica.DataCase
  import Frameworks.Signal.TestHelper
  import Systems.NextAction.TestHelper

  alias Systems.Assignment
  alias Systems.Assignment.Switch
  alias Systems.Fund
  alias Systems.NextAction

  describe "assignment_participation events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      Systems.Assignment.TestHelper.owned_participation()
    end

    test ":completed creates PendingContributions next-action when the fund has pay-ins", %{
      assignment: %{id: id},
      fund: fund,
      participation: participation,
      owner: owner
    } do
      Fund.Factories.insert_pay_in!(fund, owner)

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :completed}, message)

      assert_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":accepted clears the NA when no other contributions are pending", %{
      assignment: %{id: id} = assignment,
      participation: participation,
      owner: owner
    } do
      seed_pending_contributions_na(assignment, owner)

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :accepted}, message)

      refute_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":accepted keeps the NA when another participant is still pending", %{
      assignment: %{id: id, fund: fund} = assignment,
      participation: participation,
      owner: owner
    } do
      seed_pending_contributions_na(assignment, owner)
      other = Factories.insert!(:member)
      other_key = Assignment.Private.reward_idempotence_key(assignment, other)
      {:ok, _} = Fund.Public.create_reward(fund, 500, other, other_key)
      other_reward = Fund.Public.get_reward(other_key, Fund.RewardModel.preload_graph(:full))

      {:ok, _} =
        Ecto.Multi.new()
        |> Fund.Public.mark_pending_approval(other_reward)
        |> Mica.Repo.commit()

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :accepted}, message)

      assert_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":accepted on an unfunded assignment leaves the NA untouched", %{owner: owner} do
      unfunded = Factories.insert!(:assignment, %{fund: nil})
      :ok = Mica.Authorization.assign_role(owner, unfunded, :owner)
      participant = Factories.insert!(:member)
      {:ok, participation} = Assignment.Public.obtain_participation(unfunded, participant)

      NextAction.Public.create_next_action(
        [owner],
        Systems.Assignment.NextActions.PendingContributions,
        key: "#{unfunded.id}",
        params: %{"assignment_id" => unfunded.id}
      )

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :accepted}, message)

      assert_next_action(owner, "/assignment/#{unfunded.id}/content?tab=contributions")
    end

    test ":rejected clears the NA when no other contributions are pending", %{
      assignment: %{id: id} = assignment,
      participation: participation,
      owner: owner
    } do
      seed_pending_contributions_na(assignment, owner)

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :rejected}, message)

      refute_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":rejected keeps the NA when another participant is still pending", %{
      assignment: %{id: id, fund: fund} = assignment,
      participation: participation,
      owner: owner
    } do
      seed_pending_contributions_na(assignment, owner)
      other = Factories.insert!(:member)
      other_key = Assignment.Private.reward_idempotence_key(assignment, other)
      {:ok, _} = Fund.Public.create_reward(fund, 500, other, other_key)
      other_reward = Fund.Public.get_reward(other_key, Fund.RewardModel.preload_graph(:full))

      {:ok, _} =
        Ecto.Multi.new()
        |> Fund.Public.mark_pending_approval(other_reward)
        |> Mica.Repo.commit()

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :rejected}, message)

      assert_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end
  end

  defp seed_pending_contributions_na(%{id: assignment_id}, owner) do
    NextAction.Public.create_next_action(
      [owner],
      Systems.Assignment.NextActions.PendingContributions,
      key: "#{assignment_id}",
      params: %{"assignment_id" => assignment_id}
    )
  end
end
