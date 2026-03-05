defmodule Core.WebPush.Backend do
  @moduledoc false
  @callback send_web_push(binary(), map()) :: {:ok, %{status_code: integer()}} | {:error, atom}
end
