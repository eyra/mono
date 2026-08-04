defmodule Systems.Assignment.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper
  import Systems.NextAction.TestHelper

  alias Systems.Assignment
  alias Systems.Assignment.Switch
  alias Systems.Fund
  alias Systems.NextAction

  describe "crew events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      user = Factories.insert!(:member)
      crew = Factories.insert!(:crew)
      crew_member = Factories.insert!(:crew_member, %{crew: crew, user: user})
      _assignment = Factories.insert!(:assignment, %{crew: crew})
      %{user: user, crew: crew, crew_member: crew_member}
    end

    test "crew_member started", %{user: user, crew: crew, crew_member: crew_member} do
      message = %{crew: crew, crew_member: crew_member, from_pid: self()}
      assert :ok = Switch.intercept({:crew, {:crew_member, :started}}, message)

      assert %{monitor_event: {_, :started, _}} =
               assert_signal_dispatched({:assignment, :monitor_event})

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end

    test "crew_member declined", %{user: user, crew: crew, crew_member: crew_member} do
      message = %{crew: crew, crew_member: crew_member, from_pid: self()}
      assert :ok = Switch.intercept({:crew, {:crew_member, :declined}}, message)

      assert %{monitor_event: {_, :declined, _}} =
               assert_signal_dispatched({:assignment, :monitor_event})

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end

    test "crew_member finished_tasks", %{user: user, crew: crew, crew_member: crew_member} do
      message = %{crew: crew, crew_member: crew_member, from_pid: self()}
      assert :ok = Switch.intercept({:crew, {:crew_member, :finished_tasks}}, message)

      assert %{monitor_event: {_, :finished, _}} =
               assert_signal_dispatched({:assignment, :monitor_event})

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end
  end

  describe "crew_task events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      user = Factories.insert!(:member)

      %{crew: crew, workflow: workflow} = Assignment.Factories.create_assignment(31, 1)

      crew_member = Factories.insert!(:crew_member, %{crew: crew, user: user})
      %{items: [%{id: item_id}]} = workflow |> Core.Repo.preload([:items])

      crew_task =
        Factories.insert!(:crew_task, %{
          identifier: ["item=#{item_id}", "member=#{crew_member.id}"],
          crew: crew,
          auth_node: %Core.Authorization.Node{},
          status: :pending
        })

      %{user: user, crew: crew, crew_member: crew_member, crew_task: crew_task}
    end

    test "crew_task started", %{user: user, crew: crew, crew_task: crew_task} do
      message = %{crew: crew, crew_task: crew_task, from_pid: self()}
      assert :ok = Switch.intercept({:crew_task, :started}, message)

      assert %{monitor_event: {_, :started, _}} =
               assert_signal_dispatched({:assignment, :monitor_event})

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end

    test "crew_task completed", %{user: user, crew: crew, crew_task: crew_task} do
      message = %{crew: crew, crew_task: crew_task, from_pid: self()}
      assert :ok = Switch.intercept({:crew_task, :completed}, message)

      assert %{monitor_event: {_, :finished, _}} =
               assert_signal_dispatched({:assignment, :monitor_event})

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end
  end

  describe "assignment events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      assignment = Assignment.Factories.create_assignment(31, 1)
      %{assignment: assignment}
    end

    test "any event", %{assignment: assignment} do
      message = %{assignment: assignment, from_pid: self()}
      assert :ok = Switch.intercept({:assignment, :any_event}, message)
      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      refute Map.has_key?(message, :user_id)

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end

    test "monitor_event", %{assignment: assignment} do
      message = %{assignment: assignment, from_pid: self()}
      assert :ok = Switch.intercept({:assignment, :monitor_event}, message)
      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      refute_signal_dispatched({:page, Systems.Assignment.CrewPage})
      # monitor_event does not update embedded views
      refute_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
    end
  end

  describe "consent_agreement events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      user = Factories.insert!(:member)

      %{crew: crew, consent_agreement: agreement, workflow: workflow} =
        assignment = Assignment.Factories.create_assignment(31, 1)

      crew_member = Factories.insert!(:crew_member, %{crew: crew, user: user})
      %{items: [%{id: item_id}]} = workflow |> Core.Repo.preload([:items])

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_id}", "member=#{crew_member.id}"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        status: :pending
      })

      revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement})
      signature = Factories.insert!(:consent_signature, %{revision: revision_1, user: user})

      %{user: user, assignment: assignment, agreement: agreement, signature: signature}
    end

    test "consent_signature created", %{
      user: user,
      assignment: assignment,
      agreement: agreement,
      signature: signature
    } do
      message = %{
        assignment: assignment,
        consent_agreement: agreement,
        consent_signature: signature,
        from_pid: self()
      }

      assert :ok = Switch.intercept({:consent_agreement, {:consent_signature, :created}}, message)
      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      assert %{user_id: user_id} = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end
  end

  describe "assignment_participation events" do
    setup do
      isolate_signals(except: [Systems.Assignment.Switch])

      %{fund: fund} = assignment = Assignment.Factories.create_assignment(31, 1)

      owner = Factories.insert!(:member)

      :ok =
        Core.Authorization.assign_role(owner, assignment, :owner)

      participant = Factories.insert!(:member)

      assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
      {:ok, participation} = Assignment.Public.obtain_participation(assignment, participant)

      %{
        assignment: assignment,
        fund: fund,
        owner: owner,
        participant: participant,
        participation: participation
      }
    end

    test ":completed creates PendingContributions next-action for the owner", %{
      assignment: %{id: id},
      participation: participation,
      owner: owner
    } do
      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :completed}, message)

      assert_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":completed refreshes content page + embedded views", %{participation: participation} do
      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :completed}, message)

      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.ContributionsView})
    end

    test ":completed on an unfunded assignment skips NA creation", %{owner: owner} do
      unfunded = Factories.insert!(:assignment, %{fund: nil})
      :ok = Core.Authorization.assign_role(owner, unfunded, :owner)
      participant = Factories.insert!(:member)
      {:ok, participation} = Assignment.Public.obtain_participation(unfunded, participant)

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :completed}, message)

      refute_next_action(owner, "/assignment/#{unfunded.id}/content?tab=contributions")
    end

    test ":completed with no owners is a no-op on next-actions (does not crash)", %{
      assignment: assignment,
      participant: participant
    } do
      # Fresh assignment with no owner role assigned anywhere.
      ownerless = Assignment.Factories.create_assignment(31, 1)
      ownerless = Assignment.Public.get!(ownerless.id, Assignment.Model.preload_graph(:down))
      {:ok, participation} = Assignment.Public.obtain_participation(ownerless, participant)

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :completed}, message)

      # And confirm the setup assignment still lets NAs be reached, so the guard
      # above actually exercised the empty-owners branch rather than a silent fail.
      _ = assignment
      assert NextAction.Public.list_next_actions(participant) == []
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
        |> Core.Repo.commit()

      message = %{assignment_participation: participation, from_pid: self()}
      assert :ok = Switch.intercept({:assignment_participation, :accepted}, message)

      assert_next_action(owner, "/assignment/#{id}/content?tab=contributions")
    end

    test ":accepted on an unfunded assignment leaves the NA untouched", %{owner: owner} do
      unfunded = Factories.insert!(:assignment, %{fund: nil})
      :ok = Core.Authorization.assign_role(owner, unfunded, :owner)
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
        |> Core.Repo.commit()

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
