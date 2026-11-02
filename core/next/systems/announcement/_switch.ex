defmodule Next.Systems.Announcement.Switch do
  @moduledoc """
  Refreshes the Desktop of every recipient when an announcement changes, so
  its Desktop section and To-do show the new title and summary at once.
  """
  use Frameworks.Concept.Switch

  alias Next.Systems.Announcement
  alias Systems.Desktop

  @impl true
  def intercept({:announcement, :updated}, %{announcement: announcement, from_pid: from_pid}) do
    for %{user: user} <- Announcement.Public.list_recipients(announcement, [:user]) do
      update_routed(Desktop.Page, user, from_pid)
    end

    :ok
  end
end
