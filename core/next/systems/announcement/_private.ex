defmodule Systems.Announcement.Private do
  @doc """
  The path of the announcement page (`Systems.Announcement.Routes`). A plain
  path, not `~p`: other SaaS builds compile this system without its routes.
  """
  def page_path(announcement_id), do: "/announcement/#{announcement_id}"
end
