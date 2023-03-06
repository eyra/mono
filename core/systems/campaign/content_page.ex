defmodule Systems.Campaign.ContentPage do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :campaign
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.UI.PlainDialog

  import CoreWeb.Gettext
  import Core.ImageCatalog, only: [image_catalog: 0]

  alias CoreWeb.ImageCatalogPicker
  alias Systems.Promotion.FormView, as: PromotionForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent, TabbarFooter}

  alias Systems.{
    Campaign,
    Pool
  }

  data(tabbar_id, :string)
  data(validate?, :boolean, default: false)
  data(initial_tab, :any)
  data(actions, :map)
  data(changesets, :any)
  data(initial_image_query, :any)
  data(uri_origin, :any)
  data(popup, :map)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Campaign.Public.get!(id)
  end

  @impl true
  def mount(%{"id" => id, "tab" => initial_tab}, %{"locale" => locale}, socket) do
    model = %{id: String.to_integer(id), director: :campaign}
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
        dialog: nil,
        popup: nil
      )
      |> assign_viewport()
      |> assign_breakpoint()
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
      |> update_menus()

    super(socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_menus()
  end

  defp initial_image_query(%{vm: %{promotion: promotion}}) do
    case promotion.themes do
      nil -> ""
      themes -> themes |> Enum.join(" ")
    end
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
  def handle_event("delete_confirm", _params, %{assigns: %{vm: %{id: campaign_id}}} = socket) do
    Campaign.Public.delete(campaign_id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Console))}
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
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "submit.error.title")
        text = dgettext("eyra-submission", "submit.error.text")

        socket
        |> assign(validate?: true)
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
  def handle_info({:image_picker, image_id}, socket) do
    send_update(PromotionForm, id: :promotion_form, image_id: image_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{id: :experiment_form, ready?: ready?}, socket),
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

  defp margin_x(:mobile), do: "mx-6"
  defp margin_x(_), do: "mx-10"

  defp action_map(%{vm: %{preview_path: preview_path}}) do
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

  defp create_actions(%{breakpoint: breakpoint, vm: %{submitted?: submitted?}} = assigns) do
    create_actions(action_map(assigns), breakpoint, submitted?)
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

  defp create_more_actions(%{vm: %{submitted?: submitted?}} = assigns) do
    create_more_actions(action_map(assigns), submitted?)
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

  defp tabbar_size({:unknown, _}), do: :unknown
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{30 => :wide})

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-survey", "content.title")} menus={@menus}>
      <div id={:survey_content} phx-hook="ViewportResize">
        <div x-data="{ image_picker: false, active_tab: 0, dropdown: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="image_picker">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div
                class={"#{margin_x(@breakpoint)} w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg"}
                x-on:click.away="image_picker = false, $parent.$parent.overlay = false"
              >
                <ImageCatalogPicker
                  id={:image_picker}
                  viewport={@viewport}
                  breakpoint={@breakpoint}
                  static_path={&CoreWeb.Endpoint.static_path/1}
                  initial_query={initial_image_query(assigns)}
                  image_catalog={image_catalog()}
                />
              </div>
            </div>
          </div>
          <Popup :if={@popup}>
            <Dynamic.LiveComponent module={@popup.view} {...@popup.props} />
          </Popup>
          <Popup :if={@dialog}>
            <PlainDialog {...@dialog} />
          </Popup>
          <TabbarArea tabs={@vm.tabs}>
            <ActionBar
              right_bar_buttons={create_actions(assigns)}
              more_buttons={create_more_actions(assigns)}
            >
              <Tabbar id={@tabbar_id} initial_tab={@initial_tab} size={tabbar_size(@breakpoint)} />
            </ActionBar>
            <TabbarContent />
            <TabbarFooter />
          </TabbarArea>
        </div>
      </div>
    </Workspace>
    """
  end
end
