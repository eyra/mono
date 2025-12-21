defmodule Systems.Storage.EndpointSettingsView do
  use CoreWeb, :live_component

  alias Frameworks.Concept
  alias Systems.Storage

  @impl true
  def update(%{endpoint: endpoint}, %{assigns: %{}} = socket) do
    special_type = Storage.EndpointModel.special_field(endpoint)

    {
      :ok,
      socket
      |> assign(endpoint: endpoint, special_type: special_type, key: "key", connected?: false)
      |> update_special()
      |> compose_child(:special_form)
      |> update_logo()
      |> update_test_button()
    }
  end

  defp update_test_button(socket) do
    test_button = %{
      face: %{
        type: :primary,
        label: "Test connection",
        bg_color: "bg-tertiary",
        text_color: "text-grey1"
      },
      action: %{type: :send, event: "test_connection"}
    }

    assign(socket, test_button: test_button)
  end

  defp update_special(%{assigns: %{endpoint: endpoint}} = socket) do
    special = Storage.EndpointModel.special(endpoint)
    assign(socket, special: special)
  end

  defp update_logo(%{assigns: %{endpoint: endpoint}} = socket) do
    logo = Storage.EndpointModel.asset_image_src(endpoint, {:logo, {:product, :wide}})
    assign(socket, logo: logo)
  end

  @impl true
  def compose(:special_form, %{special: special, key: key}) do
    %{
      module: Concept.ContentModel.form(special),
      params: %{
        entity: special,
        key: key
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row">
          <Text.title2><%= dgettext("eyra-storage", "tabbar.item.settings") %></Text.title2>
          <div class="flex-grow"/>
          <div>
            <%= if @logo do %>
              <img src={@logo} alt="Storage logo" />
            <% end %>
          </div>
        </div>

        <.child name={:special_form} fabric={@fabric} />
      </Area.content>
    </div>
    """
  end
end
