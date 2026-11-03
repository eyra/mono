defmodule Next.Systems.Announcement.DeliverJob do
  @moduledoc """
  Gives the recipients of a just-published announcement their recipient rows
  and To-dos, and for a high-priority announcement their emails
  (`Next.Systems.Announcement.Public.deliver_announcement/1`). Running it again
  adds and sends nothing, so a retry is safe.
  """
  use Oban.Worker, queue: :default

  alias Next.Systems.Announcement

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"announcement_id" => announcement_id}}) do
    case Announcement.Public.deliver_announcement(announcement_id) do
      {:ok, _count} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
