defmodule MicaSaas.SaaSValidateTest.Systems do
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
    def notify_channels, do: %{email: MicaSaas.SaaSValidateTest.EmailChannel}
  end

  defmodule EventTwice do
    use Mica.System
    def notifiers, do: [Notifier, OtherNotifier]
    def notify_channels, do: %{email: MicaSaas.SaaSValidateTest.EmailChannel}
  end

  defmodule UnknownChannel do
    use Mica.System
    def notifiers, do: [SmsNotifier]
  end

  defmodule Email do
    use Mica.System
    def notify_channels, do: %{email: MicaSaas.SaaSValidateTest.EmailChannel}
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
    def oban_crons, do: [validate_test: {"0 * * * *", MicaSaas.SaaSValidateTest.Worker}]
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
    def notify_channels, do: %{email: MicaSaas.SaaSValidateTest.OtherEmailChannel}
  end

  defmodule OtherQueue do
    use Mica.System
    def oban_queues, do: [validate_test: 2]
  end

  defmodule OtherCron do
    use Mica.System
    def oban_crons, do: [validate_test: {"* * * * *", MicaSaas.SaaSValidateTest.Worker}]
  end

  defmodule OtherDesktop do
    use Mica.System
    def desktop_sections, do: [MicaSaas.SaaSValidateTest.Systems.OtherSection]
  end

  defmodule OtherSection do
    def id, do: :validate_test
  end

  defmodule OtherBFF do
    use Mica.System
    def bff_pages, do: %{validate_test: MicaSaas.SaaSValidateTest.Systems.OtherPage}
  end

  defmodule OtherGrant do
    use Mica.System
    def grants, do: [{Page, [:admin]}]
  end

  # Tool, project item and director registrations.
  defmodule ToolStub do
    defmacro __using__(type: type, schema: schema) do
      quote do
        use Mica.Tool
        def type, do: unquote(type)
        def schema, do: unquote(schema)
        def prepare(_attrs, _context), do: nil
        def view, do: nil
      end
    end
  end

  defmodule FeldsparTool do
    use ToolStub, type: "feldspar", schema: Systems.Feldspar.ToolModel
  end

  defmodule OtherFeldsparTool do
    use ToolStub, type: "feldspar", schema: Systems.Document.ToolModel
  end

  defmodule FeldsparCopyTool do
    use ToolStub, type: "feldspar_copy", schema: Systems.Feldspar.ToolModel
  end

  defmodule NoneTool do
    use ToolStub, type: "none", schema: Systems.Document.ToolModel
  end

  defmodule WrongKeyTool do
    use ToolStub, type: "feldspar_v2", schema: Systems.Document.ToolModel
  end

  defmodule StorageItem do
    use Mica.ProjectItem
    def type, do: "storage_endpoint"
    def schema, do: Systems.Storage.EndpointModel
  end

  defmodule OtherStorageItem do
    use Mica.ProjectItem
    def type, do: "storage_endpoint"
    def schema, do: Systems.Assignment.Model
  end

  defmodule NoneItem do
    use Mica.ProjectItem
    def type, do: "none"
    def schema, do: Systems.Assignment.Model
  end

  defmodule Tools do
    use Mica.System
    def tools, do: [FeldsparTool]
    def project_items, do: [StorageItem]
    def directors, do: %{validate_test: Page}
  end

  defmodule OtherTools do
    use Mica.System
    def tools, do: [OtherFeldsparTool]
  end

  defmodule CopyTools do
    use Mica.System
    def tools, do: [FeldsparCopyTool]
  end

  defmodule NoneTools do
    use Mica.System
    def tools, do: [NoneTool]
  end

  defmodule WrongKeyTools do
    use Mica.System
    def tools, do: [WrongKeyTool]
  end

  defmodule NotATool do
    use Mica.System
    def tools, do: [Page]
  end

  defmodule OtherItems do
    use Mica.System
    def project_items, do: [OtherStorageItem]
  end

  defmodule NoneItems do
    use Mica.System
    def project_items, do: [NoneItem]
  end

  defmodule OtherDirectors do
    use Mica.System
    def directors, do: %{validate_test: Switch}
  end
end

defmodule MicaSaas.SaaSValidateTest.SaaS do
  @moduledoc false
  # A SaaS made of the systems the test puts in its process.
  use Mica.SaaS
  def systems, do: Process.get(:validate_test_systems)
  def feature_flags, do: Process.get(:validate_test_flags, [])
  def endpoint, do: Process.get(:validate_test_endpoint, MicaSaasWeb.Endpoint)
  def router, do: Process.get(:validate_test_router, MicaSaasWeb.Router)
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

