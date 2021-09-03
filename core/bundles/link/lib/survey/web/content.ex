defmodule Link.Survey.Content do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :survey
  use Coreweb.UI.ViewportHelpers

  import CoreWeb.Gettext

  alias Core.Survey.Tools
  alias Core.Promotions
  alias Core.Pools.Submissions

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.Promotion.Form, as: PromotionForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias CoreWeb.UI.Navigation.{TabbarArea, Tabbar, TabbarContent, TabbarFooter}
  alias Link.Survey.Monitor
  alias Link.Survey.Form, as: ToolForm
  alias Link.Pool.Form.Submission, as: SubmissionForm
  import Core.ImageCatalog, only: [image_catalog: 0]

  data(tool_id, :any)
  data(promotion_id, :any)
  data(submission_id, :any)
  data(active_tab, :any)
  data(tabs, :map)
  data(changesets, :any)
  data(initial_image_query, :any)
  data(uri_origin, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Tools.get_survey_tool!(id)
  end

  @impl true
  def mount(%{"id" => tool_id, "tab" => active_tab}, _session, socket) do
    tool = Tools.get_survey_tool!(tool_id)
    promotion = Promotions.get!(tool.promotion_id)
    submission = Submissions.get!(promotion)

    {
      :ok,
      socket
      |> assign(
        tool_id: tool_id,
        promotion_id: tool.promotion_id,
        submission_id: submission.id,
        active_tab: active_tab,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
      |> update_menus()
      |> assign_viewport()
      |> assign_breakpoint()
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", "tool_form"), session, socket)
  end

  @impl true
  def handle_params(
        _unsigned_params,
        uri,
        %{assigns: %{tool_id: tool_id, active_tab: active_tab, submission_id: submission_id}} =
          socket
      ) do
    parsed_uri = URI.parse(uri)
    uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"
    tool = Tools.get_survey_tool!(tool_id)
    tabs = create_tabs(active_tab, tool, submission_id, uri_origin)

    {
      :noreply,
      socket
      |> assign(tabs: tabs)
    }
  end

  defp create_tabs(active_tab, tool, submission_id, uri_origin) do
    [
      %{
        id: :promotion_form,
        active: active_tab === :promotion_form,
        entity_id: tool.promotion_id,
        title: dgettext("link-survey", "tabbar.item.promotion"),
        forward_title: dgettext("link-survey", "tabbar.item.promotion.forward"),
        type: :fullpage,
        component: PromotionForm,
        props: %{
          entity_id: tool.promotion_id
        }
      },
      %{
        id: :tool_form,
        active: active_tab === :tool_form,
        title: dgettext("link-survey", "tabbar.item.survey"),
        forward_title: dgettext("link-survey", "tabbar.item.survey.forward"),
        type: :fullpage,
        component: ToolForm,
        props: %{
          entity_id: tool.id,
          uri_origin: uri_origin
        }
      },
      %{
        id: :criteria_form,
        active: active_tab === :criteria_form,
        title: dgettext("link-survey", "tabbar.item.criteria"),
        forward_title: dgettext("link-survey", "tabbar.item.criteria.forward"),
        type: :fullpage,
        component: SubmissionForm,
        props: %{
          entity_id: submission_id
        }
      },
      %{
        id: :monitor,
        active: active_tab === :monitor,
        title: dgettext("link-survey", "tabbar.item.monitor"),
        forward_title: dgettext("link-survey", "tabbar.item.monitor.forward"),
        type: :fullpage,
        component: Monitor,
        props: %{
          entity_id: tool.id
        }
      }
    ]
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

  def handle_event("delete", _params, %{assigns: %{tool_id: tool_id}} = socket) do
    Tools.get_survey_tool!(tool_id)
    |> Tools.delete_survey_tool()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
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

  defp marginX(:mobile), do: "mx-6"
  defp marginX(_), do: "mx-10"

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("link-survey", "content.title") }}
      menus={{ @menus }}
    >
      <div id={{ :survey_content }} phx-hook="ViewportResize" phx-click="reset_focus">
        <div x-data="{ open: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="open">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div class="{{marginX(@breakpoint)}} w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg" @click.away="open = false, $parent.$parent.overlay = false">
                <ImageCatalogPicker
                  id={{:image_picker}}
                  conn={{@socket}}
                  viewport={{@viewport}}
                  breakpoint={{@breakpoint}}
                  static_path={{&Routes.static_path/2}}
                  initial_query={{initial_image_query(assigns)}}
                  image_catalog={{image_catalog()}}
                />
              </div>
            </div>
          </div>
          <TabbarArea tabs={{@tabs}}>
            <Tabbar id={{ :tabbar }} />
            <TabbarContent/>
            <TabbarFooter/>
          </TabbarArea>
        </div>
      </div>
    </Workspace>
    """
  end
end
