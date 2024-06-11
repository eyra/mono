defmodule Systems.Content.Composer do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, String.to_atom("__using_#{which}__"), [])
  end

  def __using_live_website__ do
    quote do
      @before_compile {Systems.Content.Composer, :__before_compile_live_website__}
      use CoreWeb, {:live_view, :extended}

      use CoreWeb.Layouts.Website.Composer
      use CoreWeb.LiveDefaults

      use CoreWeb.UI.Popup
      use Frameworks.Pixel.ModalView

      import CoreWeb.Gettext
      import Systems.Content.Html
    end
  end

  defmacro __before_compile_live_website__(_) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, socket) do
        {:ok, socket} = super(params, session, socket)
        {:ok, socket |> assign(popup: nil, dialog: nil, modal: nil)}
      end
    end
  end

  def __using_live_workspace__ do
    quote do
      @before_compile {Systems.Content.Composer, :__before_compile_live_workspace__}
      use CoreWeb, {:live_view, :extended}

      use CoreWeb.Layouts.Workspace.Composer
      use CoreWeb.LiveDefaults

      use CoreWeb.UI.Popup
      use Frameworks.Pixel.ModalView

      import CoreWeb.Gettext
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

  defmacro __before_compile_live_workspace__(_) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, socket) do
        {:ok, socket} = super(params, session, socket)
        {:ok, socket |> assign(popup: nil, dialog: nil, modal: nil)}
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
      @before_compile {Systems.Content.Composer, :__before_compile_management_page__}

      use Systems.Content.Composer, :live_workspace
      use CoreWeb.UI.Responsive.Viewport
      alias CoreWeb.UI.Responsive.Breakpoint

      def tabbar_size({:unknown, _}), do: :unknown
      def tabbar_size(bp), do: Breakpoint.value(bp, :narrow, sm: %{30 => :wide})

      def create_actions(%{assigns: %{breakpoint: {:unknown, _}}} = _socket), do: []

      def create_actions(%{assigns: %{vm: %{actions: actions}}} = socket) do
        actions
        |> Keyword.keys()
        |> Enum.map(&create_action(Keyword.get(actions, &1), socket))
        |> Enum.filter(&(not is_nil(&1)))
      end

      def create_action(action, %{assigns: %{breakpoint: breakpoint}}) do
        Breakpoint.value(breakpoint, nil,
          xs: %{0 => action.icon},
          md: %{40 => action.label, 100 => action.icon},
          lg: %{50 => action.label}
        )
      end

      def update_tabbar_size(%{assigns: %{breakpoint: breakpoint}} = socket) do
        tabbar_size = tabbar_size(breakpoint)
        socket |> assign(tabbar_size: tabbar_size)
      end

      def update_actions(socket) do
        assign(socket, actions: create_actions(socket))
      end

      @impl true
      def handle_event(
            "action_click",
            %{"item" => action_id},
            %{assigns: %{vm: %{actions: actions}}} = socket
          ) do
        action_id = String.to_existing_atom(action_id)
        action = Keyword.get(actions, action_id)

        {
          :noreply,
          socket
          |> action.handle_click.()
          |> update_view_model()
          |> update_actions()
        }
      end
    end
  end

  defmacro __before_compile_management_page__(_) do
    quote do
      defoverridable mount: 3

      @imple true
      def mount(params, session, socket) do
        {:ok, socket} = super(params, session, socket)

        {
          :ok,
          socket
          |> assign_viewport()
          |> assign_breakpoint()
          |> update_actions()
          |> update_tabbar_size()
        }
      end

      defoverridable handle_uri: 1

      @impl true
      def handle_uri(socket) do
        super(socket)
        |> update_actions()
      end

      defoverridable handle_view_model_updated: 1

      @impl true
      def handle_view_model_updated(socket) do
        super(socket)
        |> update_actions()
      end

      defoverridable handle_resize: 1

      @impl true
      def handle_resize(socket) do
        super(socket)
        |> update_tabbar_size()
        |> update_actions()
        |> update_menus()
      end
    end
  end
end
