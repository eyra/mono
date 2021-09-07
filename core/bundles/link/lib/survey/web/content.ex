defmodule Link.Survey.Content do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :survey
  use CoreWeb.UI.Responsive.Viewport
  use CoreWeb.UI.Dialog

  import CoreWeb.Gettext

  alias Core.Survey.Tools
  alias Core.Promotions
  alias Core.Pools.Submissions
  alias Core.Content.Nodes

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.Promotion.Form, as: PromotionForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent, TabbarFooter}
  alias Link.Survey.Monitor
  alias Link.Survey.Form, as: ToolForm
  alias Link.Pool.Form.Submission, as: SubmissionForm

  data(tool_id, :any)
  data(promotion_id, :any)
  data(submission_id, :any)
  data(submitted?, :any)
  data(validate?, :any)
  data(initial_tab, :any)
  data(tabs, :map)
  data(actions, :map)
  data(changesets, :any)
  data(initial_image_query, :any)
  data(uri_origin, :any)
  data(dialog, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Tools.get_survey_tool!(id)
  end

  @impl true
  def mount(%{"id" => tool_id, "tab" => initial_tab}, _session, socket) do
    tool = Tools.get_survey_tool!(tool_id)
    promotion = Promotions.get!(tool.promotion_id)
    submission = Submissions.get!(promotion)
    submitted? = submission.status != :idle
    validate? = submitted?

    tool_form_ready? = Tools.ready?(tool)
    promotion_form_ready? = Promotions.ready?(promotion)

    {
      :ok,
      socket
      |> assign(
        tool_id: tool_id,
        promotion_id: tool.promotion_id,
        submission_id: submission.id,
        submitted?: submitted?,
        validate?: validate?,
        tool_form_ready?: tool_form_ready?,
        promotion_form_ready?: promotion_form_ready?,
        initial_tab: initial_tab,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil,
        dialog: nil
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> update_menus()
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", "promotion_form"), session, socket)
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    parsed_uri = URI.parse(uri)
    uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"

    {
      :noreply,
      socket
      |> assign(uri_origin: uri_origin)
      |> create_tabs()
    }
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_menus()
  end

  defp create_tabs(
    %{
      assigns:
      %{
        uri_origin: uri_origin,
        tool_id: tool_id,
        validate?: validate?,
        tool_form_ready?: tool_form_ready?,
        promotion_form_ready?: promotion_form_ready?
      }
    } = socket) do

    tool = Tools.get_survey_tool!(tool_id)
    promotion = Promotions.get!(tool.promotion_id)
    submission = Submissions.get!(promotion)

    tabs = [
      %{
        id: :promotion_form,
        ready?: !validate? || promotion_form_ready?,
        title: dgettext("link-survey", "tabbar.item.promotion"),
        forward_title: dgettext("link-survey", "tabbar.item.promotion.forward"),
        type: :fullpage,
        component: PromotionForm,
        props: %{
          entity_id: promotion.id,
          validate?: validate?
        }
      },
      %{
        id: :tool_form,
        ready?: !validate? || tool_form_ready?,
        title: dgettext("link-survey", "tabbar.item.survey"),
        forward_title: dgettext("link-survey", "tabbar.item.survey.forward"),
        type: :fullpage,
        component: ToolForm,
        props: %{
          entity_id: tool.id,
          uri_origin: uri_origin,
          validate?: validate?
        },
      },
      %{
        id: :criteria_form,
        title: dgettext("link-survey", "tabbar.item.criteria"),
        forward_title: dgettext("link-survey", "tabbar.item.criteria.forward"),
        type: :fullpage,
        component: SubmissionForm,
        props: %{
          entity_id: submission.id
        },
      },
      %{
        id: :monitor,
        title: dgettext("link-survey", "tabbar.item.monitor"),
        forward_title: dgettext("link-survey", "tabbar.item.monitor.forward"),
        type: :fullpage,
        component: Monitor,
        props: %{
          entity_id: tool.id,
        }
      }
    ]

    socket
    |> assign(tabs: tabs)
  end

  @impl true
  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  defp initial_image_query(%{promotion_id: promotion_id}) do
    promotion = Promotions.get!(promotion_id)

    case promotion.themes do
      nil -> ""
      themes -> themes |> Enum.map(&Atom.to_string(&1)) |> Enum.join(" ")
    end
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(ToolForm, id: :tool_form, focus: "")
    send_update(PromotionForm, id: :promotion_form, focus: "")
    {:noreply, socket}
  end

  def handle_event("delete", _params, socket) do
    item = dgettext("link-ui", "delete.confirm.campaign")
    title = dgettext("eyra-ui", "delete.confirm.title", item: item)
    text = dgettext("eyra-ui", "delete.confirm.text", item: item)
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {:noreply, socket |> confirm("delete", title, text, confirm_label)}
  end

  def handle_event("delete_confirm", _params, %{assigns: %{tool_id: tool_id}} = socket) do
    Tools.get_survey_tool!(tool_id)
    |> Tools.delete_survey_tool()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  # Events
  def handle_event("submit", _params, %{assigns: %{submission_id: submission_id}} = socket) do
    submission = Submissions.get!(submission_id)

    socket =
      if Nodes.ready?(submission.content_node) do
        {:ok, _submission} = Submissions.update(submission, %{status: :submitted})

        title = dgettext("eyra-submission", "submit.success.title")
        text = dgettext("eyra-submission", "submit.success.text")

        socket
        |> assign(submitted?: true)
        |> create_tabs()
        |> inform(title, text)
      else
        title = dgettext("eyra-submission", "submit.error.title")
        text = dgettext("eyra-submission", "submit.error.text")

        socket
        |> assign(validate?: true)
        |> create_tabs()
        |> inform(title, text)
      end

    { :noreply, socket}
  end

  def handle_event("retract", _params, %{assigns: %{submission_id: submission_id}} = socket) do
    submission = Submissions.get!(submission_id)
    {:ok, _submission} = Submissions.update(submission, %{status: :idle})

    title = dgettext("eyra-submission", "retract.success.title")
    text = dgettext("eyra-submission", "retract.success.text")

    {
      :noreply,
      socket
      |> assign(submitted?: false)
      |> inform(title, text)
    }
  end

  def handle_event("preview", _params, socket) do
    title = dgettext("eyra-ui", "feature.unavailable.title")
    text = dgettext("eyra-ui", "feature.unavailable.text")

    {
      :noreply,
      socket
      |> inform(title, text)
    }
  end

  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  def handle_info({:claim_focus, :tool_form}, socket) do
    send_update(PromotionForm, id: :promotion_form, focus: "")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :promotion_form}, socket) do
    send_update(ToolForm, id: :tool_form, focus: "")
    {:noreply, socket}
  end

  def handle_info({:image_picker, image_id}, socket) do
    send_update(PromotionForm, id: :promotion_form, image_id: image_id)
    {:noreply, socket}
  end

  def handle_info(%{id: form, ready?: ready?}, socket) do

    ready_key = String.to_atom("#{form}_ready?")

    socket =
      if socket.assigns[ready_key] != ready? do
        socket
        |> assign(ready_key, ready? )
        |> create_tabs()
      else
        socket
      end

    {:noreply, socket}
  end


  defp marginX(:mobile), do: "mx-6"
  defp marginX(_), do: "mx-10"

  defp action_map() do
    %{
      submit: %{
        label: %{
          action: %{ type: :send, event: "submit"},
          face: %{ type: :primary, label: dgettext("link-ui", "submit.button"), bg_color: "bg-success"}
        },
        icon: %{
          action: %{ type: :send, event: "submit"},
          face: %{ type: :icon, icon: :submit}
        }
      },
      preview: %{
        label: %{
          action: %{ type: :send, event: "preview"},
          face: %{ type: :primary, label: dgettext("link-ui", "preview.button"), bg_color: "bg-primary"}
        },
        icon: %{
          action: %{ type: :send, event: "preview"},
          face: %{ type: :icon, icon: :preview}
        },
        label_icon: %{
          action: %{ type: :send, event: "preview"},
          face: %{ type: :label, icon: :preview, label: dgettext("link-ui", "preview.button")}
        }
      },
      delete: %{
        icon: %{
          action: %{ type: :send, event: "delete"},
          face: %{ type: :icon, icon: :delete }
        },
        label_icon: %{
          action: %{ type: :send, event: "delete"},
          face: %{ type: :label, icon: :delete, label: dgettext("link-ui", "delete.button") }
        }
      },
      retract: %{
        icon: %{
          action: %{ type: :send, event: "retract"},
          face: %{ type: :icon, icon: :retract }
        },
        label_icon: %{
          action: %{ type: :send, event: "retract"},
          face: %{ type: :label, icon: :retract, label: dgettext("link-ui", "retract.button") }
        }
      },
      more: %{
        icon: %{
          action: %{ type: :toggle, id: :more, target: "action_menu" },
          face: %{ type: :icon, icon: :more }
        }
      },
    }
  end

  defp create_actions(breakpoint, submitted?) do
    create_actions(action_map(), breakpoint, submitted?)
  end

  defp create_actions(_, {:unknown, _}, _), do: []

  defp create_actions(%{submit: submit, preview: preview, delete: delete, more: more}, bp, false) do
    submit =
      value(bp, nil,
        xs: %{ 0 => submit.icon },
        md: %{ 40 => submit.label, 100 => submit.icon },
        lg: %{ 50 => submit.label}
      )

    preview =
      value(bp, nil,
        xs: %{ 25 => preview.icon},
        sm: %{ 30 => nil},
        md: %{ 0 => preview.icon, 60 => preview.label, 100 => nil },
        lg: %{ 14 => preview.icon, 75 => preview.label }
      )

    delete =
      value(bp, nil,
        xs: %{ 25 => delete.icon},
        sm: %{ 30 => nil},
        md: %{ 0 => delete.icon, 100 => nil },
        lg: %{ 14 => delete.icon }
      )

    more =
      value(bp, more.icon,
        xs: %{ 25 => nil},
        sm: %{ 30 => more.icon},
        md: %{ 0 => nil, 100 => more.icon },
        lg: %{ 14 => nil }
      )

    [
      submit, preview, delete, more
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp create_actions(%{preview: preview, retract: retract, more: more}, bp, true) do

    preview =
      value(bp, nil,
        xs: %{ 8 => preview.icon },
        md: %{ 25 => preview.label, 100 => preview.icon },
        lg: %{ 20 => preview.label}
      )

    retract =
      value(bp, nil,
        xs: %{ 8 => retract.icon}
      )

    more =
      value(bp, more.icon,
        xs: %{ 8 => nil}
      )

    [
      preview, retract, more
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end


  defp create_more_actions(submitted?) do
    create_more_actions(action_map(), submitted?)
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
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{ 30 => :wide })

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("link-survey", "content.title") }}
      menus={{ @menus }}
    >
      <div id={{ :survey_content }} phx-hook="ViewportResize" phx-click="reset_focus">
        <div x-data="{ image_picker: false, active_tab: 0, dropdown: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="image_picker">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div class="{{marginX(@breakpoint)}} w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg" x-on:click.away="image_picker = false, $parent.$parent.overlay = false">
                <ImageCatalogPicker
                  id={{:image_picker}}
                  conn={{@socket}}
                  viewport={{@viewport}}
                  breakpoint={{@breakpoint}}
                  static_path={{&Routes.static_path/2}}
                  initial_query={{initial_image_query(assigns)}}
                  image_catalog={{Core.ImageCatalog.Unsplash}}
                />
              </div>
            </div>
          </div>
          <div :if={{ show_dialog?(@dialog) }} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <Dialog vm={{ @dialog }} />
            </div>
          </div>
          <TabbarArea tabs={{@tabs}}>
            <ActionBar right_bar_buttons={{ create_actions(@breakpoint, @submitted?) }} more_buttons={{ create_more_actions(@submitted?) }}>
              <Tabbar size={{ tabbar_size(@breakpoint) }} initial_tab={{ @initial_tab }}/>
            </ActionBar>
            <TabbarContent/>
            <TabbarFooter/>
          </TabbarArea>
        </div>
      </div>
    </Workspace>
    """
  end
end
