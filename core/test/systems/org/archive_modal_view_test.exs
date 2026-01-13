defmodule Systems.Org.ArchiveModalViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Org

  describe "ArchiveModalView" do
    setup ctx do
      user = Factories.insert!(:creator)
      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/admin/archived")
      {:ok, conn: conn, user: user}
    end

    test "renders modal with title", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, Org.ArchiveModalView,
          session: %{
            "locale" => "en"
          }
        )

      assert has_element?(view, "[data-testid='archived-orgs-modal']")
    end

    test "renders archived organisations", %{conn: conn} do
      _archived =
        Factories.insert!(:org_node, %{
          identifier: ["archived_view_test"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, view, _html} =
        live_isolated(conn, Org.ArchiveModalView,
          session: %{
            "locale" => "en"
          }
        )

      assert has_element?(view, "[data-testid='archived-org-list']")
      assert has_element?(view, "[data-testid='archived-org-item']")
    end

    test "restore_org event restores organisation", %{conn: conn} do
      archived_org =
        Factories.insert!(:org_node, %{
          identifier: ["restore_view_test"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, view, _html} =
        live_isolated(conn, Org.ArchiveModalView,
          session: %{
            "locale" => "en"
          }
        )

      # Initially archived
      assert Org.Public.get_node!(archived_org.id).archived_at != nil

      # Trigger restore
      view |> render_click("restore_org", %{"item" => to_string(archived_org.id)})

      # Now restored
      assert Org.Public.get_node!(archived_org.id).archived_at == nil
    end
  end
end
