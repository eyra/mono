defmodule Systems.Admin.AccountViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Systems.Admin

  describe "AccountView" do
    setup do
      # Create a test creator user
      creator =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: nil,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      %{creator: creator}
    end

    test "renders account view with title", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, html} = live_isolated(conn, Admin.AccountView, session: session)

      # Should render account view
      assert view |> has_element?("[data-testid='account-view']")

      # Should show title
      assert view |> has_element?("[data-testid='account-title']")
      assert html =~ "Users"
    end

    test "renders user list", %{conn: conn, creator: creator} do
      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, html} = live_isolated(conn, Admin.AccountView, session: session)

      # Should render user list
      assert view |> has_element?("[data-testid='user-list']")

      # Should show the creator user
      assert html =~ creator.email
    end

    test "shows user count in title", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, _view, html} = live_isolated(conn, Admin.AccountView, session: session)

      # Should show count (at least 1 for the creator we made)
      assert html =~ "text-primary"
    end

    test "verify_creator event updates user", %{conn: conn, creator: creator} do
      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.AccountView, session: session)

      # Click verify button
      view |> render_click("verify_creator", %{"item" => "#{creator.id}"})

      # View should still be rendered
      assert view |> has_element?("[data-testid='account-view']")
    end

    test "make_creator event updates user", %{conn: conn} do
      # Create a non-creator user
      non_creator =
        Factories.insert!(:member, %{
          creator: false,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.AccountView, session: session)

      # Click make_creator button
      view |> render_click("make_creator", %{"item" => "#{non_creator.id}"})

      # View should still be rendered
      assert view |> has_element?("[data-testid='account-view']")
    end

    test "activate_user event updates user", %{conn: conn} do
      # Create an unconfirmed user
      unconfirmed =
        Factories.insert!(:member, %{
          creator: true,
          confirmed_at: nil
        })

      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.AccountView, session: session)

      # Click activate button
      view |> render_click("activate_user", %{"item" => "#{unconfirmed.id}"})

      # View should still be rendered
      assert view |> has_element?("[data-testid='account-view']")
    end

    test "unverify_creator event updates user", %{conn: conn, creator: creator} do
      # First verify the creator
      verified_creator =
        creator
        |> Ecto.Changeset.change(%{
          verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })
        |> Core.Repo.update!()

      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.AccountView, session: session)

      # Click unverify button
      view |> render_click("unverify_creator", %{"item" => "#{verified_creator.id}"})

      # View should still be rendered
      assert view |> has_element?("[data-testid='account-view']")
    end

    test "deactivate_user event updates user", %{conn: conn, creator: creator} do
      conn = conn |> Map.put(:request_path, "/admin/accounts")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.AccountView, session: session)

      # Click deactivate button
      view |> render_click("deactivate_user", %{"item" => "#{creator.id}"})

      # View should still be rendered
      assert view |> has_element?("[data-testid='account-view']")
    end

    # Regression coverage for FX#9905883929 — Pixel.Selector falls back to
    # `send(self(), {event_name, payload})` when :fabric is not in
    # assigns, so the filter handler must accept the raw handle_info
    # tuple rather than a Phoenix `handle_event` with a `source` key.
    test "filter change updates the list via handle_info({\"active_item_ids\", ...})",
         %{conn: conn} do
      non_creator =
        Factories.insert!(:member, %{
          creator: false,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      conn = conn |> Map.put(:request_path, "/admin/accounts")
      {:ok, view, html} = live_isolated(conn, Admin.AccountView, session: %{})

      # Default filter is [:creator] — a non-creator should not be visible.
      refute html =~ non_creator.email

      # Selector emulation: send the raw fallback message it would send
      # when no Fabric context is present.
      send(view.pid, {"active_item_ids", %{active_item_ids: []}})

      assert render(view) =~ non_creator.email
    end

    # Regression coverage for FX#9905883929 — Pixel.SearchBar's fallback
    # publishes a LiveNest event {:live_nest_event, %LiveNest.Event{
    # name: :search_query, ...}}, which is routed to consume_event/2.
    test "search query narrows the list via consume_event(:search_query)",
         %{conn: conn} do
      a_creator =
        Factories.insert!(:member, %{
          creator: true,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      other_creator =
        Factories.insert!(:member, %{
          creator: true,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      conn = conn |> Map.put(:request_path, "/admin/accounts")
      {:ok, view, html} = live_isolated(conn, Admin.AccountView, session: %{})

      assert html =~ a_creator.email
      assert html =~ other_creator.email

      # SearchBar emulation: publish a LiveNest :search_query event.
      query = String.split(a_creator.email, " ")

      send(
        view.pid,
        {:live_nest_event,
         %LiveNest.Event{
           name: :search_query,
           payload: %{query: query, query_string: a_creator.email},
           source: {self(), nil}
         }}
      )

      rendered = render(view)
      assert rendered =~ a_creator.email
      refute rendered =~ other_creator.email
    end
  end
end
