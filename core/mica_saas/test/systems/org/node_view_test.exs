defmodule MicaSaas.Systems.Org.NodeViewTest do
  use MicaSaasWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Mica.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Content
  alias Systems.Org

  defp mount_node_view(conn, org, user, is_admin?) do
    context =
      LiveContext.new(%{node_id: org.id, current_user: user, locale: :en, is_admin?: is_admin?})

    conn = Map.put(conn, :request_path, "/org/node")
    {:ok, view, _html} = live_isolated(conn, Org.NodeView, session: %{"live_context" => context})
    view
  end

  defp reload(org), do: Org.Public.get_node!(org.id)

  defp full_name(org) do
    org.id
    |> Org.Public.get_node!(Org.NodeModel.preload_graph(:full))
    |> Map.fetch!(:full_name_bundle)
    |> Content.TextBundleModel.text("en", nil, nil)
  end

  defp rename_params(name) do
    %{
      "node_model" => %{
        "full_name_bundle" => %{"items" => %{"0" => %{"locale" => "en", "text" => name}}}
      }
    }
  end

  defp insert_org do
    Factories.insert!(:org_node, %{identifier: ["node_view_org"], domains: ["uni.test"]})
  end

  describe "an organisation owner" do
    setup ctx do
      owner = Factories.insert!(:creator)
      org = insert_org()
      :ok = Org.Public.assign_owner(org, owner)
      {:ok, ctx} = login(owner, ctx)
      {:ok, conn: ctx[:conn], owner: owner, org: org}
    end

    test "sees no research-institute checkbox", %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, false)
      refute has_element?(view, "[data-testid='research-institute-checkbox']")
    end

    test "can't set the mark with a crafted event", %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, false)

      render_click(view, "toggle_research_institute", %{})

      refute Org.NodeModel.research_institute?(reload(org))
    end

    test "can't change domains or identifier with a crafted event",
         %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, false)

      render_change(view, "save", %{
        "node_model" => %{"domains_string" => "gmail.com", "identifier_string" => "taken_over"}
      })

      assert %{domains: ["uni.test"], identifier: ["node_view_org"]} = reload(org)
    end

    test "renames the organisation", %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, false)

      render_change(view, "save", rename_params("Renamed"))

      assert full_name(org) == "Renamed"
    end

    test "can't rename the organisation once no longer an owner",
         %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, false)
      :ok = Org.Public.revoke_owner(org, owner)

      render_change(view, "save", rename_params("Renamed"))

      refute full_name(org) == "Renamed"
    end

    test "can't change domains even when the page was opened as admin",
         %{conn: conn, org: org, owner: owner} do
      view = mount_node_view(conn, org, owner, true)

      render_change(view, "save", %{"node_model" => %{"domains_string" => "gmail.com"}})

      assert %{domains: ["uni.test"]} = reload(org)
    end
  end

  describe "a system admin" do
    setup ctx do
      admin = Factories.insert!(:member, %{email: "admin1@example.org"})
      {:ok, ctx} = login(admin, ctx)
      {:ok, conn: ctx[:conn], admin: admin, org: insert_org()}
    end

    test "marks the organisation as a research institute and removes the mark",
         %{conn: conn, org: org, admin: admin} do
      view = mount_node_view(conn, org, admin, true)

      view |> element("[data-testid='research-institute-checkbox']") |> render_click()

      assert %{research_institute_at: %DateTime{}, research_institute_by_id: by_id} = reload(org)
      assert by_id == admin.id
      assert has_element?(view, "[data-testid='research-institute-note']")

      view |> element("[data-testid='research-institute-checkbox']") |> render_click()

      refute Org.NodeModel.research_institute?(reload(org))
    end

    test "changes the domains", %{conn: conn, org: org, admin: admin} do
      view = mount_node_view(conn, org, admin, true)

      render_change(view, "save", %{"node_model" => %{"domains_string" => "uni.test lab.test"}})

      assert %{domains: ["uni.test", "lab.test"]} = reload(org)
    end

    test "sees what to fix when a domain isn't a domain", %{conn: conn, org: org, admin: admin} do
      view = mount_node_view(conn, org, admin, true)

      html = render_change(view, "save", %{"node_model" => %{"domains_string" => "uni.test %"}})

      assert html =~ "Enter domain names only"
      assert %{domains: ["uni.test"]} = reload(org)
    end
  end
end
