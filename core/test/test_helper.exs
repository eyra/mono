require Promox

# Start Wallaby for feature tests
{:ok, _} = Application.ensure_all_started(:wallaby)

Promox.defmock(for: Frameworks.Concept.Branch)

# Ensure test signal handlers are compiled and loaded
Code.ensure_loaded!(Frameworks.Signal.TestRecorder)
Code.ensure_loaded!(Frameworks.Signal.TestForceSwitch)
Code.ensure_loaded!(Frameworks.Signal.TestCatchAll)

ExUnit.start(exclude: [:slow])
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)

Mox.defmock(MockAws, for: ExAws.Behaviour)

Mox.defmock(Core.WebPush.MockBackend, for: Core.WebPush.Backend)
Application.put_env(:core, :web_push_backend, Core.WebPush.MockBackend)

Mox.defmock(Core.APNS.MockBackend, for: Core.APNS.Backend)
Application.put_env(:core, :apns_backend, Core.APNS.MockBackend)

# TestHelper should not be globally added - it should only be active
# when tests explicitly call isolate_signals()
# Removed incorrect global TestHelper configuration

Application.put_env(
  :core,
  :admins,
  Systems.Admin.Public.compile([
    "admin1@example.org",
    "admin2@example.org"
  ])
)

Mox.defmock(Systems.Banking.MockBackend, for: Systems.Banking.Backend)
Application.put_env(:core, :banking_backend, Systems.Banking.MockBackend)

Mox.defmock(BankingClient.MockClient, for: BankingClient.API)
Application.put_env(:core, BankingClient, client: BankingClient.MockClient)

Mox.defmock(Systems.Storage.MockBackend, for: Systems.Storage.Backend)
Mox.defmock(Systems.Storage.BuiltIn.MockSpecial, for: Systems.Storage.BuiltIn.Special)
Mox.defmock(Systems.Storage.MockTempFileStore, for: Systems.Storage.TempFileStore)
Mox.defmock(Systems.Storage.MockJobScheduler, for: Systems.Storage.JobScheduler)

defmodule Core.Test.SandboxLogFilter do
  @moduledoc """
  Drops the benign SQL sandbox teardown disconnect logs that appear during the
  test suite.

  When a test process (the sandbox connection owner) exits while a process it
  spawned is still running a query — typically a LiveView re-rendering, or
  Ecto's parallel preloader (`maybe_pmap`) running association fetches in
  `Task.async_stream` — DBConnection logs an `owner #PID<...> exited` /
  `Client #PID<...> is still using a connection from owner` error. The
  transaction is rolled back by the sandbox; the message is teardown-timing
  noise, not a real failure.

  This filter is intentionally narrow: a genuine in-test database failure
  surfaces as a `Postgrex.Error` (a SQL error), which does not match the
  signature below and is left untouched.
  """

  def filter(log_event, _extra) do
    if sandbox_teardown?(log_event), do: :stop, else: :ignore
  end

  defp sandbox_teardown?(%{msg: msg}) do
    text = message_text(msg)

    String.contains?(text, "still using a connection from owner") or
      (String.contains?(text, "owner #PID") and String.contains?(text, "exited"))
  end

  defp sandbox_teardown?(_log_event), do: false

  defp message_text({:string, chardata}), do: safe_chardata(chardata)
  defp message_text({:report, report}), do: inspect(report)

  defp message_text({format, args}) when is_list(format) and is_list(args) do
    safe_chardata(:io_lib.format(format, args))
  end

  defp message_text(other), do: inspect(other)

  defp safe_chardata(chardata) do
    IO.chardata_to_string(chardata)
  rescue
    _ -> inspect(chardata)
  end
end

:logger.add_primary_filter(
  :silence_sandbox_teardown,
  {&Core.Test.SandboxLogFilter.filter/2, []}
)
