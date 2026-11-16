require Promox

# Mica's own suite runs with no SaaS (no BUNDLE): on a composition of Mica's
# systems, with no SaaS module, router or endpoint. A `Mica.SaaS` callback
# raises in it. `mix test` doesn't start the app for this suite (mix.exs), so it
# starts here, on this composition.
Mica.SaaS.put_composition(systems: Mica.Systems.all())
{:ok, _} = Application.ensure_all_started(:mica)

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
