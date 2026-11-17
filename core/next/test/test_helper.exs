# Next's suite (`BUNDLE=next mix test`) runs on its own, so it has its own copy of
# the setup in mica/test/test_helper.exs.
require Promox

# Start Wallaby for feature tests
{:ok, _} = Application.ensure_all_started(:wallaby)

Promox.defmock(for: Frameworks.Concept.Branch)

# Ensure test signal handlers are compiled and loaded
Code.ensure_loaded!(Frameworks.Signal.TestRecorder)
Code.ensure_loaded!(Frameworks.Signal.TestForceSwitch)
Code.ensure_loaded!(Frameworks.Signal.TestCatchAll)

ExUnit.start(exclude: [:slow], capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(Mica.Repo, :manual)

Mox.defmock(MockAws, for: ExAws.Behaviour)

# TestHelper should not be globally added - it should only be active
# when tests explicitly call isolate_signals()
# Removed incorrect global TestHelper configuration

Application.put_env(
  :mica,
  :admins,
  Systems.Admin.Public.compile([
    "admin1@example.org",
    "admin2@example.org"
  ])
)

Mox.defmock(Systems.Storage.MockBackend, for: Systems.Storage.Backend)
Mox.defmock(Systems.Storage.BuiltIn.MockSpecial, for: Systems.Storage.BuiltIn.Special)
Mox.defmock(Systems.Storage.MockTempFileStore, for: Systems.Storage.TempFileStore)
Mox.defmock(Systems.Storage.MockJobScheduler, for: Systems.Storage.JobScheduler)

:logger.add_primary_filter(
  :silence_sandbox_teardown,
  {&Mica.Test.SandboxLogFilter.filter/2, []}
)
