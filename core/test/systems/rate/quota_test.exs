defmodule Systems.Rate.QuotaTest do
  use ExUnit.Case, async: true
  alias Systems.Rate.Quota

  describe "keyword init/1" do
    test "all atoms" do
      assert %Systems.Rate.Quota{
               service: "storage_export",
               limit: 1,
               unit: :call,
               window: :minute,
               scope: :local
             } =
               Quota.init(
                 service: :storage_export,
                 limit: 1,
                 unit: :call,
                 window: :minute,
                 scope: :local
               )
    end

    test "all strings" do
      assert %Systems.Rate.Quota{
               service: "storage_export",
               limit: 1,
               unit: :call,
               window: :minute,
               scope: :local
             } =
               Quota.init(
                 service: "storage_export",
                 limit: "1",
                 unit: "call",
                 window: "minute",
                 scope: "local"
               )
    end

    test "invalid string" do
      assert_raise RuntimeError, fn ->
        Quota.init(
          service: "storage_export",
          limit: 1,
          unit: "invalid",
          window: "minute",
          scope: "local"
        )
      end
    end

    test "invalid atom" do
      assert_raise RuntimeError, fn ->
        Quota.init(
          service: "storage_export",
          limit: 1,
          unit: :invalid,
          window: "minute",
          scope: "local"
        )
      end
    end

    test "invalid integer" do
      assert_raise RuntimeError, fn ->
        Quota.init(
          service: "storage_export",
          limit: :invalid,
          unit: :call,
          window: "minute",
          scope: "local"
        )
      end
    end
  end

  describe "map init/1" do
    test "all atoms" do
      assert %Systems.Rate.Quota{
               service: "storage_export",
               limit: 1,
               unit: :call,
               window: :minute,
               scope: :local
             } =
               Quota.init(%{
                 service: :storage_export,
                 limit: 1,
                 unit: :call,
                 window: :minute,
                 scope: :local
               })
    end

    test "all strings" do
      assert %Systems.Rate.Quota{
               service: "storage_export",
               limit: 1,
               unit: :call,
               window: :minute,
               scope: :local
             } =
               Quota.init(%{
                 service: "storage_export",
                 limit: "1",
                 unit: "call",
                 window: "minute",
                 scope: "local"
               })
    end

    test "invalid string" do
      assert_raise RuntimeError, fn ->
        Quota.init(%{
          service: "storage_export",
          limit: 1,
          unit: "invalid",
          window: "minute",
          scope: "local"
        })
      end
    end

    test "invalid atom" do
      assert_raise RuntimeError, fn ->
        Quota.init(%{
          service: "storage_export",
          limit: 1,
          unit: :invalid,
          window: "minute",
          scope: "local"
        })
      end
    end

    test "invalid integer" do
      assert_raise RuntimeError, fn ->
        Quota.init(%{
          service: "storage_export",
          limit: :invalid,
          unit: :call,
          window: "minute",
          scope: "local"
        })
      end
    end
  end

  describe "json init/1" do
    test "json" do
      json =
        Jason.decode!("""
          {"service": "storage_export", "limit": "1", "unit": "call", "window": "minute", "scope": "local"}
        """)

      assert %Systems.Rate.Quota{
               service: "storage_export",
               limit: 1,
               unit: :call,
               window: :minute,
               scope: :local
             } = Quota.init(json)
    end
  end
end
