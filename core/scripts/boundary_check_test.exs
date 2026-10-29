# Tests of the boundary check rules. Run from core/:
#   elixir scripts/boundary_check_test.exs

Code.require_file("boundary_rules.ex", __DIR__)
ExUnit.start()

defmodule BoundaryRulesTest do
  use ExUnit.Case, async: true

  @router "mica/lib/core_web/router.ex"
  @footer "mica/frameworks/pixel/components/footer.ex"
  @allowlist %{
    {@router, :next_reference} => [
      "next/systems/graphite/_routes.ex",
      "next/systems/onyx/_routes.ex"
    ],
    {@footer, :eyra_domain} => 2
  }

  defp found(router_targets, footer_count) do
    [{@router, :next_reference, router_targets}, {@footer, :eyra_domain, footer_count}]
  end

  describe "ratchet/2" do
    test "passes when the found violations equal the allowlist" do
      found = found(["next/systems/graphite/_routes.ex", "next/systems/onyx/_routes.ex"], 2)

      assert %{new: [], grown: [], shrunk: [], stale: []} =
               BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails on a new target in an allowlisted file" do
      found =
        found(
          [
            "next/systems/graphite/_routes.ex",
            "next/systems/onyx/_routes.ex",
            "next/systems/paper/_system.ex"
          ],
          2
        )

      assert %{new: [], grown: [{@router, :next_reference, ["next/systems/paper/_system.ex"]}]} =
               BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails when a target is swapped for another, and reports the drop" do
      found = found(["next/systems/graphite/_routes.ex", "next/systems/paper/_system.ex"], 2)

      assert %{
               grown: [{@router, :next_reference, ["next/systems/paper/_system.ex"]}],
               shrunk: [{@router, :next_reference, ["next/systems/onyx/_routes.ex"]}]
             } = BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails on more literal matches in an allowlisted file" do
      found = found(["next/systems/graphite/_routes.ex", "next/systems/onyx/_routes.ex"], 3)

      assert %{grown: [{@footer, :eyra_domain, {2, 3}}], shrunk: []} =
               BoundaryRules.ratchet(found, @allowlist)
    end

    test "passes with a note when targets or matches drop" do
      found = found(["next/systems/graphite/_routes.ex"], 1)

      assert %{new: [], grown: [], stale: [], shrunk: shrunk} =
               BoundaryRules.ratchet(found, @allowlist)

      assert Enum.sort(shrunk) == [
               {@footer, :eyra_domain, {2, 1}},
               {@router, :next_reference, ["next/systems/onyx/_routes.ex"]}
             ]
    end

    test "fails on a file that is not allowlisted" do
      probe = {"mica/systems/pool/probe.ex", :next_reference, ["next/systems/student/_public.ex"]}

      found = [
        probe | found(["next/systems/graphite/_routes.ex", "next/systems/onyx/_routes.ex"], 2)
      ]

      assert %{new: [^probe], grown: []} = BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails on a new kind in an allowlisted file" do
      panl = {@footer, :panl_domain, 1}

      found = [
        panl | found(["next/systems/graphite/_routes.ex", "next/systems/onyx/_routes.ex"], 2)
      ]

      assert %{new: [^panl]} = BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails on an entry that no longer occurs" do
      found = [{@footer, :eyra_domain, 2}]

      assert %{stale: [{@router, :next_reference}]} = BoundaryRules.ratchet(found, @allowlist)
    end

    test "fails when an entry's detail has the wrong shape" do
      found = found(3, 2)

      assert %{grown: [{@router, :next_reference, {_, 3}}]} =
               BoundaryRules.ratchet(found, @allowlist)
    end
  end

  describe "names/1" do
    defp names(source), do: source |> BoundaryRules.names() |> Enum.map(&elem(&1, 0))

    test "expands grouped aliases" do
      assert names("alias Systems.{Fund, Paper.Model}") == ["Systems.Fund", "Systems.Paper.Model"]
    end

    test "resolves short names through the file's aliases" do
      source = """
      alias Systems.Zircon
      alias Systems.{Paper}
      alias Systems.Graphite.Public, as: Leaderboards
      Zircon.Screening.run()
      Paper.Model
      Leaderboards.list()
      """

      assert "Systems.Zircon.Screening" in names(source)
      assert "Systems.Paper.Model" in names(source)
      assert "Systems.Graphite.Public" in names(source)
    end

    test "finds :\"Elixir.…\" atoms" do
      assert names(~s|{Registry, name: :"Elixir.Systems.Paper.ImportRegistry"}|) == [
               "Registry",
               "Systems.Paper.ImportRegistry"
             ]
    end

    test "turns config :core keys into system namespaces" do
      assert names("config :core, :zircon, agent: 1") == ["Systems.Zircon"]
      assert names("config :core, saas: Next.SaaS") == ["Next.SaaS"]
    end

    test "keeps lines, except for atoms" do
      assert BoundaryRules.names("x = 1\nalias Next.SaaS") == [{"Next.SaaS", 2}]
      assert BoundaryRules.names(~s|:"Elixir.Next.SaaS"|) == [{"Next.SaaS", nil}]
    end
  end

  describe "in_namespace?/2" do
    test "matches the namespace and its children, not a prefix" do
      assert BoundaryRules.in_namespace?("Systems.Paper", ["Systems.Paper"])
      assert BoundaryRules.in_namespace?("Systems.Paper.Model", ["Systems.Paper"])
      refute BoundaryRules.in_namespace?("Systems.PaperTrail", ["Systems.Paper"])
    end
  end
end
