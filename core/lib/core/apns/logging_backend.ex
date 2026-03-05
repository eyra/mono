defmodule Core.APNS.LoggingBackend do
  @moduledoc false
  @behaviour Core.APNS.Backend

  require Logger

  def send_notification(notification) do
    Logger.info("APNS notification: #{inspect(notification)}")
  end
end
