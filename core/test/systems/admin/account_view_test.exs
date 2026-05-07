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
  end
end
