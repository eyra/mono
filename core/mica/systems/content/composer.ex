defmodule Systems.Content.Composer do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, String.to_atom("__using_#{which}__"), [])
  end

  defmacro __using__({which, :live_nest}) when is_atom(which) do
    apply(__MODULE__, String.to_atom("__using_#{which}_live_nest__"), [])
  end

  def __using_live_website__ do
    quote do
      use MicaWeb, :live_view_fabric

      use MicaWeb.Layouts.Website.Composer
      use MicaWeb.LiveDefaults

      use Gettext, backend: MicaWeb.Gettext
      import Systems.Content.Html
    end
  end

  def __using_live_workspace__ do
    quote do
      use MicaWeb, :live_view_fabric

      use MicaWeb.Layouts.Workspace.Composer
      use MicaWeb.LiveDefaults

      use Gettext, backend: MicaWeb.Gettext
      import Systems.Content.Html

      @impl true
      def handle_event("inform_ok", _params, socket) do
        {:noreply, socket |> assign(dialog: nil)}
      end
    end
  end

  def __using_tabbar_page__ do
    quote do
      use Systems.Content.Composer, :live_workspace
    end
  end

  def __using_management_page__ do
    quote do
      use Systems.Content.Composer, :live_workspace
    end
  end

  def __using_live_workspace_live_nest__ do
    quote do
      use MicaWeb, :routed_live_view

      use MicaWeb.Layouts.Workspace.Composer, :live_nest
      use MicaWeb.LiveDefaults

      use Gettext, backend: MicaWeb.Gettext
      import Systems.Content.Html

      @impl true
      def handle_event("inform_ok", _params, socket) do
        {:noreply, socket |> assign(dialog: nil)}
      end
    end
  end

  def __using_tabbar_page_live_nest__ do
    quote do
      use Systems.Content.Composer, {:live_workspace, :live_nest}
    end
  end

  def __using_management_page_live_nest__ do
    quote do
      use Systems.Content.Composer, {:live_workspace, :live_nest}
    end
  end
end
