defmodule Next.Systems.Announcement.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Desktop do
        pipe_through([:browser, :require_authenticated_user])

        live("/announcements", FullListPage, :announcements, as: :announcement_list)
      end

      scope "/announcement", Next.Systems.Announcement do
        pipe_through([:browser, :require_authenticated_user])
        live("/:id", Page)
      end

      scope "/admin/announcement", Next.Systems.Announcement do
        pipe_through([:browser, :require_authenticated_user])
        live("/new", ComposePage)
        live("/:id", ComposePage)
      end
    end
  end
end
