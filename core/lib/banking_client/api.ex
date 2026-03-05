defmodule BankingClient.API do
  @moduledoc false
  @callback send_message(map()) :: map()
end
