defmodule Frameworks.Pixel.Switch do
  @moduledoc false
  use CoreWeb, :live_component

  alias Frameworks.Pixel

  @impl true
  def update(%{id: id, on_text: on_text, off_text: off_text, opt_in?: opt_in?, status: status}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        on_text: on_text,
        off_text: off_text,
        opt_in?: opt_in?,
        status: status
      )
      |> compose_child(:radio_group)
    }
  end

  @impl true
  def compose(:radio_group, %{on_text: on_text, off_text: off_text, opt_in?: opt_in?, status: status}) do
    off = %{id: :off, value: off_text, active: status == :off}
    on = %{id: :on, value: on_text, active: status == :on}

    items =
      if opt_in? do
        [off, on]
      else
        [on, off]
      end

    %{
      module: Pixel.RadioGroup,
      params: %{
        items: items
      }
    }
  end

  @impl true
  def handle_event("update", %{status: status}, socket) do
    {
      :noreply,
      send_event(socket, :parent, "update", %{status: status})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.stack fabric={@fabric} />
    </div>
    """
  end
end
