ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)

Mox.defmock(Core.WebPush.MockBackend, for: Core.WebPush.Backend)
Application.put_env(:core, :web_push_backend, Core.WebPush.MockBackend)

Mox.defmock(Core.APNS.MockBackend, for: Core.APNS.Backend)
Application.put_env(:core, :apns_backend, Core.APNS.MockBackend)

Application.put_env(:core, :signal_handlers, [Core.Signals.Test])

Application.put_env(
  :core,
  :admins,
  MapSet.new([
    "admin1@example.org",
    "admin2@example.org"
  ])
)
