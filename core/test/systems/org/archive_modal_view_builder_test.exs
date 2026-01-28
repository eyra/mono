defmodule Systems.Org.ArchiveModalViewBuilderTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Org
  alias Systems.Org.ArchiveModalViewBuilder

  describe "view_model/2" do
    test "returns archived organisations" do
      _active_org = Factories.insert!(:org_node, %{identifier: ["active_org"]})

      archived_org =
        Factories.insert!(:org_node, %{
          identifier: ["archived_org"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en})

      org_ids = Enum.map(vm.organisations, & &1.item)
      refute _active_org.id in org_ids
      assert archived_org.id in org_ids
    end

    test "returns title in view model" do
      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en})

      assert is_binary(vm.title)
      assert vm.title != ""
    end

    test "returns org_count matching organisations length" do
      _archived1 =
        Factories.insert!(:org_node, %{
          identifier: ["arch1"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      _archived2 =
        Factories.insert!(:org_node, %{
          identifier: ["arch2"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en})

      assert vm.org_count == length(vm.organisations)
      assert vm.org_count >= 2
    end

    test "filters by search query" do
      _org1 =
        Factories.insert!(:org_node, %{
          identifier: ["searchable_org"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      _org2 =
        Factories.insert!(:org_node, %{
          identifier: ["other_archived"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en, query: ["searchable"]})

      # Should filter to only match "searchable" in title/description
      assert Enum.all?(vm.organisations, fn org ->
               String.contains?(String.downcase(org.title), "searchable") or
                 String.contains?(String.downcase(org.description), "searchable")
             end)
    end

    test "builds restore button for each organisation" do
      _archived =
        Factories.insert!(:org_node, %{
          identifier: ["restore_test"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en})

      assert Enum.all?(vm.organisations, fn org ->
               length(org.action_buttons) == 1 and
                 hd(org.action_buttons).action.event == "restore_org"
             end)
    end

    test "returns filter_labels" do
      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en})

      assert length(vm.filter_labels) == 2
      filter_ids = Enum.map(vm.filter_labels, & &1.id)
      assert :root in filter_ids
      assert :nested in filter_ids
    end

    test "filters by hierarchy - root only" do
      # Create parent and child orgs
      parent =
        Factories.insert!(:org_node, %{
          identifier: ["parent_arch"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      child =
        Factories.insert!(:org_node, %{
          identifier: ["child_arch"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      Org.Public.create_link!(parent, child)

      # Reload to get reverse_links
      child = Org.Public.get_node!(child.id, [:reverse_links])

      vm = ArchiveModalViewBuilder.view_model(nil, %{locale: :en, active_filters: [:root]})

      # Should only include root orgs (no reverse_links)
      org_ids = Enum.map(vm.organisations, & &1.item)
      assert parent.id in org_ids
      refute child.id in org_ids
    end
  end
end
