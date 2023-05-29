defmodule Systems.DataDonation.ContentPage do
  @moduledoc """
  The cms page for data donation tool
  """
  use CoreWeb, :live_view

  require Core.Enums.Themes
  alias Core.Enums.Themes

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Hero

  alias CoreWeb.UI.ImageCatalogPicker

  alias Systems.{
    DataDonation,
    Promotion
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    DataDonation.Public.get_tool!(id)
  end

  def mount(%{"id" => id}, _session, socket) do
    tool = DataDonation.Public.get_tool!(id)

    {
      :ok,
      socket
      |> assign(
        tool_id: id,
        promotion_id: tool.promotion_id,
        changesets: %{}
      )
    }
  end

  @impl true
  def handle_uri(socket), do: socket

  defp initial_image_query(%{promotion_id: promotion_id}) do
    promotion = Promotion.Public.get!(promotion_id)

    case promotion.themes do
      nil -> ""
      themes -> themes |> Enum.map_join(" ", &Atom.to_string(&1))
    end
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:image_picker, image_id}, socket) do
    send_update(Promotion.FormView, id: :promotion_form, image_id: image_id)
    {:noreply, socket}
  end

  # data(tool_id, :any)
  # data(promotion_id, :any)
  # data(changesets, :any)
  # data(initial_image_query, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div x-data="{ open: false }">
        <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="open">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <div
              class="w-5/6 md:w-popup-md lg:w-popup-lg"
              @click.away="open = false, $parent.overlay = false"
            >
              <.live_component
                module={ImageCatalogPicker}
                static_path={&CoreWeb.Endpoint.static_path/1}
                initial_query={initial_image_query(assigns)}
                id={:image_picker}
                image_catalog={Core.ImageCatalog.Unsplash}
              />
            </div>
          </div>
        </div>
        <Hero.small title={dgettext("eyra-data-donation", "content.title")} />
        <.live_component
          module={DataDonation.ToolForm}
          id={:tool_form}
          entity_id={@tool_id}
        />
        <.live_component
          module={Promotion.FormView}
          id={:promotion_form}
          props={%{entity_id: @promotion_id, themes_module: Themes}}
        />
      </div>
    </div>
    """
  end
end
