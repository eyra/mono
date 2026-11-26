defmodule MicaSaas.Systems.Org.MemberViewTest do
  @moduledoc """
  Regression coverage for FX#9905890143 — a stale LiveView session
  belonging to a user whose :owner role was revoked must not be able to
  mutate the org's membership.
  """
  use MicaSaasWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  require LiveNest.Constants

  alias Mica.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Org

  describe "MemberView authorization" do
    setup ctx do
      owner = Factories.insert!(:creator)
      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/node")

      org =
        Factories.insert!(:org_node, %{
          identifier: ["user_view_auth_org"],
          domains: ["user-view-auth.test"]
        })

      :ok = Org.Public.assign_owner(org, owner)

      context =
        LiveContext.new(%{
          node_id: org.id,
          current_user: owner,
          locale: :en
        })

      {:ok, conn: conn, owner: owner, org: org, context: context}
    end

    test "handle_info {:add_user, ...} no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      candidate = Factories.insert!(:creator)

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      send(view.pid, {:add_user, %{user: candidate}})
      _ = render(view)

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      refute candidate.id in member_ids
    end

    test "an Add refused after the owner role is revoked shows no row, name or photo",
         %{conn: conn, owner: owner, org: org, context: context} do
      researcher =
        Factories.insert!(:creator, %{
          email: "ada@gmail.test",
          displayname: "Ada",
          profile: %Account.UserProfileModel{
            fullname: "Ada Lovelace",
            photo_url: "https://photos.test/ada.png"
          }
        })

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      view
      |> form("#members_editor_search_bar_form", %{query: researcher.email})
      |> render_change()

      view
      |> element("[phx-click='add'][phx-value-item='#{researcher.id}']")
      |> render_click()

      # The component tells the view with a message; render/1 waits for it.
      html = render(view)

      refute Org.Public.member?(org, researcher)
      refute html =~ researcher.email
      refute html =~ "Ada"
      refute html =~ "https://photos.test/ada.png"
    end

    test "handle_info {:remove_user, ...} no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      member = Factories.insert!(:creator)
      Org.Public.add_member(org, member)

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      send(view.pid, {:remove_user, %{user: member}})
      _ = render(view)

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      assert member.id in member_ids
    end

    test "handle_event add_all_domain_matched no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      candidate = Factories.insert!(:creator, %{email: "candidate@user-view-auth.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      render_click(view, "add_all_domain_matched", %{})

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      refute candidate.id in member_ids
    end
  end

  describe "MemberView records who adds and removes members" do
    setup ctx do
      owner = Factories.insert!(:creator)
      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/node")

      org =
        Factories.insert!(:org_node, %{
          identifier: ["member_view_added_by"],
          domains: ["uni.test"]
        })

      :ok = Org.Public.assign_owner(org, owner)

      context = LiveContext.new(%{node_id: org.id, current_user: owner, locale: :en})
      {:ok, conn: conn, owner: owner, org: org, context: context}
    end

    test "an owner adds a researcher by hand and shows as who added them",
         %{conn: conn, owner: owner, org: org, context: context} do
      researcher = Factories.insert!(:creator, %{email: "researcher@gmail.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      send(view.pid, {:add_user, %{user: researcher}})

      assert render(view) =~ "Added by #{Account.User.label(owner)}"

      assert [%{user: %{id: user_id}, added_by: %{id: added_by_id}}] =
               Org.Public.list_memberships(org)

      assert user_id == researcher.id
      assert added_by_id == owner.id
    end

    test "an owner looking up an account sees only the email they typed until it's added",
         %{conn: conn, context: context} do
      researcher =
        Factories.insert!(:creator, %{
          email: "ada@gmail.test",
          displayname: "Ada",
          profile: %Account.UserProfileModel{
            fullname: "Ada Lovelace",
            photo_url: "https://photos.test/ada.png"
          }
        })

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      view
      |> form("#members_editor_search_bar_form", %{query: researcher.email})
      |> render_change()

      # The search bar updates the editor with send_update; render/1 waits for it.
      html = render(view)

      assert has_element?(view, "[phx-click='add'][phx-value-item='#{researcher.id}']")
      assert html =~ researcher.email
      refute html =~ "Ada"
      refute html =~ "https://photos.test/ada.png"

      view
      |> element("[phx-click='add'][phx-value-item='#{researcher.id}']")
      |> render_click()

      assert render(view) =~ "https://photos.test/ada.png"
    end

    test "an owner can't add an account they didn't look up",
         %{conn: conn, org: org, context: context} do
      looked_up = Factories.insert!(:creator, %{email: "looked-up@gmail.test"})
      other = Factories.insert!(:creator, %{email: "other@gmail.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      editor = with_target(view, "#members_editor")

      render_click(editor, "add", %{"item" => to_string(other.id)})

      view
      |> form("#members_editor_search_bar_form", %{query: looked_up.email})
      |> render_change()

      render_click(editor, "add", %{"item" => to_string(other.id)})

      # The component tells the view with a message; render/1 waits for it.
      html = render(view)

      refute Org.Public.member?(org, other)
      refute html =~ other.email
    end

    test "add all domain-matched records the owner for each member",
         %{conn: conn, owner: owner, org: org, context: context} do
      Factories.insert!(:creator, %{email: "one@uni.test"})
      Factories.insert!(:creator, %{email: "two@uni.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      render_click(view, "add_all_domain_matched", %{})

      memberships = Org.Public.list_memberships(org)
      assert length(memberships) == 2
      assert Enum.all?(memberships, &(&1.added_by.id == owner.id))
    end

    test "offers the researchers on a domain as soon as support enters it",
         %{conn: conn, org: org, context: context} do
      Factories.insert!(:creator, %{email: "new@lab.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      refute has_element?(view, "[phx-click='add_all_domain_matched']")

      org = Org.Public.get_node!(org.id, Org.NodeModel.preload_graph(:full))

      {:ok, _} =
        Mica.Persister.save(org, Org.NodeModel.changeset(org, %{domains_string: "lab.test"}))

      assert has_element?(view, "[phx-click='add_all_domain_matched']")
    end

    test "the only member can be removed",
         %{conn: conn, owner: owner, org: org, context: context} do
      member = Factories.insert!(:creator)
      :ok = Org.Public.add_member(org, member, owner)

      {:ok, view, _html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      view
      |> element("[phx-click='remove'][phx-value-item='#{member.id}']")
      |> render_click()

      # The component tells the view with a message; render/1 waits for it.
      _ = render(view)
      refute Org.Public.member?(org, member)
    end
  end

  # Coverage for FX#9905891585 — the Members tab now has a search bar and
  # filter chips driven by Pixel.SearchBar + Pixel.Selector, which talk
  # to the LiveView via consume_event/2. Both emit through
  # Frameworks.Pixel.FabricBridge; without a Fabric parent they publish
  # LiveNest events.
  describe "MemberView search and filter" do
    setup ctx do
      owner = Factories.insert!(:creator)
      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/node")

      org =
        Factories.insert!(:org_node, %{
          identifier: ["user_view_filter_test_org"],
          domains: ["filter-test.org"]
        })

      :ok = Org.Public.assign_owner(org, owner)

      context =
        LiveContext.new(%{
          node_id: org.id,
          current_user: owner,
          locale: :en
        })

      {:ok, conn: conn, org: org, context: context}
    end

    test ":external filter via Selector consume_event narrows the rendered list",
         %{conn: conn, org: org, context: context} do
      internal = Factories.insert!(:creator, %{email: "alice@filter-test.org"})
      external = Factories.insert!(:creator, %{email: "alice@elsewhere.example"})
      Org.Public.add_member(org, internal)
      Org.Public.add_member(org, external)

      {:ok, view, html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      assert html =~ internal.email
      assert html =~ external.email

      send(view.pid, {
        LiveNest.Constants.event(),
        %LiveNest.Event{name: :active_item_ids, payload: %{active_item_ids: [:external]}}
      })

      rendered = render(view)
      assert rendered =~ external.email
      refute rendered =~ internal.email
    end

    test "search query via SearchBar consume_event narrows the rendered list",
         %{conn: conn, org: org, context: context} do
      match = Factories.insert!(:creator, %{email: "needle@filter-test.org"})
      other = Factories.insert!(:creator, %{email: "haystack@filter-test.org"})
      Org.Public.add_member(org, match)
      Org.Public.add_member(org, other)

      {:ok, view, html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      assert html =~ match.email
      assert html =~ other.email

      send(
        view.pid,
        {:live_nest_event,
         %LiveNest.Event{
           name: :search_query,
           payload: %{query: ["needle"], query_string: "needle"},
           source: {self(), nil}
         }}
      )

      rendered = render(view)
      assert rendered =~ match.email
      refute rendered =~ other.email
    end
  end
end
