ExUnit.start()

Mox.defmock(Bunq.MockHTTP, for: HTTPoison.Base)
Application.put_env(:bunq, :http_client, Bunq.MockHTTP)
