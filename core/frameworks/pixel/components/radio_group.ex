defmodule Frameworks.Pixel.RadioGroup do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(%{items: items}, socket) do
    active_item = items |> Enum.find(& &1.active)
    form = to_form(%{"radio-group" => "#{active_item.id}"})

    {
      :ok,
      socket
      |> assign(items: items, form: form)
    }
  end

  @impl true
  def handle_event("change", %{"radio-group" => status}, socket) do
    {:noreply,
     socket |> send_event(:parent, "update", %{status: String.to_existing_atom(status)})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_form"} for={@form} phx-change="change" phx-target={@myself}>
        <div class="flex flex-row gap-8">
          <%= for item <- @items do %>
            <label class="cursor-pointer flex flex-row gap-[18px] items-center">
              <input
                id={item.id}
                value={item.id}
                type="radio"
                name="radio-group"
                checked={item.active}
                class="cursor-pointer appearance-none w-3 h-3 rounded-full ring-2 ring-offset-4 ring-grey3 checked:bg-primary checked:ring-primary"
              />
              <div class="text-label font-label text-grey1 select-none mt-1"><%= item.value %></div>
            </label>
          <% end %>
        </div>
      </.form>
    </div>
    """
  end
end
