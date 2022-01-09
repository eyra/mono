defmodule BankingClient.API do
  @callback send_message(map()) :: map()
end
