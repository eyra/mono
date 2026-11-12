defmodule Mica.SaaSValidateTest.Systems do
  @moduledoc false

  defmodule Switch do
  end

  defmodule Notifier do
    def notify_events, do: [validate_test_event: [channels: [:email]]]
  end

  defmodule OtherNotifier do
    def notify_events, do: [validate_test_event: [channels: [:email]]]
  end

  defmodule SmsNotifier do
    def notify_events, do: [validate_test_sms: [channels: [:sms]]]
  end

  defmodule Handoff do
  end

  defmodule Template do
    def id, do: :validate_test
  end

  defmodule OtherTemplate do
    def id, do: :validate_test
  end

  defmodule Section do
    def id, do: :validate_test
  end

  defmodule Page do
  end

  defmodule Plain do
    use Mica.System
  end

  defmodule HandlerTwice do
    use Mica.System
    def signal_handlers, do: [Switch, Switch]
  end

  defmodule NotifierTwice do
    use Mica.System
    def notifiers, do: [Notifier, Notifier]
    def notify_channels, do: %{email: Mica.SaaSValidateTest.EmailChannel}
  end

  defmodule EventTwice do
    use Mica.System
    def notifiers, do: [Notifier, OtherNotifier]
    def notify_channels, do: %{email: Mica.SaaSValidateTest.EmailChannel}
  end

  defmodule UnknownChannel do
    use Mica.System
    def notifiers, do: [SmsNotifier]
  end

  defmodule Email do
    use Mica.System
    def notify_channels, do: %{email: Mica.SaaSValidateTest.EmailChannel}
  end

  defmodule HandoffTwice do
    use Mica.System
    def sign_in_handoffs, do: [Handoff, Handoff]
  end

  defmodule Templates do
    use Mica.System
    def assignment_templates, do: [Template, OtherTemplate]
  end

  defmodule Desktop do
    use Mica.System
    def desktop_sections, do: [Section]
  end

  defmodule Queue do
    use Mica.System
    def oban_queues, do: [validate_test: 1]
  end

  defmodule Cron do
    use Mica.System
    def oban_crons, do: [validate_test: {"0 * * * *", Mica.SaaSValidateTest.Worker}]
  end

  defmodule BFF do
    use Mica.System
    def bff_pages, do: %{validate_test: Page}
  end

  defmodule Grant do
    use Mica.System
    def grants, do: [{Page, [:member]}]
  end

  defmodule Widen do
    use Mica.System
    def grants, do: [{Page, [:admin], widen: true}]
  end

  defmodule Flag do
    use Mica.System
    def feature_flags, do: [:validate_test]
  end

  # Second systems that declare the same as the one above them.
  defmodule OtherEmail do
    use Mica.System
    def notify_channels, do: %{email: Mica.SaaSValidateTest.OtherEmailChannel}
  end

  defmodule OtherQueue do
    use Mica.System
    def oban_queues, do: [validate_test: 2]
  end

  defmodule OtherCron do
    use Mica.System
    def oban_crons, do: [validate_test: {"* * * * *", Mica.SaaSValidateTest.Worker}]
  end

  defmodule OtherDesktop do
    use Mica.System
    def desktop_sections, do: [Mica.SaaSValidateTest.Systems.OtherSection]
  end

  defmodule OtherSection do
    def id, do: :validate_test
  end

  defmodule OtherBFF do
    use Mica.System
    def bff_pages, do: %{validate_test: Mica.SaaSValidateTest.Systems.OtherPage}
  end

  defmodule OtherGrant do
    use Mica.System
    def grants, do: [{Page, [:admin]}]
  end
end

defmodule Mica.SaaSValidateTest.SaaS do
  @moduledoc false
  # A SaaS made of the systems the test puts in its process.
  use Mica.SaaS
  def systems, do: Process.get(:validate_test_systems)
  def feature_flags, do: Process.get(:validate_test_flags, [])
  def endpoint, do: Process.get(:validate_test_endpoint, NextWeb.Endpoint)
  def start_pages, do: nil
  def menu_items, do: nil
  def menu_builder(_), do: nil
  def signed_in_page(_), do: "/"
end

