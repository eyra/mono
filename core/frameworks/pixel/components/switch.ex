defmodule Frameworks.Pixel.Switch do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel

  # Handle Selector Update
  @impl true
  def update(%{active_item_id: status, selector_id: :selector}, socket) do
    {:ok, socket |> update_status(status)}
  end

  @impl true
  def update(
        %{id: id, on_text: on_text, off_text: off_text, opt_in?: opt_in?, status: status},
        socket
      ) do
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
      |> compose_child(:selector)
    }
  end

  defp update_status(%{assigns: %{status: status}} = socket, new_status)
       when status != new_status do
    socket
    |> assign(status: new_status)
    |> send_event(:parent, "switch", %{status: new_status})
  end

  defp update_status(socket, _status) do
    socket
  end

  @impl true
  def compose(:selector, %{
        id: id,
        on_text: on_text,
        off_text: off_text,
        opt_in?: opt_in?,
        status: status
      }) do
    off = %{id: :off, value: off_text, active: status == :off}
    on = %{id: :on, value: on_text, active: status == :on}

    items =
      if opt_in? do
        [off, on]
      else
        [on, off]
      end

    %{
      module: Pixel.Selector,
      params: %{
        grid_options: "flex flex-row gap-8",
        items: items,
        type: :radio,
        optional?: false,
        parent: %{id: id, type: __MODULE__}
      }
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
