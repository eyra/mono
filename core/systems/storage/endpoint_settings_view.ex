defmodule Systems.Storage.EndpointSettingsView do
  use CoreWeb, :live_component

  alias Frameworks.Concept
  alias Systems.Storage

  @impl true
  def update(%{endpoint: endpoint}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(endpoint: endpoint, key: "key")
      |> update_special()
      |> compose_child(:special_form)
    }
  end

  defp update_special(%{assigns: %{endpoint: endpoint}} = socket) do
    special = Storage.EndpointModel.special(endpoint)
    assign(socket, special: special)
  end

  @impl true
  def compose(:special_form, %{special: special, key: key}) do
    %{
      module: Concept.ContentModel.form(special),
      params: %{
        model: special,
        key: key
      }
    }
  end

  @impl true
  def handle_event("update", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-storage", "tabbar.item.settings") %></Text.title2>
        <.spacing value="L" />
        <.child name={:special_form} fabric={@fabric} />
      </Area.content>
    </div>
    """
  end
end
