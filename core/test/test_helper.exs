ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)

Mox.defmock(Core.WebPush.MockBackend, for: Core.WebPush.Backend)
Application.put_env(:core, :web_push_backend, Core.WebPush.MockBackend)

Mox.defmock(Core.APNS.MockBackend, for: Core.APNS.Backend)
Application.put_env(:core, :apns_backend, Core.APNS.MockBackend)

Application.put_env(:core, :signal_handlers, [Frameworks.Signal.TestHelper])

Application.put_env(
  :core,
  :admins,
  Systems.Admin.Context.compile([
    "admin1@example.org",
    "admin2@example.org"
  ])
)

Mox.defmock(Systems.Banking.MockBackend, for: Systems.Banking.Backend)
Application.put_env(:core, :banking_backend, Systems.Banking.MockBackend)
