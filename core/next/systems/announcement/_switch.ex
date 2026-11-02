defmodule Systems.Announcement.Switch do
  @moduledoc """
  Refreshes the Desktop of every recipient when an announcement changes, so
  its Desktop section and To-do show the new title and summary at once, and
  the announcement page of a recipient who has it open, so it shows the new
  text. Both read the text from the database when the message arrives, so a
  message that arrives late never brings back older text.
  """
  use Frameworks.Concept.Switch

  alias Systems.Announcement
  alias Systems.Desktop

  @impl true
  def intercept({:announcement, :updated}, %{announcement: announcement, from_pid: from_pid}) do
    for %{user: user} = recipient <- Announcement.Public.list_recipients(announcement, [:user]) do
      update_routed(Desktop.Page, user, from_pid)
      update_routed(Announcement.Page, recipient, from_pid)
    end

    :ok
  end
end
