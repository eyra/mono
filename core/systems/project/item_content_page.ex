defmodule Systems.Project.ItemContentPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :projects
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Gettext

  import CoreWeb.Layouts.Workspace.Component

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  alias Systems.{
    Project
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Project.Public.get_item!(id)
  end

  @impl true
  def mount(%{"id" => id, "tab" => initial_tab}, %{"locale" => locale}, socket) do
    model = %{id: String.to_integer(id), director: :project}
    tabbar_id = "project_item_content/#{id}"

    {
      :ok,
      socket
      |> assign(
        id: id,
        model: model,
        tabbar_id: tabbar_id,
        initial_tab: initial_tab,
        locale: locale,
        changesets: %{},
        publish_clicked: false,
        dialog: nil,
        popup: nil,
        side_panel: nil,
        action_map: %{},
        more_actions: []
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> update_tabbar_size()
      |> update_menus()
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", nil), session, socket)
  end

  defoverridable handle_uri: 1

  @impl true
  def handle_uri(socket) do
    socket =
      socket
      |> observe_view_model()
      |> update_actions()
      |> update_menus()

    super(socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
    |> update_actions()
    |> update_menus()
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_tabbar_size()
    |> update_actions()
    |> update_menus()
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

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  @impl true
  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    socket |> Flash.put(type, message, true)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:show_popup, popup}, socket) do
    {:noreply, socket |> assign(popup: popup)}
  end

  @impl true
  def handle_info({:hide_popup}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_info(%{id: form_id, ready?: ready?}, socket) do
    ready_key = String.to_atom("#{form_id}_ready?")

    socket =
      if socket.assigns[ready_key] != ready? do
        socket
        |> assign(ready_key, ready?)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  defp action_map(%{assigns: %{vm: %{actions: actions}}}) do
    actions
    |> Enum.map(&{elem(&1, 0), action(&1)})
    |> Enum.into(%{})
  end

  defp action({:publish, %{action: action}}) do
    %{
      label: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-project", "publish.button"),
          bg_color: "bg-success"
        }
      },
      icon: %{
        action: action,
        face: %{type: :icon, icon: :publish, alt: dgettext("eyra-project", "publish.button")}
      }
    }
  end

  defp action({:preview, %{action: action}}) do
    %{
      label: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-project", "preview.button"),
          bg_color: "bg-primary"
        }
      },
      icon: %{
        action: action,
        face: %{type: :icon, icon: :preview, alt: dgettext("eyra-project", "preview.button")}
      }
    }
  end

  defp action({:retract, %{action: action}}) do
    %{
      label: %{
        action: action,
        face: %{
          type: :secondary,
          label: dgettext("eyra-project", "retract.button"),
          text_color: "text-error",
          border_color: "border-error"
        }
      },
      icon: %{
        action: action,
        face: %{type: :icon, icon: :retract, alt: dgettext("eyra-project", "retract.button")}
      }
    }
  end

  defp action({:close, %{action: action}}) do
    %{
      label: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-project", "close.button")
        }
      },
      icon: %{
        action: action,
        face: %{type: :icon, icon: :close, alt: dgettext("eyra-project", "close.button")}
      }
    }
  end

  defp action({:open, %{action: action}}) do
    %{
      label: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-project", "open.button")
        }
      },
      icon: %{
        action: action,
        face: %{type: :icon, icon: :open, alt: dgettext("eyra-project", "open.button")}
      }
    }
  end

  defp update_actions(socket) do
    action_map = action_map(socket)
    actions = create_actions(action_map, socket)

    socket
    |> assign(
      action_map: action_map,
      actions: actions
    )
  end

  defp create_actions(_, %{assigns: %{breakpoint: {:unknown, _}}} = _socket), do: []

  defp create_actions(
         action_map,
         %{assigns: %{vm: %{actions: actions}}} = socket
       ) do
    actions
    |> Keyword.keys()
    |> Enum.map(&create_action(&1, Map.get(action_map, &1), socket))
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp create_action(_, action, %{assigns: %{breakpoint: breakpoint}}) do
    value(breakpoint, nil,
      xs: %{0 => action.icon},
      md: %{40 => action.label, 100 => action.icon},
      lg: %{50 => action.label}
    )
  end

  defp update_tabbar_size(%{assigns: %{breakpoint: breakpoint}} = socket) do
    tabbar_size = tabbar_size(breakpoint)
    socket |> assign(tabbar_size: tabbar_size)
  end

  defp tabbar_size({:unknown, _}), do: :unknown
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{30 => :wide})

  defp margin_x(:mobile), do: "mx-6"
  defp margin_x(_), do: "mx-10"

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={@vm.title} menus={@menus} >
      <:top_bar>
        <Navigation.action_bar right_bar_buttons={@actions} more_buttons={@more_actions}>
            <Tabbar.container id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} size={@tabbar_size} />
        </Navigation.action_bar>
      </:top_bar>

      <div id="project" phx-hook="LiveContent" data-show-errors={@vm.show_errors}>
        <div id={:questionnaire_content} phx-hook="ViewportResize">

          <%= if @popup do %>
            <.popup>
              <div class={"#{margin_x(@breakpoint)} w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg"}>
                <.live_component module={@popup.module} {@popup.props} />
              </div>
            </.popup>
          <% end %>

          <%= if @dialog do %>
            <.popup>
              <.plain_dialog {@dialog} />
            </.popup>
          <% end %>

          <Tabbar.content tabs={@vm.tabs} />
          <Tabbar.footer tabs={@vm.tabs} />
        </div>
      </div>
    </.workspace>
    """
  end
end
