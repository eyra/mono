defmodule Systems.Pool.AssemblyTest do
  use Core.DataCase

  alias Systems.Budget
  alias Systems.Org
  alias Systems.Pool

  describe "get_or_create_panl/0" do
    test "creates PANL pool with all dependencies when it doesn't exist" do
      assert Pool.Public.get_panl() == nil

      pool = Pool.Assembly.get_or_create_panl()

      assert %Pool.Model{
               name: "Panl",
               target: 1000,
               director: :citizen
             } = pool

      assert pool.currency != nil
      assert pool.org != nil
    end

    test "returns existing PANL pool when it exists" do
      first_pool = Pool.Assembly.get_or_create_panl()
      second_pool = Pool.Assembly.get_or_create_panl()

      assert first_pool.id == second_pool.id
    end

    test "creates euro currency for PANL pool" do
      pool = Pool.Assembly.get_or_create_panl()
      pool = Repo.preload(pool, :currency)

      assert %Budget.CurrencyModel{
               name: "euro",
               type: :legal,
               decimal_scale: 2
             } = pool.currency
    end

    test "creates panl org for PANL pool" do
      pool = Pool.Assembly.get_or_create_panl()
      pool = Repo.preload(pool, :org)

      assert %Org.NodeModel{
               identifier: ["panl"]
             } = pool.org
    end

    test "reuses existing euro currency" do
      euro = Budget.Assembly.get_or_create_euro()
      pool = Pool.Assembly.get_or_create_panl()
      pool = Repo.preload(pool, :currency)

      assert pool.currency.id == euro.id
    end

    test "reuses existing panl org" do
      Org.Public.create_node!(["panl"], [{:en, "Panl"}], [{:en, "Panl"}])
      org = Org.Public.get_node(["panl"])

      pool = Pool.Assembly.get_or_create_panl()
      pool = Repo.preload(pool, :org)

      assert pool.org.id == org.id
    end
  end
end
