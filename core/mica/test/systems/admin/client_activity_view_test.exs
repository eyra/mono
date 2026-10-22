defmodule Systems.Admin.ClientActivityViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  require LiveNest.Constants

  import Systems.Admin.ClientActivityTestHelper

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Admin

  setup ctx do
    admin = Factories.insert!(:member)
    {:ok, ctx} = login(admin, ctx)

    client = Factories.insert!(:member)
    teammate = Factories.insert!(:member)

    assignment =
      insert_project_assignment(
        name: "Published study",
        project_owners: [owner(client, ~N[2024-01-01 00:00:00]), owner(teammate)],
        status: :online
      )

    _concept = insert_project_assignment(name: "Concept study", project_owners: [owner(client)])

    context = LiveContext.new(%{current_user: admin, locale: :en, is_admin?: true})

    {:ok,
     conn: ctx[:conn] |> Map.put(:request_path, "/admin/config"),
     context: context,
     client: client,
     teammate: teammate,
     assignment: assignment}
  end

  defp mount(conn, context) do
    {:ok, view, _html} =
      live_isolated(conn, Admin.ClientActivityView, session: %{"live_context" => context})

    view
  end

  test "lists clients with their assignment count", %{
    conn: conn,
    context: context,
    client: client
  } do
    view = mount(conn, context)

    assert view |> has_element?("[data-testid='client-row-#{client.id}']")
    assert view |> element("[data-testid='client-count-#{client.id}']") |> render() =~ "2"
    assert view |> has_element?("[data-testid='client-activity-filter-hint']")
  end

  test "published filter updates the count", %{conn: conn, context: context, client: client} do
    view = mount(conn, context)

    send(view.pid, {
      LiveNest.Constants.event(),
      %LiveNest.Event{name: :active_item_ids, payload: %{active_item_ids: [:published]}}
    })

    assert view |> element("[data-testid='client-count-#{client.id}']") |> render() =~ "1"
  end

  test "shows no client data to a non-admin", %{conn: conn, client: client} do
    member = Factories.insert!(:member)
    context = LiveContext.new(%{current_user: member, locale: :en, is_admin?: false})
    view = mount(conn, context)

    assert view |> has_element?("[data-testid='client-activity-forbidden']")
    refute view |> has_element?("[data-testid='client-row-#{client.id}']")
  end

  test "selecting a client shows their assignments", %{
    conn: conn,
    context: context,
    client: client,
    assignment: assignment
  } do
    view = mount(conn, context)

    view |> render_click("select_client", %{"item" => "#{client.id}"})

    assert view |> has_element?("[data-testid='client-assignment-list']")
    assert view |> has_element?("[data-testid='assignment-row-#{assignment.id}']")
  end

  test "selecting an assignment shows its details and team", %{
    conn: conn,
    context: context,
    client: client,
    teammate: teammate,
    assignment: assignment
  } do
    view = mount(conn, context)

    view |> render_click("select_client", %{"item" => "#{client.id}"})
    view |> render_click("select_assignment", %{"item" => "#{assignment.id}"})

    assert view |> has_element?("[data-testid='client-assignment-details']")
    assert view |> has_element?("[data-testid='team-member-#{client.id}']")
    assert view |> has_element?("[data-testid='team-member-#{teammate.id}']")
  end

  test "back from an assignment returns to the client's assignments", %{
    conn: conn,
    context: context,
    client: client,
    assignment: assignment
  } do
    view = mount(conn, context)

    view |> render_click("select_client", %{"item" => "#{client.id}"})
    view |> render_click("select_assignment", %{"item" => "#{assignment.id}"})
    view |> render_click("back")

    assert view |> has_element?("[data-testid='client-assignment-list']")
  end

  test "back from a client returns to the client list", %{
    conn: conn,
    context: context,
    client: client
  } do
    view = mount(conn, context)

    view |> render_click("select_client", %{"item" => "#{client.id}"})
    view |> render_click("back")

    assert view |> has_element?("[data-testid='client-list']")
  end
end
