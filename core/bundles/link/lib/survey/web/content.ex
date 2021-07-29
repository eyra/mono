defmodule Link.Survey.Content do
  @moduledoc """
  The cms page for survey tool
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave

  import CoreWeb.Gettext

  alias Core.Survey.Tools
  alias Core.Promotions

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.Promotion.Form, as: PromotionForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Link.Survey.Form, as: ToolForm
  alias Link.Survey.{MonitorData, Monitor}

  data(tool_id, :any)
  data(promotion_id, :any)
  data(monitor_data, :any)
  data(changesets, :any)
  data(initial_image_query, :any)
  data(uri_origin, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Tools.get_survey_tool!(id)
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    parsed_uri = URI.parse(uri)
    uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"
    {:noreply, assign(socket, uri_origin: uri_origin)}
  end

  def mount(%{"id" => id}, _session, socket) do
    tool = Tools.get_survey_tool!(id)
    promotion = Promotions.get!(tool.promotion_id)
    monitor_data = MonitorData.create(tool, promotion)

    {
      :ok,
      socket
      |> assign(
        tool_id: id,
        promotion_id: tool.promotion_id,
        monitor_data: monitor_data,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
    }
  end

  defp initial_image_query(%{promotion_id: promotion_id}) do
    promotion = Promotions.get!(promotion_id)

    case promotion.themes do
      nil -> ""
      themes -> themes |> Enum.map(&Atom.to_string(&1)) |> Enum.join(" ")
    end
  end

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("link-survey", "content.title") }}
      user={{@current_user}}
      user_agent={{ Browser.Ua.to_ua(@socket) }}
      active_item={{ :survey }}
      id={{ @tool_id }}
    >
      <div phx-click="reset_focus">
        <div x-data="{ open: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="open">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div class="w-5/6 md:w-popup-md lg:w-popup-lg" @click.away="open = false, $parent.overlay = false">
                <ImageCatalogPicker conn={{@socket}} static_path={{&Routes.static_path/2}} initial_query={{initial_image_query(assigns)}} id={{:image_picker}} image_catalog={{Core.ImageCatalog.Unsplash}} />
              </div>
            </div>
          </div>
          <Monitor monitor_data={{@monitor_data}}/>
          <ToolForm id={{:tool_form}} entity_id={{@tool_id}} uri_origin={{@uri_origin}}/>
          <PromotionForm id={{:promotion_form}} entity_id={{@promotion_id}} />
        </div>
      </div>
    </Workspace>
    """
  end
end
