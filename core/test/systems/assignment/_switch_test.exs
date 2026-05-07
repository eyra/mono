defmodule Systems.Assignment.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Assignment
  alias Systems.Assignment.Switch

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

    test "crew_task accepted", %{user: user, crew: crew, crew_task: crew_task} do
      message = %{
        crew: crew,
        crew_task: crew_task,
        from_pid: self(),
        changeset: %{data: %{status: :pending}}
      }

      assert :ok = Switch.intercept({:crew_task, :accepted}, message)
      refute_signal_dispatched({:assignment, :monitor_event})
      assert_signal_dispatched({:page, Systems.Assignment.ContentPage})
      message = assert_signal_dispatched({:page, Systems.Assignment.CrewPage})
      assert message.user_id == user.id

      # Verify embedded views are updated
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.OnboardingConsentView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.CrewWorkView})
      assert_signal_dispatched({:embedded_live_view, Systems.Assignment.FinishedView})
    end

    test "crew_task rejected", %{user: user, crew: crew, crew_task: crew_task} do
      message = %{crew: crew, crew_task: crew_task, from_pid: self()}
      assert :ok = Switch.intercept({:crew_task, :rejected}, message)
      refute_signal_dispatched({:assignment, :monitor_event})
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
end
