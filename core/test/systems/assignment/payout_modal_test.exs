defmodule Systems.Assignment.PayoutModalTest.Host do
  @moduledoc """
  Stand-in for the auth-gated parent (`Systems.Assignment.ParticipantsView`),
  so `PayoutModal` can be driven in isolation.

  It deliberately performs no mutation — it only replies with the result the
  test asked for, which is exactly the contract the real parent has with the
  modal: the modal bubbles up, the parent mutates, the parent signals back.
  """
  use CoreWeb, :live_view

  alias Systems.Assignment

  @impl true
  def mount(_params, session, socket) do
    self_ref = %Fabric.LiveView.RefModel{pid: self()}

    {
      :ok,
      socket
      |> assign(fabric: %Fabric.Model{parent: nil, self: self_ref, children: nil})
      |> assign(assignment_id: session["assignment_id"])
      |> assign(parent_result: session["parent_result"] || "ok")
      |> compose_child(:payout_modal)
    }
  end

  @impl true
  def compose(:payout_modal, %{assignment_id: assignment_id}) do
    %{
      module: Assignment.PayoutModal,
      params: %{assignment_id: assignment_id}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.child name={:payout_modal} fabric={@fabric} />
    </div>
    """
  end

  @impl true
  def handle_event("pay_out_all", _, socket) do
    {:noreply, send_event(socket, :payout_modal, "post_pay_out_all", %{result: result(socket)})}
  end

  @impl true
  def handle_event("submit_decline", _, socket) do
    {:noreply,
     send_event(socket, :payout_modal, "post_submit_decline", %{result: result(socket)})}
  end

  @impl true
  def handle_event(_name, _payload, socket), do: {:noreply, socket}

  defp result(%{assigns: %{parent_result: "error"}}), do: {:error, :boom}
  defp result(_), do: {:ok, 1}
end

defmodule Systems.Assignment.PayoutModalTest do
  @moduledoc """
  Rendering + local UI state of `Systems.Assignment.PayoutModal`.

  The modal owns no mutations (see `PayoutMutationsOwnershipTest`), so what is
  worth pinning here is what it *does* own: which tab is showing, whether a
  row's decline form is expanded, and whether the error banner reflects the
  result the parent signalled back.
  """
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Core.Repo
  alias Systems.Assignment
  alias Systems.Assignment.PayoutModalTest.Host
  alias Systems.Crew
  alias Systems.Fund

  setup %{conn: conn} do
    {:ok, conn: Map.put(conn, :request_path, "/assignment/payout-modal-test")}
  end

  describe "tabs" do
    test "opens on the waiting tab", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='payout-modal']")
      assert has_element?(view, "[data-testid='payout-waiting-tab']")
      refute has_element?(view, "[data-testid='payout-overview-tab']")
    end

    test "switches to the overview tab", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='payout-tab-overview']") |> render_click()

      assert has_element?(view, "[data-testid='payout-overview-tab']")
      refute has_element?(view, "[data-testid='payout-waiting-tab']")
    end

    test "switches back to the waiting tab", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='payout-tab-overview']") |> render_click()
      view |> element("[data-testid='payout-tab-waiting']") |> render_click()

      assert has_element?(view, "[data-testid='payout-waiting-tab']")
    end
  end

  describe "waiting tab" do
    test "lists a row per pending payout", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='payout-row-#{task.id}']")
      assert has_element?(view, "[data-testid='payout-waiting-count']", "1")
      refute has_element?(view, "[data-testid='payout-empty']")
    end

    test "shows the empty state when nothing is awaiting approval", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval(reward_status: :approved)
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='payout-empty']")
      assert has_element?(view, "[data-testid='payout-waiting-count']", "0")
    end

    test "disables Pay out all when nothing is awaiting approval", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval(reward_status: :approved)
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='pay-out-all-button'][disabled]")
    end

    test "enables Pay out all while approvals are waiting", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='pay-out-all-button']")
      refute has_element?(view, "[data-testid='pay-out-all-button'][disabled]")
    end
  end

  describe "overview tab" do
    test "shows the empty state when nothing has been paid yet", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='payout-tab-overview']") |> render_click()

      assert has_element?(view, "[data-testid='payout-overview-empty']")
      assert has_element?(view, "[data-testid='payout-overview-count']", "0")
    end

    test "lists a row per paid reward", %{conn: conn} do
      %{assignment: assignment, reward: reward} = setup_pending_approval(reward_status: :paid)
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='payout-tab-overview']") |> render_click()

      assert has_element?(view, "[data-testid='payout-overview-row-#{reward.id}']")
      assert has_element?(view, "[data-testid='payout-overview-amount-#{reward.id}']")
      assert has_element?(view, "[data-testid='payout-overview-count']", "1")
    end
  end

  describe "decline flow" do
    test "is collapsed until the row's decline link is clicked", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      assert has_element?(view, "[data-testid='decline-#{task.id}']")
      refute has_element?(view, "[data-testid='decline-reason-#{task.id}']")
    end

    test "expands the reason form for the clicked row", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='decline-#{task.id}']") |> render_click()

      assert has_element?(view, "[data-testid='decline-reason-#{task.id}']")
      assert has_element?(view, "[data-testid='cancel-decline-#{task.id}']")
      refute has_element?(view, "[data-testid='decline-#{task.id}']")
    end

    test "collapses the reason form again on cancel", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='decline-#{task.id}']") |> render_click()
      view |> element("[data-testid='cancel-decline-#{task.id}']") |> render_click()

      refute has_element?(view, "[data-testid='decline-reason-#{task.id}']")
      assert has_element?(view, "[data-testid='decline-#{task.id}']")
    end
  end

  describe "error banner" do
    test "is absent on open", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      refute has_element?(view, "[data-testid='payout-error']")
    end

    test "stays absent when the parent reports a successful bulk approve", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='pay-out-all-button']") |> render_click()

      refute has_element?(view, "[data-testid='payout-error']")
    end

    test "appears when the parent reports a failed bulk approve", %{conn: conn} do
      %{assignment: assignment} = setup_pending_approval()
      view = mount_modal(conn, assignment, parent_result: "error")

      view |> element("[data-testid='pay-out-all-button']") |> render_click()

      assert has_element?(view, "[data-testid='payout-error']")
    end

    test "appears when the parent reports a failed decline", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment, parent_result: "error")

      view |> element("[data-testid='decline-#{task.id}']") |> render_click()
      view |> form("form[phx-submit='submit_decline']") |> render_submit(%{"reason" => "n/a"})

      assert has_element?(view, "[data-testid='payout-error']")
    end

    test "keeps the row expanded after a failed decline so it can be retried", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment, parent_result: "error")

      view |> element("[data-testid='decline-#{task.id}']") |> render_click()
      view |> form("form[phx-submit='submit_decline']") |> render_submit(%{"reason" => "n/a"})

      assert has_element?(view, "[data-testid='decline-reason-#{task.id}']")
    end

    test "collapses the row and clears the banner after a successful decline", %{conn: conn} do
      %{assignment: assignment, task: task} = setup_pending_approval()
      view = mount_modal(conn, assignment)

      view |> element("[data-testid='decline-#{task.id}']") |> render_click()
      view |> form("form[phx-submit='submit_decline']") |> render_submit(%{"reason" => "n/a"})

      refute has_element?(view, "[data-testid='decline-reason-#{task.id}']")
      refute has_element?(view, "[data-testid='payout-error']")
    end
  end

  defp mount_modal(conn, %{id: assignment_id}, opts \\ []) do
    session =
      %{"assignment_id" => assignment_id}
      |> Map.merge(Map.new(opts, fn {k, v} -> {to_string(k), v} end))

    {:ok, view, _html} = live_isolated(conn, Host, session: session)
    view
  end

  defp setup_pending_approval(opts \\ []) do
    reward_status = Keyword.get(opts, :reward_status, :pending_approval)

    assignment = Assignment.Factories.create_questionnaire_assignment()

    currency = Fund.Factories.create_currency("eur_payout_modal", :legal, "€", 2)
    fund = Fund.Factories.create_fund("fund_payout_modal_#{assignment.id}", currency)

    {:ok, _} = assignment |> Assignment.Model.changeset(fund) |> Repo.update()

    assignment = Repo.preload(assignment, [:crew, :workflow], force: true)

    participant = Factories.insert!(:member, %{creator: false})

    [workflow_item | _] = assignment.workflow |> Repo.preload(:items) |> Map.fetch!(:items)

    member = Crew.Factories.create_member(assignment.crew, participant)
    identifier = ["item=#{workflow_item.id}", "member=#{member.id}"]
    task = Crew.Factories.create_task(assignment.crew, member, identifier, status: :completed)

    {:ok, %{reward: reward}} =
      Fund.Public.create_reward(
        Repo.preload(fund, [:available, :pending, :currency]),
        1000,
        participant,
        "assignment=#{assignment.id},user=#{participant.id}"
      )

    reward = reward |> Ecto.Changeset.change(%{status: reward_status}) |> Repo.update!()

    assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))

    %{assignment: assignment, task: task, reward: reward}
  end
end
