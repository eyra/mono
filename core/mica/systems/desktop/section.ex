defmodule Systems.Desktop.Section do
  @moduledoc """
  A section on the Desktop page (`/desktop`), shown after Recent items.

  Systems contribute sections with `c:Mica.System.desktop_sections/0`; the page
  shows them in `c:Mica.SaaS.systems/0` order.

      defmodule Systems.Notes.DesktopSection do
        use Systems.Desktop.Section
        use Gettext, backend: MicaWeb.Gettext

        alias Systems.Notes

        @impl true
        def id, do: :notes

        @impl true
        def title, do: dgettext("eyra-notes", "desktop.title")

        @impl true
        def view_model(user, _assigns) do
          case Notes.Public.list_unread(user) do
            [] -> nil
            notes -> %{notes: notes}
          end
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <Notes.View.list notes={@vm.notes} />
          \"\"\"
        end
      end

  Sections are display-only: they render inside `Systems.Desktop.View`, which
  handles none of their events, so a `phx-click` in a section crashes the view.
  Links to other pages work.

  The page builds the section's view model with the page's, so a section
  refreshes when the page does. To refresh it live, the section's system has
  its own Switch that intercepts the signals of its data and calls
  `update_routed(Systems.Desktop.Page, user, from_pid)` for the affected user.
  """

  @doc "The section id. The section's element id is `desktop_section_<id>`."
  @callback id() :: atom()

  @callback title() :: String.t()

  @doc """
  The section's view model for `user`, built with the page's view model from
  the page's `assigns`. `nil` hides the section.
  """
  @callback view_model(user :: map(), assigns :: map()) :: map() | nil

  @doc "Renders the section's content. `@vm` is the result of `c:view_model/2`."
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Desktop.Section
      use MicaWeb, :html
    end
  end
end
