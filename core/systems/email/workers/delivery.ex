defmodule Systems.Email.Delivery do
  @moduledoc false
  use Oban.Worker, queue: :email_delivery

  alias Systems.Email

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case deliver(args) do
      {:error, error} ->
        Logger.error("Email delivery error: #{error}")
        :error

      _ ->
        Logger.debug("Email delivery succeeded")
        :ok
    end
  end

  defp deliver(%{"to" => to, "from" => from, "title" => title, "byline" => byline, "message" => message}) do
    deliver(%Email.Model{
      to: to,
      from: from,
      title: title,
      byline: byline,
      message: message
    })
  end

  defp deliver(%Email.Model{} = email) do
    Email.Public.deliver_now(email)
  end
end
