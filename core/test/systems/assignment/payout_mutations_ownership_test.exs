defmodule Systems.Assignment.PayoutMutationsOwnershipTest do
  @moduledoc """
  Regression: FX#9919395084.

  Payout-related mutations (bulk approve, decline) must live on the
  auth-gated parent `ParticipantsView`, not on the child `PayoutModal`.
  Today the modal is only composed from ParticipantsView so mutations are
  gated in practice, but by construction the modal owns no auth check —
  composing it elsewhere would expose the mutations.

  These tests pin the handler location:
  - the parent's handlers actually mutate,
  - the child's don't (it may still render buttons, but a direct
    handle_event/3 invocation on the modal must not perform the mutation).
  """
  use Core.DataCase, async: false

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Assignment.ParticipantsView
  alias Systems.Assignment.PayoutModal
  alias Systems.Crew
  alias Systems.Fund

  defp setup_pending_approval do
    assignment = Assignment.Factories.create_questionnaire_assignment()

    currency = Fund.Factories.create_currency("eur_p4", :legal, "€", 2)
    fund = Fund.Factories.create_fund("fund_p4_#{assignment.id}", currency)

    {:ok, _} =
      assignment
      |> Assignment.Model.changeset(fund)
      |> Core.Repo.update()

    assignment = Core.Repo.preload(assignment, [:crew, :workflow], force: true)

    participant = Factories.insert!(:member, %{creator: false})

    [workflow_item | _] =
      assignment.workflow |> Core.Repo.preload(:items) |> Map.fetch!(:items)

    member = Crew.Factories.create_member(assignment.crew, participant)
    identifier = ["item=#{workflow_item.id}", "member=#{member.id}"]
    task = Crew.Factories.create_task(assignment.crew, member, identifier, status: :completed)

    # Create the reward through Fund.Public so the accompanying deposit exists
    # — reject_task rolls back the deposit as part of an atomic multi, so
    # without one the whole reject fails and the task stays :completed.
    idempotence_key = "assignment=#{assignment.id},user=#{participant.id}"

    {:ok, %{reward: reward}} =
      Fund.Public.create_reward(
        Core.Repo.preload(fund, [:available, :pending, :currency]),
        1000,
        participant,
        idempotence_key
      )

    reward =
      reward
      |> Ecto.Changeset.change(%{status: :pending_approval})
      |> Core.Repo.update!()

    assignment =
      Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

    %{assignment: assignment, task: task, reward: reward}
  end

  defp parent_socket(assignment) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        assignment: assignment,
        fabric: Fabric.Factories.create_fabric()
      }
    }
  end

  # Modal shim's `send_event(:parent, ...)` walks fabric.parent; supply a
  # valid ref (test process) so the shim doesn't raise before we can assert
  # its no-mutation behavior.
  defp modal_fabric do
    parent_ref = %Fabric.LiveView.RefModel{pid: self()}
    self_ref = %Fabric.LiveView.RefModel{pid: self()}
    %Fabric.Model{parent: parent_ref, self: self_ref, children: nil}
  end

  defp modal_socket(assignment) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        assignment_id: assignment.id,
        vm: %{assignment: assignment},
        active_tab: :waiting,
        declining_task_id: nil,
        decline_reason: "",
        search_query: "",
        error: nil,
        fabric: modal_fabric()
      }
    }
  end

  describe "ParticipantsView owns the mutations" do
    test "pay_out_all approves the pending reward" do
      %{assignment: assignment, reward: reward} = setup_pending_approval()

      {:noreply, _socket} =
        ParticipantsView.handle_event("pay_out_all", %{}, parent_socket(assignment))

      assert Core.Repo.reload(reward).status == :approved
    end

    test "submit_decline rejects the identified task" do
      %{assignment: assignment, task: task} = setup_pending_approval()

      {:noreply, _socket} =
        ParticipantsView.handle_event(
          "submit_decline",
          %{task_id: task.id, reason: "n/a"},
          parent_socket(assignment)
        )

      assert %{status: :rejected} = Crew.Public.get_task!(task.id)
    end
  end

  describe "PayoutModal does not own the mutations" do
    test "handle_event(\"pay_out_all\", ...) does not mutate" do
      %{assignment: assignment, reward: reward} = setup_pending_approval()

      {:noreply, _socket} =
        PayoutModal.handle_event("pay_out_all", %{}, modal_socket(assignment))

      assert Core.Repo.reload(reward).status == :pending_approval
    end

    test "handle_event(\"submit_decline\", ...) does not mutate" do
      %{assignment: assignment, task: task} = setup_pending_approval()

      socket = %{
        modal_socket(assignment)
        | assigns:
            modal_socket(assignment).assigns
            |> Map.put(:declining_task_id, task.id)
            |> Map.put(:decline_reason, "n/a")
      }

      {:noreply, _socket} = PayoutModal.handle_event("submit_decline", %{}, socket)

      assert %{status: :completed} = Crew.Public.get_task!(task.id)
    end
  end
end
