defmodule Link.Survey.Content do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :survey

  import CoreWeb.Gettext

  alias Core.Survey.Tools
  alias Core.Promotions

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.Promotion.Form, as: PromotionForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias CoreWeb.UI.Navigation.{TabbarArea, Tabbar, TabbarContent, TabbarFooter}

  alias Link.Survey.Form, as: ToolForm
  alias Link.Survey.Monitor

  data(tool_id, :any)
  data(promotion_id, :any)
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

    {
      :ok,
      socket
      |> assign(
        tool_id: tool_id,
        promotion_id: tool.promotion_id,
        active_tab: active_tab,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
      |> update_menus()
    }
  end

  @impl true
  def mount(params, session, socket) do
    mount(Map.put(params, "tab", "tool_form"), session, socket)
  end

  @impl true
  def handle_params(_unsigned_params, uri, %{assigns: %{tool_id: tool_id, active_tab: active_tab}} = socket) do
    parsed_uri = URI.parse(uri)
    uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"
    tool = Tools.get_survey_tool!(tool_id)
    tabs = create_tabs(active_tab, tool, uri_origin)

    {:noreply, assign(socket, tabs: tabs)}
  end

  defp create_tabs(active_tab, tool, uri_origin) do
    [
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
        },
      },
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
        id: :monitor,
        active: active_tab === :monitor,
        title: dgettext("link-survey", "tabbar.item.monitor"),
        forward_title: dgettext("link-survey", "tabbar.item.monitor.forward"),
        type: :fullpage,
        component: Monitor,
        props: %{
          entity_id: tool.id,
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

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("link-survey", "content.title") }}
      menus={{ @menus }}
    >
      <div phx-click="reset_focus">
        <div x-data="{ open: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="open">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div class="w-5/6 md:w-popup-md lg:w-popup-lg" @click.away="open = false, $parent.$parent.overlay = false">
                <ImageCatalogPicker conn={{@socket}} static_path={{&Routes.static_path/2}} initial_query={{initial_image_query(assigns)}} id={{:image_picker}} image_catalog={{Core.ImageCatalog.Unsplash}} />
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
