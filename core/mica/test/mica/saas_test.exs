defmodule Mica.SaaSTest.Stub do
  @moduledoc false
  # A test SaaS, with the callbacks these tests don't read.
  defmacro __using__(_opts) do
    quote do
      use Mica.SaaS
      def endpoint, do: nil
      def router, do: nil
      def start_pages, do: nil
      def menu_items, do: nil
      def menu_builder(_), do: nil
      def title, do: "Test"
      def signed_in_page(_), do: "/"
      def sign_in_page, do: "/sign-in"
      def member_sign_in_page(_return_to), do: "/sign-in"
      def sign_in_options_page, do: "/sign-in"
      def identify_page(_user_type), do: "/identify"
      def session_path, do: "/session"
    end
  end
end

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

  defmodule PagesSystem do
    use Mica.System
    def bff_pages, do: %{home: Mica.SaaSTest.HomePage}
  end

  defmodule OtherPagesSystem do
    use Mica.System
    def bff_pages, do: %{home: Mica.SaaSTest.OtherHomePage, settings: Mica.SaaSTest.SettingsPage}
  end

  defmodule SettingsSystem do
    use Mica.System
    def bff_pages, do: %{settings: Mica.SaaSTest.SettingsPage}
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

  defmodule GrantSystem do
    use Mica.System
    def grants, do: [{Mica.SaaSTest.Page, [:member]}]
  end

  defmodule ActionGrantSystem do
    use Mica.System
    def grants, do: [{Mica.SaaSTest.Controller, %{index: [:visitor]}}]
  end

  defmodule QuotedGrantSystem do
    use Mica.System
    def grants, do: quote(do: [{Mica.SaaSTest.Page, [:member]}])
  end

  defmodule MigrationsSystem do
    use Mica.System
    def migrations_path, do: "/app/priv/tools/migrations"
  end

  defmodule FlagSaaS do
    use Mica.SaaSTest.Stub
    def systems, do: [SignInSystem, OtpSystem]
    def feature_flags, do: [otp: true]
  end

  defmodule TypoFlagSaaS do
    use Mica.SaaSTest.Stub
    def systems, do: [SignInSystem]
    def feature_flags, do: [opt: true]
  end

  defmodule DuplicateSaaS do
    use Mica.SaaSTest.Stub
    def systems, do: [GoodSystem, GoodSystem]
  end

  defmodule UnknownSaaS do
    use Mica.SaaSTest.Stub
    def systems, do: [Mica.SaaSTest.Missing.System]
  end

  defmodule NoSystemSaaS do
    use Mica.SaaSTest.Stub
    def systems, do: [NotASystem]
  end

  # Mica has no sign-in pages, router or product name of its own (d-0011).
  test "use Mica.SaaS gives no default for the router, the sign-in pages or the title" do
    {_result, diagnostics} =
      Code.with_diagnostics(fn ->
        Code.compile_quoted(
          quote do
            defmodule Mica.SaaSTest.Bare do
              use Mica.SaaS
            end
          end
        )
      end)

    callbacks =
      ~w(router/0 sign_in_page/0 member_sign_in_page/1 sign_in_options_page/0
         identify_page/1 session_path/0 title/0)

    for callback <- callbacks do
      [name, arity] = String.split(callback, "/")

      refute function_exported?(
               Mica.SaaSTest.Bare,
               String.to_atom(name),
               String.to_integer(arity)
             )

      assert Enum.any?(
               diagnostics,
               &(&1.message =~ "function #{callback} required by behaviour")
             ),
             "no warning that #{callback} is required"
    end
  end

  describe "the composition of Mica's own tests" do
    test "is made of Mica's systems, with no SaaS configured" do
      assert Mica.Env.get(:saas) == nil
      refute Mica.SaaS.saas?()
      assert Mica.SaaS.systems() == Mica.Systems.all()
    end

    test "raises on every Mica.SaaS callback" do
      for {name, arity} <- Mica.SaaS.behaviour_info(:callbacks) do
        assert_raise RuntimeError, ~r/^no SaaS: this is a mica-saas test/, fn ->
          apply(Mica.SaaS.module(), name, List.duplicate(nil, arity))
        end
      end
    end

    test "has no endpoint or router" do
      assert_raise RuntimeError, ~r/^no SaaS: this is a mica-saas test/, &Mica.SaaS.endpoint/0
      assert_raise RuntimeError, ~r/^no SaaS: this is a mica-saas test/, &Mica.SaaS.router/0
    end

    test "passes the boot's checks, and the app runs no endpoint" do
      assert Mica.SaaS.validate!() == :ok
      refute Mica.SaaS.saas?()

      refute Enum.any?(Mica.Application.children(), fn child ->
               module = with {module, _opts} <- child, do: module
               is_atom(module) and function_exported?(module, :__mica_endpoint__, 0)
             end)
    end
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

  test "notify channels are collected from all systems" do
    assert Mica.SaaS.notify_channels() == %{
             email: Systems.Notify.Channel.Email,
             na: Systems.Notify.Channel.NA
           }
  end

  test "the notify message channels are the collected channel names" do
    assert Systems.Notify.MessageModel.channels() == [:email, :na]
  end

  test "a notify channel declared by two systems is an error" do
    assert_raise ArgumentError,
                 "notify channel :email is declared by more than one system",
                 fn -> Mica.SaaS.collect_notify_channels([EmailSystem, OtherEmailSystem]) end
  end

  test "grants are collected from all systems as data, in system order" do
    assert Mica.SaaS.collect_grants([GrantSystem, GoodSystem, ActionGrantSystem]) == [
             {Mica.SaaSTest.Page, [:member]},
             {Mica.SaaSTest.Controller, %{index: [:visitor]}}
           ]
  end

  test "a quoted grant is an error" do
    assert_raise ArgumentError,
                 ~r/^Mica.SaaSTest.QuotedGrantSystem.grants\/0: not a grant: \{\{:__aliases__/,
                 fn -> Mica.SaaS.collect_grants([QuotedGrantSystem]) end
  end

  test "the configured SaaS's grants are in the permission map" do
    permission_map = Mica.Authorization.permission_map()

    for {module, roles} when is_list(roles) <- Mica.SaaS.grants() do
      assert Frameworks.GreenLight.PermissionMap.roles(
               permission_map,
               Frameworks.GreenLight.Permissions.access_permission(module)
             ) == MapSet.new(roles)
    end
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

  test "BFF pages are collected from all systems" do
    assert Mica.SaaS.collect_bff_pages([PagesSystem, GoodSystem, SettingsSystem]) == %{
             home: Mica.SaaSTest.HomePage,
             settings: Mica.SaaSTest.SettingsPage
           }
  end

  test "a BFF page served by two systems is an error" do
    assert_raise ArgumentError,
                 "BFF page :home is served by more than one system",
                 fn -> Mica.SaaS.collect_bff_pages([PagesSystem, OtherPagesSystem]) end
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

    # The route macros check the SaaS while the router compiles.
    assert_raise ArgumentError, message, fn -> Mica.SaaS.checked_systems(TypoFlagSaaS) end
  end

  test "the Admin and Account systems declare the admin panels and account tabs, in order" do
    # The SaaS's own systems add their panels after these.
    assert Enum.take(Mica.SaaS.admin_panels(), 5) == [
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
