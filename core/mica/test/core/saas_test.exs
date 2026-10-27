defmodule Core.SaaSTest do
  use ExUnit.Case, async: true

  defmodule GoodSystem do
    use Core.System
  end

  defmodule NotASystem do
  end

  defmodule EmailSystem do
    use Core.System
    def notify_channels, do: %{email: Core.SaaSTest.EmailChannel}
  end

  defmodule OtherEmailSystem do
    use Core.System
    def notify_channels, do: %{email: Core.SaaSTest.OtherEmailChannel}
  end

  defmodule QueueSystem do
    use Core.System
    def oban_queues, do: [imports: 1]
  end

  defmodule OtherQueueSystem do
    use Core.System
    def oban_queues, do: [exports: 2, imports: 3]
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
    assert List.starts_with?(Core.SaaS.systems(), Core.Systems.all())
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

  test "signal handlers are collected from all systems, sorted by module name" do
    handlers = Core.SaaS.signal_handlers()

    assert handlers == Enum.sort(handlers)
    assert Systems.Assignment.Switch in handlers
    assert Systems.Zircon.Switch in handlers
  end

  test "notify channels are collected from all systems" do
    assert Core.SaaS.notify_channels() == %{
             email: Systems.Notify.Channel.Email,
             na: Systems.Notify.Channel.NA
           }
  end

  test "the notify message channel enum has the collected channel names" do
    assert Systems.Notify.MessageModel.channels() == [:email, :na]
  end

  test "a notify channel declared by two systems is an error" do
    assert_raise ArgumentError,
                 "notify channel :email is declared by more than one system",
                 fn -> Core.SaaS.collect_notify_channels([EmailSystem, OtherEmailSystem]) end
  end

  test "Oban queues are collected in system order" do
    assert Core.SaaS.collect_oban_queues([OtherQueueSystem, GoodSystem]) == [
             exports: 2,
             imports: 3
           ]
  end

  test "an Oban queue declared by two systems is an error" do
    assert_raise ArgumentError,
                 "Oban queue :imports is declared by more than one system",
                 fn -> Core.SaaS.collect_oban_queues([QueueSystem, OtherQueueSystem]) end
  end

  test "the Paper registry is a child and the systems declare their queues and quotas" do
    assert {Registry, keys: :unique, name: Systems.Paper.RISProcessorRegistry} in Core.SaaS.children()
    assert Core.SaaS.oban_queues() == [email_dispatchers: 1, email_delivery: 1, ris_import: 1]

    assert [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local] in Core.SaaS.rate_quotas()
  end
end
