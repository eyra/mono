defmodule Systems.Assignment.ContributionsViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Fund

  setup ctx do
    isolate_signals(except: [Systems.Assignment.Switch])

    user = Factories.insert!(:member)
    {:ok, ctx} = login(user, ctx)
    conn = ctx[:conn] |> Map.put(:request_path, "/assignments/contributions")

    participant = Factories.insert!(:member)
    %{fund: fund, crew: crew} = assignment = Assignment.Factories.create_assignment(31, 1)
    member = Crew.Factories.create_member(crew, participant)

    context =
      LiveContext.new(%{
        current_user: user,
        locale: :en,
        timezone: "Etc/UTC",
        assignment_id: assignment.id,
        title: "Contributions"
      })

    {:ok,
     conn: conn,
     user: user,
     context: context,
     assignment: assignment,
     fund: fund,
     crew: crew,
     participant: participant,
     member: member}
  end

  defp mount_view(conn, context) do
    live_isolated(conn, Assignment.ContributionsView, session: %{"live_context" => context})
  end

  defp create_pending_contribution(assignment, participant, crew, member) do
    idempotence_key = Assignment.Public.idempotence_key(assignment, participant)
    {:ok, _} = Fund.Public.create_reward(assignment.fund, 1000, participant, idempotence_key)
    {:ok, _} = Fund.Public.mark_pending_approval(idempotence_key)
    {:ok, _} = Assignment.Public.obtain_participation(assignment, participant)

    task =
      Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"],
        status: :completed
      )

    {idempotence_key, task}
  end

  describe "mounting" do
    test "renders the contributions frame with the given title", %{conn: conn, context: context} do
      {:ok, view, _html} = mount_view(conn, context)
      assert view |> has_element?("[data-testid='contributions-view']")
      assert render(view) =~ "Contributions"
    end

    test "always mounts the pending and confirmed sub-components",
         %{conn: conn, context: context} do
      {:ok, view, _html} = mount_view(conn, context)
      assert view |> has_element?("[data-testid='contributions-pending']")
      assert view |> has_element?("[data-testid='contributions-confirmed']")
    end

    test "omits the declined sub-component when there are no declined rewards",
         %{conn: conn, context: context} do
      {:ok, view, _html} = mount_view(conn, context)
      refute view |> has_element?("[data-testid='contributions-declined']")
    end

    test "mounts the declined sub-component when there is at least one declined reward",
         %{conn: conn, context: context, participant: participant, fund: fund} do
      Factories.insert!(:reward, %{
        idempotence_key: "rw-rejected-#{System.unique_integer([:positive])}",
        amount: 300,
        status: :rejected,
        rejected_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        user: participant,
        fund: fund
      })

      {:ok, view, _html} = mount_view(conn, context)
      assert view |> has_element?("[data-testid='contributions-declined']")
    end
  end

  describe "handle_info :confirm_all" do
    test "bulk-approves all pending rewards for the assignment",
         %{
           conn: conn,
           context: context,
           assignment: assignment,
           participant: participant,
           crew: crew,
           member: member
         } do
      {idempotence_key, _} = create_pending_contribution(assignment, participant, crew, member)

      {:ok, view, _html} = mount_view(conn, context)
      send(view.pid, :confirm_all)

      # let the LV drain the message + send_update
      _ = render(view)

      assert %Fund.RewardModel{status: :approved} =
               Fund.Public.get_reward(idempotence_key, [])
    end
  end

  describe "handle_info :submit_decline" do
    test "rejects the reward for the given participation_id",
         %{
           conn: conn,
           context: context,
           assignment: assignment,
           participant: participant,
           crew: crew,
           member: member
         } do
      {idempotence_key, _task} =
        create_pending_contribution(assignment, participant, crew, member)

      {:ok, participation} =
        Assignment.Public.obtain_participation(assignment, participant)

      {:ok, view, _html} = mount_view(conn, context)

      send(
        view.pid,
        {:submit_decline, %{participation_id: participation.id, reason: "bad data"}}
      )

      _ = render(view)

      assert %Fund.RewardModel{
               status: :rejected,
               rejection_reason: "bad data"
             } = Fund.Public.get_reward(idempotence_key, [])
    end
  end
end
