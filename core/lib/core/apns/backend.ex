defmodule Core.APNS.Backend do
  @callback send_notification(any()) :: :ok | %{device_token: binary(), response: atom()}
end
