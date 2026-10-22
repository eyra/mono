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

  describe "merge/2" do
    test "keeps the defaults of services without an override" do
      otp = quota(:otp_request, 3)

      assert Quota.merge([otp], [quota(:signup, 5)]) == [otp, quota(:signup, 5)]
    end

    test "replaces all defaults of a service that has an override" do
      defaults = [quota(:storage_export, 1), quota(:storage_export, 2, :global)]
      override = quota(:storage_export, 6)

      assert Quota.merge(defaults, [override]) == [override]
    end

    test "keeps the defaults when there are no overrides" do
      defaults = [quota(:otp_request, 3), quota(:signup, 5)]

      assert Quota.merge(defaults, []) == defaults
    end
  end

  defp quota(service, limit, scope \\ :local) do
    Quota.init(service: service, limit: limit, unit: :call, window: :minute, scope: scope)
  end
end
