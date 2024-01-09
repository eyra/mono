defmodule Systems.Campaign.ContentPage do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :campaign
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.UI.PlainDialog
  use Systems.Observatory.Public

  import CoreWeb.Gettext
  import Core.ImageCatalog, only: [image_catalog: 0]

  alias Core.Accounts
  alias CoreWeb.UI.ImageCatalogPicker
  alias Systems.Promotion.FormView, as: PromotionForm

  alias Systems.{
    Campaign,
    Pool,
    Content
  }

  import Content.Page

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Campaign.Public.get!(id)
  end

  @impl true
  def mount(%{"id" => id} = params, %{"resolved_locale" => locale}, socket) do
    initial_tab = Map.get(params, "tab")
    model = Campaign.Public.get!(String.to_integer(id), Campaign.Model.preload_graph(:down))
    tabbar_id = "campaign_content/#{id}"

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
        submit_clicked: false,
        dialog: nil,
        popup: nil
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> update_tabbar_size()
      |> update_menus()
    }
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
    item = dgettext("link-ui", "delete.confirm.campaign")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {:noreply, socket |> confirm("delete", title, text, confirm_label)}
  end

  @impl true
  def handle_event(
        "delete_confirm",
        _params,
        %{assigns: %{vm: %{id: campaign_id}, current_user: user}} = socket
      ) do
    Campaign.Public.delete(campaign_id)
    start_path = Accounts.start_page_path(user)
    {:noreply, push_redirect(socket, to: start_path)}
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  @impl true
  def handle_event(
        "submit",
        _params,
        %{assigns: %{vm: %{id: campaign_id, submission: submission}}} = socket
      ) do
    socket =
      if Campaign.Public.ready?(campaign_id) do
        {:ok, _submission} = Pool.Public.submit(submission)
        title = dgettext("eyra-submission", "submit.success.title")
        text = dgettext("eyra-submission", "submit.success.text")

        socket
        |> update_view_model()
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "submit.error.title")
        text = dgettext("eyra-submission", "submit.error.text")

        socket
        |> assign(submit_clicked: true)
        |> update_view_model()
        |> inform(title, text)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "retract",
        _params,
        %{assigns: %{vm: %{submission: submission}}} = socket
      ) do
    {:ok, _} = Pool.Public.update(submission, %{status: :idle})
    title = dgettext("eyra-submission", "retract.success.title")
    text = dgettext("eyra-submission", "retract.success.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
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
  def handle_info(
        {:show_image_picker, initial_image_query},
        %{assigns: %{viewport: viewport, breakpoint: breakpoint}} = socket
      ) do
    popup = %{
      module: ImageCatalogPicker,
      props: %{
        id: :image_picker,
        viewport: viewport,
        breakpoint: breakpoint,
        static_path: &CoreWeb.Endpoint.static_path/1,
        initial_query: initial_image_query,
        image_catalog: image_catalog()
      }
    }

    {:noreply, socket |> assign(popup: popup)}
  end

  @impl true
  def handle_info({:image_picker, :close}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_info({:image_picker, image_id}, socket) do
    send_update(PromotionForm, id: :promotion_form, image_id: image_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{id: :inquiry_form, ready?: ready?}, socket),
    do: handle_info(%{id: :assignment_form, ready?: ready?}, socket)

  @impl true
  def handle_info(%{id: :ethical_form, ready?: ready?}, socket),
    do: handle_info(%{id: :assignment_form, ready?: ready?}, socket)

  @impl true
  def handle_info(%{id: :tool_form, ready?: ready?}, socket),
    do: handle_info(%{id: :assignment_form, ready?: ready?}, socket)

  @impl true
  def handle_info(%{id: form, ready?: ready?}, socket) do
    ready_key = String.to_atom("#{form}_ready?")

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
    submit_action = %{type: :send, event: "submit"}
    delete_action = %{type: :send, event: "delete"}
    retract_action = %{type: :send, event: "retract"}
    more_action = %{type: :toggle, id: :more, target: "action_menu"}

    %{
      submit: %{
        label: %{
          action: submit_action,
          face: %{
            type: :primary,
            label: dgettext("link-ui", "submit.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: submit_action,
          face: %{type: :icon, icon: :submit, alt: dgettext("link-ui", "submit.button")}
        }
      },
      preview: %{
        label: %{
          action: preview_action,
          face: %{
            type: :primary,
            label: dgettext("link-ui", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("link-ui", "preview.button")}
        },
        label_icon: %{
          action: preview_action,
          face: %{type: :label, icon: :preview, label: dgettext("link-ui", "preview.button")}
        }
      },
      delete: %{
        icon: %{
          action: delete_action,
          face: %{type: :icon, icon: :delete, alt: dgettext("link-ui", "delete.button")}
        },
        label_icon: %{
          action: delete_action,
          face: %{type: :label, icon: :delete, label: dgettext("link-ui", "delete.button")}
        }
      },
      retract: %{
        icon: %{
          action: retract_action,
          face: %{type: :icon, icon: :retract, alt: dgettext("link-ui", "delete.button")}
        },
        label_icon: %{
          action: retract_action,
          face: %{type: :label, icon: :retract, label: dgettext("link-ui", "retract.button")}
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

  defp update_actions(
         %{assigns: %{breakpoint: breakpoint, vm: %{submitted?: submitted?}}} = socket
       ) do
    actions =
      socket
      |> action_map()
      |> create_actions(breakpoint, submitted?)

    socket |> assign(actions: actions)
  end

  defp create_actions(_, {:unknown, _}, _), do: []

  defp create_actions(%{submit: submit, preview: preview, delete: delete, more: more}, bp, false) do
    submit =
      value(bp, nil,
        xs: %{0 => submit.icon},
        md: %{40 => submit.label, 100 => submit.icon},
        lg: %{50 => submit.label}
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
      submit,
      preview,
      delete,
      more
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp create_actions(%{preview: preview, retract: retract, more: more}, bp, true) do
    preview =
      value(bp, nil,
        xs: %{8 => preview.icon},
        md: %{25 => preview.label, 100 => preview.icon},
        lg: %{20 => preview.label}
      )

    retract = value(bp, nil, xs: %{8 => retract.icon})

    more = value(bp, more.icon, xs: %{8 => nil})

    [
      preview,
      retract,
      more
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp update_more_actions(%{assigns: %{vm: %{submitted?: submitted?}}} = socket) do
    more_actions =
      socket
      |> action_map()
      |> create_more_actions(submitted?)

    socket |> assign(more_actions: more_actions)
  end

  defp create_more_actions(%{preview: preview, delete: delete}, false) do
    [
      preview.label_icon,
      delete.label_icon
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp create_more_actions(%{preview: preview, retract: retract}, true) do
    [
      preview.label_icon,
      retract.label_icon
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp update_tabbar_size(%{assigns: %{breakpoint: breakpoint}} = socket) do
    tabbar_size = tabbar_size(breakpoint)
    socket |> assign(tabbar_size: tabbar_size)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.content_page
      title={@vm.title}
      menus={@menus}
      tabs={@vm.tabs}
      actions={@actions}
      more_actions={@more_actions}
      initial_tab={@initial_tab}
      tabbar_id={@tabbar_id}
      tabbar_size={@tabbar_size}
      breakpoint={@breakpoint}
      popup={@popup}
      dialog={@dialog}
      show_errors={@vm.show_errors}
     />
    """
  end
end
