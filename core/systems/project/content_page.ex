defmodule Systems.Project.ContentPage do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :project
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Gettext

  alias Core.Accounts
  import CoreWeb.Layouts.Workspace.Component

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  alias Systems.{
    Project
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Project.Public.get!(id)
  end

  @impl true
  def mount(%{"id" => id, "tab" => initial_tab}, %{"locale" => locale}, socket) do
    model = %{id: String.to_integer(id), director: :project}
    tabbar_id = "project_content/#{id}"

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
        side_panel: nil
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
      |> update_more_actions()
      |> update_menus()

    super(socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
    |> update_actions()
    |> update_more_actions()
    |> update_menus()
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_tabbar_size()
    |> update_actions()
    |> update_more_actions()
    |> update_menus()
  end

  @impl true
  def handle_event("delete", _params, socket) do
    item = dgettext("eyra-project", "delete.confirm")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {:noreply, socket |> confirm("delete", title, text, confirm_label)}
  end

  @impl true
  def handle_event(
        "delete_confirm",
        _params,
        %{assigns: %{vm: %{id: project_id}, current_user: user}} = socket
      ) do
    Project.Public.delete(project_id)
    start_page = Accounts.start_page_target(user)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, start_page))}
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  @impl true
  def handle_event(
        "publish",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "conceal",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("preview", _params, socket) do
    title = dgettext("eyra-ui", "feature.unavailable.title")
    text = dgettext("eyra-ui", "feature.unavailable.text")

    {
      :noreply,
      socket
      |> inform(title, text)
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

  defp action_map(%{assigns: %{vm: %{preview_path: preview_path}}}) do
    preview_action = %{type: :redirect, to: preview_path}
    publish_action = %{type: :send, event: "publish"}
    delete_action = %{type: :send, event: "delete"}
    conceal_action = %{type: :send, event: "conceal"}
    more_action = %{type: :toggle, id: :more, target: "action_menu"}

    %{
      publish: %{
        label: %{
          action: publish_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-project", "publish.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: publish_action,
          face: %{type: :icon, icon: :publish, alt: dgettext("eyra-project", "publish.button")}
        }
      },
      preview: %{
        label: %{
          action: preview_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-project", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-project", "preview.button")}
        },
        label_icon: %{
          action: preview_action,
          face: %{type: :label, icon: :preview, label: dgettext("eyra-project", "preview.button")}
        }
      },
      delete: %{
        icon: %{
          action: delete_action,
          face: %{type: :icon, icon: :delete, alt: dgettext("eyra-project", "delete.button")}
        },
        label_icon: %{
          action: delete_action,
          face: %{type: :label, icon: :delete, label: dgettext("eyra-project", "delete.button")}
        }
      },
      conceal: %{
        icon: %{
          action: conceal_action,
          face: %{type: :icon, icon: :conceal, alt: dgettext("eyra-project", "delete.button")}
        },
        label_icon: %{
          action: conceal_action,
          face: %{type: :label, icon: :conceal, label: dgettext("eyra-project", "conceal.button")}
        }
      },
      more: %{
        icon: %{
          action: more_action,
          face: %{type: :icon, icon: :more, alt: "Show more actions"}
        }
      }
    }
  end

  defp update_actions(%{assigns: %{breakpoint: breakpoint}} = socket) do
    actions =
      socket
      |> action_map()
      |> create_actions(breakpoint, false)

    socket |> assign(actions: actions)
  end

  defp create_actions(_, {:unknown, _}, _), do: []

  defp create_actions(
         %{publish: publish, preview: preview, delete: delete, more: more},
         bp,
         false
       ) do
    publish =
      value(bp, nil,
        xs: %{0 => publish.icon},
        md: %{40 => publish.label, 100 => publish.icon},
        lg: %{50 => publish.label}
      )

    preview =
      value(bp, nil,
        xs: %{25 => preview.icon},
        sm: %{30 => nil},
        md: %{0 => preview.icon, 60 => preview.label, 100 => nil},
        lg: %{14 => preview.icon, 75 => preview.label}
      )

    delete =
      value(bp, nil,
        xs: %{25 => delete.icon},
        sm: %{30 => nil},
        md: %{0 => delete.icon, 100 => nil},
        lg: %{14 => delete.icon}
      )

    more =
      value(bp, more.icon,
        xs: %{25 => nil},
        sm: %{30 => more.icon},
        md: %{0 => nil, 100 => more.icon},
        lg: %{14 => nil}
      )

    [
      publish,
      preview,
      delete,
      more
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  # defp create_actions(%{preview: preview, conceal: conceal, more: more}, bp, true) do
  #   preview =
  #     value(bp, nil,
  #       xs: %{8 => preview.icon},
  #       md: %{25 => preview.label, 100 => preview.icon},
  #       lg: %{20 => preview.label}
  #     )

  #   conceal = value(bp, nil, xs: %{8 => conceal.icon})

  #   more = value(bp, more.icon, xs: %{8 => nil})

  #   [
  #     preview,
  #     conceal,
  #     more
  #   ]
  #   |> Enum.filter(&(not is_nil(&1)))
  # end

  defp update_more_actions(socket) do
    published? = false

    more_actions =
      socket
      |> action_map()
      |> create_more_actions(published?)

    socket |> assign(more_actions: more_actions)
  end

  defp create_more_actions(%{preview: preview, delete: delete}, false) do
    [
      preview.label_icon,
      delete.label_icon
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  # defp create_more_actions(%{preview: preview, conceal: conceal}, true) do
  #   [
  #     preview.label_icon,
  #     conceal.label_icon
  #   ]
  #   |> Enum.filter(&(not is_nil(&1)))
  # end

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
    <.workspace title={dgettext("eyra-project", "content.title")} menus={@menus} >
      <:top_bar>
        <Navigation.action_bar right_bar_buttons={@actions} more_buttons={@more_actions}>
            <Tabbar.container id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} size={@tabbar_size} />
        </Navigation.action_bar>
      </:top_bar>

      <div id="project" phx-hook="LiveContent" data-show-errors={@vm.show_errors}>
        <div id={:survey_content} phx-hook="ViewportResize">

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
