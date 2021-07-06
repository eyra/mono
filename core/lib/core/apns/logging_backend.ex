defmodule Core.APNS.LoggingBackend do
  @behaviour Core.APNS.Backend
  require Logger

  def send_notification(notification) do
    Logger.info("APNS notification: #{inspect(notification)}")
  end
end
