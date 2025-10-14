defmodule Systems.Content.Composer do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, String.to_atom("__using_#{which}__"), [])
  end

  def __using_live_website__ do
    quote do
      use CoreWeb, :live_view

      use CoreWeb.Layouts.Website.Composer
      use CoreWeb.LiveDefaults

      use Gettext, backend: CoreWeb.Gettext
      import Systems.Content.Html
    end
  end

  def __using_live_workspace__ do
    quote do
      use CoreWeb, :live_view

      use CoreWeb.Layouts.Workspace.Composer
      use CoreWeb.LiveDefaults

      use Gettext, backend: CoreWeb.Gettext
      import Systems.Content.Html

      @impl true
      def handle_event("inform_ok", _params, socket) do
        {:noreply, socket |> assign(dialog: nil)}
      end

      @impl true
      def handle_info({:signal_test, _}, socket) do
        {:noreply, socket}
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
end
