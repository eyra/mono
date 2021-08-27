defmodule CoreWeb.DataDonation.Content do
  @moduledoc """
  The cms page for data donation tool
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave

  import CoreWeb.Gettext

  alias EyraUI.Hero.HeroSmall
  alias Core.DataDonation.Tools
  alias Core.Promotions

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.DataDonation.Form, as: ToolForm
  alias CoreWeb.Promotion.Form, as: PromotionForm

  data(tool_id, :any)
  data(promotion_id, :any)
  data(changesets, :any)
  data(initial_image_query, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Tools.get!(id)
  end

  def mount(%{"id" => id}, _session, socket) do
    tool = Tools.get!(id)

    {
      :ok,
      socket
      |> assign(
        tool_id: id,
        promotion_id: tool.promotion_id,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
    }
  end

  @impl true
  def handle_auto_save_done(socket) do
    socket
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
      <div phx-click="reset_focus">
        <div x-data="{ open: false }">
          <div class="fixed z-20 left-0 top-0 w-full h-full" x-show="open">
            <div class="flex flex-row items-center justify-center w-full h-full">
              <div class="w-5/6 md:w-popup-md lg:w-popup-lg" @click.away="open = false, $parent.overlay = false">
                <ImageCatalogPicker conn={{@socket}} static_path={{&Routes.static_path/2}} initial_query={{initial_image_query(assigns)}} id={{:image_picker}} image_catalog={{Core.ImageCatalog.Unsplash}} />
              </div>
            </div>
          </div>
          <HeroSmall title={{ dgettext("eyra-data-donation", "content.title") }} />
          <ToolForm id={{:tool_form}} entity_id={{@tool_id}} />
          <PromotionForm id={{:promotion_form}} props={{ %{entity_id: @promotion_id} }} />
        </div>
      </div>
    """
  end
end
