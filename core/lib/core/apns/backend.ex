defmodule Core.APNS.Backend do
  @moduledoc false
  @callback send_notification(any()) :: :ok | %{device_token: binary(), response: atom()}
end
