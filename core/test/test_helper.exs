ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)

Mox.defmock(Core.WebPush.MockBackend, for: Core.WebPush.Backend)
Application.put_env(:core, :web_push_backend, Core.WebPush.MockBackend)
