defmodule Next.Systems.Announcement.Routes do
  defmacro routes() do
    quote do
      scope "/announcement", Next.Systems.Announcement do
        pipe_through([:browser, :require_authenticated_user])
        live("/:id", Page)
      end
    end
  end
end