defmodule Mica.SaaSValidateTest do
  # Not async: a test changes the Logger level.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  require Logger

  alias Mica.SaaS
  alias Mica.SaaSValidateTest.Systems

  defp validate!(systems, flags \\ []) do
    Process.put(:validate_test_systems, systems)
    Process.put(:validate_test_flags, flags)
    SaaS.validate!(Mica.SaaSValidateTest.SaaS)
  end

  test "the configured SaaS validates" do
    assert %{systems: systems} = SaaS.validate!(SaaS.module())
    assert systems == SaaS.systems()
  end

  test "a valid composition passes" do
    assert %{systems: [Systems.Plain, Systems.Email]} = validate!([Systems.Plain, Systems.Email])
  end

  test "a SaaS module that is no Mica.SaaS" do
    assert_raise ArgumentError, ~r/does not `use Mica.SaaS`/, fn ->
      SaaS.validate!(Systems.Switch)
    end
  end

  test "the composition holds the SaaS's endpoint" do
    assert %{endpoint: NextWeb.Endpoint} = validate!([Systems.Plain])
    assert SaaS.endpoint() == SaaS.module().endpoint()
  end

  test "an endpoint that is no MicaWeb.Endpoint" do
    Process.put(:validate_test_endpoint, Systems.Plain)

    assert_raise ArgumentError,
                 "Mica.SaaSValidateTest.SaaS.endpoint/0 names Mica.SaaSValidateTest.Systems.Plain, " <>
                   "which does not `use MicaWeb.Endpoint`",
                 fn -> validate!([Systems.Plain]) end
  end

  test "an endpoint that is no module" do
    Process.put(:validate_test_endpoint, Mica.SaaSValidateTest.Missing)

    assert_raise ArgumentError,
                 ~r/endpoint\/0 names Mica.SaaSValidateTest.Missing, which is not a module/,
                 fn ->
                   validate!([Systems.Plain])
                 end
  end

  test "a system that is no Mica.System" do
    assert_raise ArgumentError, ~r/does not `use Mica.System`/, fn ->
      validate!([Systems.Switch])
    end
  end

  test "a system listed twice" do
    assert_raise ArgumentError,
                 ~r/lists \[Mica.SaaSValidateTest.Systems.Plain\] more than once/,
                 fn ->
                   validate!([Systems.Plain, Systems.Plain])
                 end
  end

  test "a signal handler listed twice" do
    assert_raise ArgumentError, ~r/^signal handler \[.*Switch\] is listed more than once/, fn ->
      validate!([Systems.HandlerTwice])
    end
  end

  test "a notifier listed twice" do
    assert_raise ArgumentError, ~r/^notifier \[.*Notifier\] is listed more than once/, fn ->
      validate!([Systems.NotifierTwice])
    end
  end

  test "an event type that two notifiers declare" do
    assert_raise ArgumentError,
                 ~s(notify event type ["validate_test_event"] is listed more than once),
                 fn -> validate!([Systems.EventTwice]) end
  end

  test "a notify channel that two systems declare" do
    assert_raise ArgumentError, "notify channel :email is declared by more than one system", fn ->
      validate!([Systems.Email, Systems.OtherEmail])
    end
  end

  test "an Oban cron that two systems declare" do
    assert_raise ArgumentError,
                 "Oban cron :validate_test is declared by more than one system",
                 fn ->
                   validate!([Systems.Cron, Systems.OtherCron])
                 end
  end

  test "a Desktop section id that two sections have" do
    assert_raise ArgumentError,
                 "Desktop section id :validate_test is declared by more than one section",
                 fn -> validate!([Systems.Desktop, Systems.OtherDesktop]) end
  end

  test "a BFF page that two systems serve" do
    assert_raise ArgumentError, "BFF page :validate_test is served by more than one system", fn ->
      validate!([Systems.BFF, Systems.OtherBFF])
    end
  end

  test "an Oban queue that two systems declare" do
    assert_raise ArgumentError,
                 "Oban queue :validate_test is declared by more than one system",
                 fn ->
                   validate!([Systems.Queue, Systems.OtherQueue])
                 end
  end

  test "a sign-in handoff listed twice" do
    assert_raise ArgumentError, ~r/^sign-in handoff \[.*Handoff\] is listed more than once/, fn ->
      validate!([Systems.HandoffTwice])
    end
  end

  test "an assignment template id listed twice" do
    assert_raise ArgumentError,
                 "assignment template id [:validate_test] is listed more than once",
                 fn ->
                   validate!([Systems.Templates])
                 end
  end

  test "a flag default that no system declares" do
    assert_raise ArgumentError,
                 ~r/sets \[:validate_tset\], which none of its systems declares/,
                 fn ->
                   validate!([Systems.Flag], validate_tset: true)
                 end
  end

  test "a notifier event routed to a channel that no system declares" do
    assert_raise ArgumentError,
                 ~s(notify event "validate_test_sms" is routed to channel :sms, which no system declares),
                 fn -> validate!([Systems.UnknownChannel]) end
  end

  test "a permission granted twice" do
    assert_raise ArgumentError, ~r/granted more than once; a grant that widens another one/, fn ->
      validate!([Systems.Grant, Systems.OtherGrant])
    end
  end

  test "a widening grant passes and is logged" do
    # The test config logs errors only.
    level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: level) end)

    log = capture_log(fn -> validate!([Systems.Grant, Systems.Widen]) end)

    assert log =~
             "the grant of Mica.SaaSValidateTest.Systems.Page to [:admin] widens another grant"
  end

  test "a widening grant that widens nothing" do
    assert_raise ArgumentError, ~r/is not granted before, so `widen: true` widens nothing/, fn ->
      validate!([Systems.Widen])
    end
  end
end
