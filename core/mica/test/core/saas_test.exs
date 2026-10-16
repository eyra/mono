defmodule Core.SaaSTest do
  use ExUnit.Case, async: true

  defmodule GoodSystem do
    use Core.System
  end

  defmodule NotASystem do
  end

  defmodule DuplicateSaaS do
    use Core.SaaS
    def systems, do: [GoodSystem, GoodSystem]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule UnknownSaaS do
    use Core.SaaS
    def systems, do: [Core.SaaSTest.Missing.System]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule NoSystemSaaS do
    use Core.SaaS
    def systems, do: [NotASystem]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  test "the configured SaaS lists Mica's systems first" do
    assert Core.SaaS.module() == Next.SaaS
    assert List.starts_with?(Core.SaaS.systems(), Core.systems())
    assert Core.SaaS.checked_systems(Next.SaaS) == Next.SaaS.systems()
  end

  test "a SaaS module that is no Core.SaaS is named in the error" do
    assert_raise ArgumentError,
                 "config :core, saas: names Core.SaaSTest.NotASystem, which does not `use Core.SaaS`",
                 fn -> Core.SaaS.checked_systems(NotASystem) end
  end

  test "an entry that is not a module is named in the error" do
    assert_raise ArgumentError,
                 ~r/^Core.SaaSTest.UnknownSaaS.systems\/0 names Core.SaaSTest.Missing.System, which is not a module/,
                 fn -> Core.SaaS.checked_systems(UnknownSaaS) end
  end

  test "an entry that is no Core.System is named in the error" do
    assert_raise ArgumentError,
                 "Core.SaaSTest.NoSystemSaaS.systems/0 names Core.SaaSTest.NotASystem, which does not `use Core.System`",
                 fn -> Core.SaaS.checked_systems(NoSystemSaaS) end
  end

  test "a system listed twice is an error" do
    assert_raise ArgumentError,
                 "Core.SaaSTest.DuplicateSaaS.systems/0 lists [Core.SaaSTest.GoodSystem] more than once",
                 fn -> Core.SaaS.checked_systems(DuplicateSaaS) end
  end
end
