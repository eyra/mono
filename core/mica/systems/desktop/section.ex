defmodule Systems.Desktop.Section do
  @moduledoc """
  A section on the Desktop page (`/desktop`), shown after Recent items, or
  before them when `c:placement/0` says so.

  Systems contribute sections with `c:Mica.System.desktop_sections/0`; the page
  shows the sections of each placement in `c:Mica.SaaS.systems/0` order.

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

  A preview can expose a full-list link with `c:full_list/1`. To reuse the
  generic full-list page, route `Systems.Desktop.FullListPage` with this
  section's id as its LiveView action and implement `c:full_view_model/2`.
  The same `c:render/1` renders that content, including its empty state.
  Returning nil makes the full page unavailable. Updates can target the
  generic page with the current user, just like Desktop updates.

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

  @type placement :: :before_recent_items | :after_recent_items

  @doc "Where the section goes relative to Recent items. Defaults to `:after_recent_items`."
  @callback placement() :: placement()

  @doc "Optional navigation from a preview section to its full list."
  @callback full_list(vm :: map()) :: %{label: String.t(), to: String.t()} | nil

  @doc "Full-list content for this section; nil means the full page is unavailable."
  @callback full_view_model(user :: map(), assigns :: map()) :: map() | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Desktop.Section
      use MicaWeb, :html

      @impl Systems.Desktop.Section
      def placement, do: :after_recent_items

      @impl Systems.Desktop.Section
      def full_list(_vm), do: nil

      @impl Systems.Desktop.Section
      def full_view_model(_user, _assigns), do: nil

      defoverridable placement: 0, full_list: 1, full_view_model: 2
    end
  end
end
