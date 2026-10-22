defmodule Systems.Org.PoolsViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Factories
  alias Systems.Fund
  alias Systems.Org
  alias Systems.Pool

  describe "view_model/2 with no pools linked to the org" do
    setup do
      org =
        Factories.insert!(:org_node, %{
          identifier: ["pools_view_builder_no_pools_#{System.unique_integer([:positive])}"]
        })

      %{org: org}
    end

    test "returns empty pools and pool_count zero", %{org: org} do
      vm = Org.PoolsViewBuilder.view_model(org, %{locale: :en})

      assert vm.pools == []
      assert vm.pool_count == 0
    end
  end

  describe "view_model/2 with a linked pool" do
    setup do
      org =
        Factories.insert!(:org_node, %{
          identifier: ["pools_view_builder_with_pool_#{System.unique_integer([:positive])}"]
        })

      currency =
        Fund.Factories.create_currency(
          "pools_view_builder_cur_#{System.unique_integer([:positive])}",
          :legal,
          "ƒ",
          2
        )

      pool =
        Pool.Public.create!(
          "pools_view_builder_pool_#{System.unique_integer([:positive])}",
          500,
          currency,
          org,
          :citizen
        )

      %{org: org, pool: pool}
    end

    test "returns the pool as an item with title and description", %{org: org, pool: pool} do
      vm = Org.PoolsViewBuilder.view_model(org, %{locale: :en})

      assert vm.pool_count == 1
      [item] = vm.pools
      assert item.item == pool.id
      assert item.title == pool.name
      assert item.description =~ dgettext("eyra-org", "pools.participants.label")
    end

    test "description reports the participant count", %{org: org, pool: pool} do
      participant = Factories.insert!(:member)
      Pool.Public.add_participant!(pool, participant)

      vm = Org.PoolsViewBuilder.view_model(org, %{locale: :en})

      [item] = vm.pools
      assert item.description =~ "1"
    end

    test "director and currency appear as tag chips", %{org: org} do
      vm = Org.PoolsViewBuilder.view_model(org, %{locale: :en})

      [item] = vm.pools
      assert is_list(item.tags)
      assert dgettext("eyra-pool", "director.citizen") in item.tags
      assert length(item.tags) == 2
    end
  end
end