defmodule MicaSaas.SaaSValidateTest do
  # Not async: a test changes the Logger level.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  require Logger

  alias Mica.SaaS
  alias MicaSaas.SaaSValidateTest.Systems

  defp validate!(systems, flags \\ []) do
    Process.put(:validate_test_systems, systems)
    Process.put(:validate_test_flags, flags)
    SaaS.validate!(MicaSaas.SaaSValidateTest.SaaS)
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
    assert %{endpoint: MicaSaasWeb.Endpoint} = validate!([Systems.Plain])
    assert SaaS.endpoint() == SaaS.module().endpoint()
  end

  test "an endpoint that is no MicaWeb.Endpoint" do
    Process.put(:validate_test_endpoint, Systems.Plain)

    assert_raise ArgumentError,
                 "MicaSaas.SaaSValidateTest.SaaS.endpoint/0 names MicaSaas.SaaSValidateTest.Systems.Plain, " <>
                   "which does not `use MicaWeb.Endpoint`",
                 fn -> validate!([Systems.Plain]) end
  end

  test "the composition holds the SaaS's router" do
    assert %{router: MicaSaasWeb.Router} = validate!([Systems.Plain])
    assert SaaS.router() == SaaS.module().router()
  end

  test "a router that is no Phoenix.Router" do
    Process.put(:validate_test_router, Systems.Plain)

    assert_raise ArgumentError,
                 "MicaSaas.SaaSValidateTest.SaaS.router/0 names MicaSaas.SaaSValidateTest.Systems.Plain, " <>
                   "which does not `use Phoenix.Router`",
                 fn -> validate!([Systems.Plain]) end
  end

  test "a router that is no module" do
    Process.put(:validate_test_router, MicaSaas.SaaSValidateTest.Missing)

    assert_raise ArgumentError,
                 ~r/router\/0 names MicaSaas.SaaSValidateTest.Missing, which is not a module/,
                 fn -> validate!([Systems.Plain]) end
  end

  test "an endpoint that is no module" do
    Process.put(:validate_test_endpoint, MicaSaas.SaaSValidateTest.Missing)

    assert_raise ArgumentError,
                 ~r/endpoint\/0 names MicaSaas.SaaSValidateTest.Missing, which is not a module/,
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
                 ~r/lists \[MicaSaas.SaaSValidateTest.Systems.Plain\] more than once/,
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
             "the grant of MicaSaas.SaaSValidateTest.Systems.Page to [:admin] widens another grant"
  end

  test "a widening grant that widens nothing" do
    assert_raise ArgumentError, ~r/is not granted before, so `widen: true` widens nothing/, fn ->
      validate!([Systems.Widen])
    end
  end

  describe "tools, project items and directors" do
    test "are collected from all systems" do
      assert %{
               tools: [Systems.FeldsparTool],
               project_items: [Systems.StorageItem],
               directors: [validate_test: Systems.Page]
             } = validate!([Systems.Tools])
    end

    test "a tool type that two tools declare" do
      assert_raise ArgumentError, ~s(tool type ["feldspar"] is listed more than once), fn ->
        validate!([Systems.Tools, Systems.OtherTools])
      end
    end

    test "a tool schema that two tools share" do
      assert_raise ArgumentError,
                   "tool type schema [Systems.Feldspar.ToolModel] is listed more than once",
                   fn -> validate!([Systems.Tools, Systems.CopyTools]) end
    end

    test "the reserved tool type none" do
      assert_raise ArgumentError, ~s(tool type ["none"] is reserved), fn ->
        validate!([Systems.NoneTools])
      end
    end

    test "a tool whose ToolModel key is not its type" do
      assert_raise ArgumentError,
                   ~s(tool MicaSaas.SaaSValidateTest.Systems.WrongKeyTool has type "feldspar_v2", ) <>
                     ~s(but its schema's Frameworks.Concept.ToolModel.key/1 is "document"),
                   fn -> validate!([Systems.WrongKeyTools]) end
    end

    test "a tool that is no Mica.Tool" do
      assert_raise ArgumentError,
                   ~r/names MicaSaas.SaaSValidateTest.Systems.Page, which does not `use Mica.Tool`/,
                   fn ->
                     validate!([Systems.NotATool])
                   end
    end

    test "a project item type that two item types declare" do
      assert_raise ArgumentError,
                   ~s(project item type ["storage_endpoint"] is listed more than once),
                   fn -> validate!([Systems.Tools, Systems.OtherItems]) end
    end

    test "the reserved project item type none" do
      assert_raise ArgumentError, ~s(project item type ["none"] is reserved), fn ->
        validate!([Systems.NoneItems])
      end
    end

    test "a director that two systems declare" do
      assert_raise ArgumentError, "director [:validate_test] is listed more than once", fn ->
        validate!([Systems.Tools, Systems.OtherDirectors])
      end
    end
  end
end
