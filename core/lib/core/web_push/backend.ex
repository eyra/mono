defmodule Core.WebPush.Backend do
  @callback send_web_push(binary(), map()) :: {:ok, %{status_code: integer()}} | {:error, atom}
end
