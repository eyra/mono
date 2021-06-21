defmodule CoreWeb.DataDonation.Content do
  @moduledoc """
  The cms page for data donation tool
  """
  use CoreWeb, :live_view

  import CoreWeb.Gettext

  alias EyraUI.Hero.HeroSmall
  alias Core.Repo
  alias Core.Studies
  alias Core.DataDonation.Tools
  alias Core.Promotions

  alias CoreWeb.ImageCatalogPicker
  alias CoreWeb.DataDonation.Form, as: ToolForm
  alias CoreWeb.Promotion.Form, as: PromotionForm

  data(tool_id, :any)
  data(promotion_id, :any)
  data(changesets, :any)
  data(author, :any)
  data(initial_image_query, :any)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Tools.get!(id)
  end

  def mount(%{"id" => id}, _session, socket) do
    tool = Tools.get!(id)

    study = Studies.get_study!(tool.study_id)
    [author | _] = Studies.list_authors(study)

    {
      :ok,
      socket
      |> assign(
        author: author.user,
        tool_id: id,
        promotion_id: tool.promotion_id,
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
          <PromotionForm id={{:promotion_form}} entity_id={{@promotion_id}} owner={{@author}} />
        </div>
      </div>
    """
  end

  # Schedule Save
  @save_delay 1

  defp cancel_save_timer(nil), do: nil
  defp cancel_save_timer(timer), do: Process.cancel_timer(timer)

  def schedule_save(socket, new_changesets) do
    socket =
      update_in(socket.assigns.save_timer, fn timer ->
        cancel_save_timer(timer)
        Process.send_after(self(), :save, @save_delay * 1_000)
      end)

    socket =
      update_in(socket.assigns.changesets, fn existing_changesets ->
        Map.merge(existing_changesets, new_changesets)
      end)

    socket
  end

  # Save
  def save(changeset) do
    if changeset.valid? do
      entity = save_valid(changeset)
      {:ok, entity}
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  defp save_valid(changeset) do
    {:ok, entity} = changeset |> Repo.update()
    entity
  end

  # Schedule Hide Message
  @hide_flash_delay 3

  defp cancel_hide_flash_timer(nil), do: nil
  defp cancel_hide_flash_timer(timer), do: Process.cancel_timer(timer)

  def schedule_hide_flash(socket) do
    update_in(socket.assigns.hide_flash_timer, fn timer ->
      cancel_hide_flash_timer(timer)
      Process.send_after(self(), :hide_flash, @hide_flash_delay * 1_000)
    end)
  end

  def hide_flash(socket) do
    cancel_hide_flash_timer(socket.assigns.hide_flash_timer)

    socket
    |> clear_flash()
  end

  def put_error_flash(socket) do
    socket
    |> put_flash(:error, dgettext("eyra-ui", "error.flash"))
  end

  def put_saved_flash(socket) do
    socket
    |> put_flash(:info, dgettext("eyra-ui", "saved.info.flash"))
  end

  # Handle Event
  
  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(ToolForm, id: :tool_form, focus: "")
    send_update(PromotionForm, id: :promotion_form, focus: "")
    {:noreply, socket}
  end

  # Handle Info

  @impl true
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

  def handle_info(:save, %{assigns: %{changesets: changesets}} = socket) do
    changesets
    |> Enum.each(fn {_, value} ->
      value |> Repo.update()
    end)

    {
      :noreply,
      socket
      |> assign(changesets: %{})
      |> put_saved_flash()
      |> schedule_hide_flash()
    }
  end

  def handle_info(:hide_flash, socket) do
    {
      :noreply,
      socket
      |> hide_flash()
    }
  end

  def handle_info({:flash, :error}, socket) do
    {
      :noreply,
      socket
      |> put_error_flash()
      |> schedule_hide_flash()
      |> hide_flash()
    }
  end

  def handle_info({:schedule_save, changesets}, socket) do
    {
      :noreply,
      socket
      |> schedule_save(changesets)
    }
  end
end
