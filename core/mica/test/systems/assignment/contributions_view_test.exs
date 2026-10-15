defmodule Systems.Assignment.ContributionsViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper
  import Systems.Fund.TestHelper
  import Systems.NextAction.TestHelper

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Fund
  alias Systems.NextAction

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
    idempotence_key = Assignment.Private.reward_idempotence_key(assignment, participant)
    {:ok, _} = Fund.Public.create_reward(assignment.fund, 1000, participant, idempotence_key)
    {:ok, _} = mark_pending_approval(idempotence_key)

    {:ok, participation} = Assignment.Public.obtain_participation(assignment, participant)
    {:ok, _} = Assignment.Public.complete_participation(participation)

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

    test "mounts the declined sub-component when there is at least one declined participation",
         %{conn: conn, context: context, assignment: assignment, participant: participant} do
      {:ok, participation} = Assignment.Public.obtain_participation(assignment, participant)
      {:ok, _} = Assignment.Public.reject_participation(participation, "not eligible")

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

    test "approves multiple pending participations in one bulk action",
         %{
           conn: conn,
           context: context,
           assignment: assignment,
           crew: crew,
           participant: participant_a,
           member: member_a
         } do
      {key_a, _} = create_pending_contribution(assignment, participant_a, crew, member_a)

      participant_b = Factories.insert!(:member)
      member_b = Crew.Factories.create_member(crew, participant_b)
      {key_b, _} = create_pending_contribution(assignment, participant_b, crew, member_b)

      {:ok, view, _html} = mount_view(conn, context)
      send(view.pid, :confirm_all)
      _ = render(view)

      assert %Fund.RewardModel{status: :approved} = Fund.Public.get_reward(key_a, [])
      assert %Fund.RewardModel{status: :approved} = Fund.Public.get_reward(key_b, [])
    end

    test "clears the PendingContributions NA once the pending queue drains",
         %{
           conn: conn,
           context: context,
           user: user,
           assignment: %{id: id} = assignment,
           crew: crew,
           participant: participant_a,
           member: member_a
         } do
      # Signed-in user is the assignment's owner (inherited from auth tree).
      :ok = Core.Authorization.assign_role(user, assignment, :owner)

      {_, _} = create_pending_contribution(assignment, participant_a, crew, member_a)

      participant_b = Factories.insert!(:member)
      member_b = Crew.Factories.create_member(crew, participant_b)
      {_, _} = create_pending_contribution(assignment, participant_b, crew, member_b)

      # Seed the NA the Switch would have created on the first :completed signal.
      NextAction.Public.create_next_action(
        [user],
        Systems.Assignment.NextActions.PendingContributions,
        key: "#{id}",
        params: %{"assignment_id" => id}
      )

      assert_next_action(user, "/assignment/#{id}/content?tab=contributions")

      {:ok, view, _html} = mount_view(conn, context)
      send(view.pid, :confirm_all)
      _ = render(view)

      refute_next_action(user, "/assignment/#{id}/content?tab=contributions")
    end
  end

  describe "consume_event :submit_decline" do
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
        {:live_nest_event,
         %LiveNest.Event{
           name: :submit_decline,
           payload: %{participation_id: participation.id, reason: "bad data"}
         }}
      )

      _ = render(view)

      assert %Fund.RewardModel{status: :rejected} =
               Fund.Public.get_reward(idempotence_key, [])
    end
  end
end
