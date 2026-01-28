defmodule Systems.Admin.OrgViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Admin.OrgViewBuilder
  alias Systems.Org

  describe "view_model/2" do
    test "builds correct view model structure" do
      vm = OrgViewBuilder.view_model(nil, %{locale: :en, is_admin?: true})

      assert vm.title == dgettext("eyra-admin", "org.content.title")
      assert vm.search_placeholder == dgettext("eyra-org", "search.placeholder")
      assert vm.create_button.face.label == dgettext("eyra-admin", "create.org.button")

      assert vm.create_button.face_short.label ==
               dgettext("eyra-admin", "create.org.button.short")

      assert is_list(vm.filter_labels)
      assert is_list(vm.organisations)
      assert is_integer(vm.org_count)
    end

    test "create_button is nil for non-admin" do
      vm = OrgViewBuilder.view_model(nil, %{locale: :en, is_admin?: false})

      assert vm.create_button == nil
    end

    test "filter_labels contains root and nested filters" do
      vm = OrgViewBuilder.view_model(nil, %{locale: :en})

      filter_ids = Enum.map(vm.filter_labels, & &1.id)
      assert :root in filter_ids
      assert :nested in filter_ids
    end

    test "filter_labels are inactive by default" do
      vm = OrgViewBuilder.view_model(nil, %{locale: :en})

      assert Enum.all?(vm.filter_labels, fn label -> label.active == false end)
    end

    test "org_count matches organisations list length" do
      vm = OrgViewBuilder.view_model(nil, %{locale: :en})

      assert vm.org_count == length(vm.organisations)
    end
  end

  describe "build_organisation_items/5" do
    setup do
      # Root org: no parent
      {:ok, %{org: root}} =
        Org.Public.create_node(
          ["root", "org"],
          [{:en, "ROOT"}, {:nl, "ROOT"}],
          [{:en, "Root University"}, {:nl, "Root University"}]
        )

      # Nested org: has parent
      {:ok, %{org: nested}} =
        Org.Public.create_node(
          ["nested", "org"],
          [{:en, "NESTED"}, {:nl, "NESTED"}],
          [{:en, "Nested Department"}, {:nl, "Nested Department"}]
        )

      # root → nested creates: nested has parent
      Org.Public.create_link!(root, nested)

      # Reload with preloads
      root = Org.Public.get_node!(root.id, Org.NodeModel.preload_graph(:full))
      nested = Org.Public.get_node!(nested.id, Org.NodeModel.preload_graph(:full))

      %{root: root, nested: nested}
    end

    test "returns all organisations with no filters", %{root: root, nested: nested} do
      base_orgs = [root, nested]
      items = OrgViewBuilder.build_organisation_items(base_orgs, nil, [], :en, true)

      ids = Enum.map(items, & &1.item)
      assert root.id in ids
      assert nested.id in ids
    end

    test "filters to root organisations only", %{root: root, nested: nested} do
      base_orgs = [root, nested]
      items = OrgViewBuilder.build_organisation_items(base_orgs, nil, [:root], :en, true)

      ids = Enum.map(items, & &1.item)
      assert root.id in ids
      refute nested.id in ids
    end

    test "filters to nested organisations only", %{root: root, nested: nested} do
      base_orgs = [root, nested]
      items = OrgViewBuilder.build_organisation_items(base_orgs, nil, [:nested], :en, true)

      ids = Enum.map(items, & &1.item)
      refute root.id in ids
      assert nested.id in ids
    end

    test "shows all when both filters selected", %{root: root, nested: nested} do
      base_orgs = [root, nested]
      items = OrgViewBuilder.build_organisation_items(base_orgs, nil, [:root, :nested], :en, true)

      ids = Enum.map(items, & &1.item)
      assert root.id in ids
      assert nested.id in ids
    end

    test "filters by search query", %{root: root, nested: nested} do
      base_orgs = [root, nested]

      items =
        OrgViewBuilder.build_organisation_items(base_orgs, ["Root University"], [], :en, true)

      ids = Enum.map(items, & &1.item)
      assert root.id in ids
    end
  end

  describe "build_organisation_item/3" do
    setup do
      {:ok, %{org: org}} =
        Org.Public.create_node(
          ["item", "test"],
          [{:en, "ITEM"}, {:nl, "ITEM"}],
          [{:en, "Item Test Org"}, {:nl, "Item Test Org"}]
        )

      org = Org.Public.get_node!(org.id, Org.NodeModel.preload_graph(:full))
      %{org: org}
    end

    test "builds correct item structure", %{org: org} do
      item = OrgViewBuilder.build_organisation_item(org, :en, true)

      assert item.item == org.id
      assert is_binary(item.title)
      assert is_binary(item.description)
      assert is_list(item.tags)
    end

    test "includes member count in description", %{org: org} do
      item = OrgViewBuilder.build_organisation_item(org, :en, true)

      assert item.description =~ dgettext("eyra-org", "org.members.label")
    end

    test "includes left_actions for admin", %{org: org} do
      item = OrgViewBuilder.build_organisation_item(org, :en, true)

      assert length(item.left_actions) == 1
      assert hd(item.left_actions).action.event == "setup_admins"
    end

    test "includes right_actions for admin", %{org: org} do
      item = OrgViewBuilder.build_organisation_item(org, :en, true)

      assert length(item.right_actions) == 1
      assert hd(item.right_actions).action.event == "archive_org"
    end

    test "no actions for non-admin", %{org: org} do
      item = OrgViewBuilder.build_organisation_item(org, :en, false)

      assert item.left_actions == []
      assert item.right_actions == []
    end

    test "uses domains as tags" do
      # Create org with domains
      {:ok, %{org: org}} =
        Org.Public.create_node(
          ["domain", "test"],
          [{:en, "DOM"}, {:nl, "DOM"}],
          [{:en, "Domain Test Org"}, {:nl, "Domain Test Org"}]
        )

      # Update org with domains via the virtual domains_string field
      org
      |> Org.NodeModel.changeset(%{domains_string: "test.edu example.org"})
      |> Core.Repo.update!()

      org = Org.Public.get_node!(org.id, Org.NodeModel.preload_graph(:full))
      item = OrgViewBuilder.build_organisation_item(org, :en, true)

      assert "test.edu" in item.tags
      assert "example.org" in item.tags
    end
  end
end
