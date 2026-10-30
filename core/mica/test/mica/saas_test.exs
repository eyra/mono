defmodule Mica.SaaSTest do
  use ExUnit.Case, async: true

  defmodule GoodSystem do
    use Mica.System
  end

  defmodule NotASystem do
  end

  defmodule EmailSystem do
    use Mica.System
    def notify_channels, do: %{email: Mica.SaaSTest.EmailChannel}
  end

  defmodule OtherEmailSystem do
    use Mica.System
    def notify_channels, do: %{email: Mica.SaaSTest.OtherEmailChannel}
  end

  defmodule ChildSystem do
    use Mica.System
    def children, do: [{Registry, keys: :unique, name: Mica.SaaSTest.Registry}]
  end

  defmodule QueueSystem do
    use Mica.System
    def oban_queues, do: [imports: 1]
  end

  defmodule OtherQueueSystem do
    use Mica.System
    def oban_queues, do: [exports: 2, imports: 3]
  end

  defmodule CronSystem do
    use Mica.System
    def oban_crons, do: [cleanup: {"0 * * * *", Mica.SaaSTest.CleanupWorker}]
  end

  defmodule OtherCronSystem do
    use Mica.System

    def oban_crons,
      do: [
        report: {"0 3 * * *", Mica.SaaSTest.ReportWorker},
        cleanup: {"* * * * *", Mica.SaaSTest.CleanupWorker}
      ]
  end

  defmodule NewsSection do
    def id, do: :news
  end

  defmodule OtherNewsSection do
    def id, do: :news
  end

  defmodule TipsSection do
    def id, do: :tips
  end

  defmodule NewsSystem do
    use Mica.System
    def desktop_sections, do: [NewsSection]
  end

  defmodule OtherNewsSystem do
    use Mica.System
    def desktop_sections, do: [OtherNewsSection, TipsSection]
  end

  defmodule TipsSystem do
    use Mica.System
    def desktop_sections, do: [TipsSection]
  end

  defmodule SignInSystem do
    use Mica.System
    def feature_flags, do: [:password_sign_in, :otp]
  end

  defmodule OtpSystem do
    use Mica.System
    def feature_flags, do: [:otp]
  end

  defmodule MigrationsSystem do
    use Mica.System
    def migrations_path, do: "/app/priv/tools/migrations"
  end

  defmodule FlagSaaS do
    use Mica.SaaS
    def systems, do: [SignInSystem, OtpSystem]
    def feature_flags, do: [otp: true]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule TypoFlagSaaS do
    use Mica.SaaS
    def systems, do: [SignInSystem]
    def feature_flags, do: [opt: true]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule DuplicateSaaS do
    use Mica.SaaS
    def systems, do: [GoodSystem, GoodSystem]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule UnknownSaaS do
    use Mica.SaaS
    def systems, do: [Mica.SaaSTest.Missing.System]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  defmodule NoSystemSaaS do
    use Mica.SaaS
    def systems, do: [NotASystem]
    def start_pages, do: nil
    def menu_items, do: nil
    def menu_builder(_), do: nil
    def signed_in_page(_), do: "/"
  end

  test "the configured SaaS lists Mica's systems first" do
    assert Mica.SaaS.module() == Next.SaaS
    assert List.starts_with?(Mica.SaaS.systems(), Mica.Systems.all())
    assert Mica.SaaS.checked_systems(Next.SaaS) == Next.SaaS.systems()
  end

  test "a SaaS module that is no Mica.SaaS is named in the error" do
    assert_raise ArgumentError,
                 "config :mica, saas: names Mica.SaaSTest.NotASystem, which does not `use Mica.SaaS`",
                 fn -> Mica.SaaS.checked_systems(NotASystem) end
  end

  test "an entry that is not a module is named in the error" do
    assert_raise ArgumentError,
                 ~r/^Mica.SaaSTest.UnknownSaaS.systems\/0 names Mica.SaaSTest.Missing.System, which is not a module/,
                 fn -> Mica.SaaS.checked_systems(UnknownSaaS) end
  end

  test "an entry that is no Mica.System is named in the error" do
    assert_raise ArgumentError,
                 "Mica.SaaSTest.NoSystemSaaS.systems/0 names Mica.SaaSTest.NotASystem, which does not `use Mica.System`",
                 fn -> Mica.SaaS.checked_systems(NoSystemSaaS) end
  end

  test "a system listed twice is an error" do
    assert_raise ArgumentError,
                 "Mica.SaaSTest.DuplicateSaaS.systems/0 lists [Mica.SaaSTest.GoodSystem] more than once",
                 fn -> Mica.SaaS.checked_systems(DuplicateSaaS) end
  end

  test "signal handlers are collected from all systems, sorted by module name within the systems" do
    handlers = Mica.SaaS.signal_handlers()

    assert handlers ==
             Enum.sort_by(handlers, &String.replace(inspect(&1), ~r/^\w+\.(?=Systems\.)/, ""))

    assert Systems.Assignment.Switch in handlers
    assert Next.Systems.Zircon.Switch in handlers
  end

  test "notify channels are collected from all systems" do
    assert Mica.SaaS.notify_channels() == %{
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
                 fn -> Mica.SaaS.collect_notify_channels([EmailSystem, OtherEmailSystem]) end
  end

  test "the migration paths of the systems that have their own are collected" do
    assert Mica.SaaS.collect_migrations_paths([GoodSystem, MigrationsSystem]) == [
             "/app/priv/tools/migrations"
           ]
  end

  test "the migration paths are only Mica's while no system has its own" do
    assert Mica.SaaS.migrations_paths() == [
             Application.app_dir(:mica, "priv/repo/migrations")
           ]
  end

  test "the children of the systems are collected" do
    assert Mica.SaaS.collect_children([GoodSystem, ChildSystem]) == [
             {Registry, keys: :unique, name: Mica.SaaSTest.Registry}
           ]
  end

  test "Desktop sections are collected in system order" do
    assert Mica.SaaS.collect_desktop_sections([TipsSystem, GoodSystem, NewsSystem]) == [
             TipsSection,
             NewsSection
           ]
  end

  test "a Desktop section id declared by two sections is an error" do
    assert_raise ArgumentError,
                 "Desktop section id :news is declared by more than one section",
                 fn -> Mica.SaaS.collect_desktop_sections([NewsSystem, OtherNewsSystem]) end
  end

  test "Oban queues are collected in system order" do
    assert Mica.SaaS.collect_oban_queues([OtherQueueSystem, GoodSystem]) == [
             exports: 2,
             imports: 3
           ]
  end

  test "an Oban queue declared by two systems is an error" do
    assert_raise ArgumentError,
                 "Oban queue :imports is declared by more than one system",
                 fn -> Mica.SaaS.collect_oban_queues([QueueSystem, OtherQueueSystem]) end
  end

  test "Oban crons are collected in system order" do
    assert Mica.SaaS.collect_oban_crons([CronSystem, GoodSystem]) == [
             cleanup: {"0 * * * *", Mica.SaaSTest.CleanupWorker}
           ]
  end

  test "an Oban cron declared by two systems is an error" do
    assert_raise ArgumentError,
                 "Oban cron :cleanup is declared by more than one system",
                 fn -> Mica.SaaS.collect_oban_crons([CronSystem, OtherCronSystem]) end
  end

  test "declared feature flags are off unless the SaaS turns them on" do
    assert Mica.SaaS.collect_feature_flags(FlagSaaS, FlagSaaS.systems()) == [
             otp: true,
             password_sign_in: false
           ]
  end

  test "a SaaS default for a flag that no system declares is an error, also at compile time" do
    message =
      "Mica.SaaSTest.TypoFlagSaaS.feature_flags/0 sets [:opt], which none of its systems declares"

    assert_raise ArgumentError, message, fn ->
      Mica.SaaS.collect_feature_flags(TypoFlagSaaS, TypoFlagSaaS.systems())
    end

    # The route and grant macros check the SaaS while the router compiles.
    assert_raise ArgumentError, message, fn -> Mica.SaaS.checked_systems(TypoFlagSaaS) end
  end

  test "Next declares every flag it sets, and nothing more" do
    assert Keyword.keys(Mica.SaaS.feature_flags()) ==
             Enum.sort(Keyword.keys(Next.SaaS.feature_flags()))
  end

  test "the systems declare their queues and quotas" do
    assert Mica.SaaS.oban_queues() == [email_dispatchers: 1, email_delivery: 1, ris_import: 1]

    assert Keyword.keys(Mica.SaaS.oban_crons()) == [
             :advert_expiration,
             :pay_in_expiration,
             :auto_approve,
             :data_donation_cleanup,
             :payment_reconciliation,
             :auth_code_cleanup
           ]

    assert [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local] in Mica.SaaS.rate_quotas()
  end

  test "the Admin and Account systems declare the admin panels and account tabs, in order" do
    assert Mica.SaaS.admin_panels() == [
             Systems.Admin.SystemPanel,
             Systems.Admin.AccountPanel,
             Systems.Admin.OrgPanel,
             Systems.Admin.ActionsPanel,
             Systems.Admin.ClientActivityPanel
           ]

    assert Mica.SaaS.account_tabs() == [
             Systems.Account.ProfileTab,
             Systems.Account.PayoutsTab,
             Systems.Account.FeaturesTab
           ]
  end
end
