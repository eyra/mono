ExUnit.start()

Mox.defmock(Bunq.MockHTTP, for: HTTPoison.Base)
Mox.defmock(MockBankingBackend, for: BankingProxy.BankingBackend)
Mox.defmock(MockRanchTransport, for: :ranch_transport)

Application.put_env(:bunq, :http_client, Bunq.MockHTTP)
