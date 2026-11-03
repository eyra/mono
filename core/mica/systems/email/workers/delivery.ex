defmodule Systems.Email.Delivery do
  use Oban.Worker, queue: :email_delivery
  require Logger

  alias Systems.{
    Email
  }

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

  defp deliver(
         %{
           "to" => to,
           "from" => from,
           "title" => title,
           "byline" => byline,
           "message" => message
         } = args
       ) do
    deliver(%Email.Model{
      to: to,
      from: from,
      subject: Map.get(args, "subject"),
      title: title,
      byline: byline,
      message: message,
      html_message: Map.get(args, "html_message")
    })
  end

  defp deliver(%Email.Model{} = email) do
    Email.Public.deliver_now(email)
  end
end
