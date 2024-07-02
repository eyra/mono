defmodule Systems.Assignment.StorageView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.RadioGroup
  alias Systems.Project
  alias Systems.Storage

  @impl true
  def update(%{project_node: project_node, storage_endpoint: storage_endpoint}, socket) do
    special_type = Map.get(socket, :special_type, :builtin)

    {
      :ok,
      socket
      |> assign(
        project_node: project_node,
        storage_endpoint: storage_endpoint,
        special_type: special_type
      )
      |> compose_child(:type_selector)
      |> update_storage_button()
      |> update_logo()
      |> update_body()
    }
  end

  @impl true
  def compose(:type_selector, %{storage_endpoint: storage_endpoint, special_type: special_type})
      when is_nil(storage_endpoint) do
    items = Storage.ServiceIds.labels(special_type, Storage.Private.allowed_service_ids())

    %{
      module: RadioGroup,
      params: %{
        items: items
      }
    }
  end

  @impl true
  def compose(:type_selector, _), do: nil

  def update_storage_button(%{assigns: %{storage_endpoint: nil}} = socket) do
    storage_button = %{
      action: %{type: :send, event: "create_storage"},
      face: %{
        type: :primary,
        bg_color: "bg-tertiary",
        text_color: "text-grey1",
        label: dgettext("eyra-assignment", "storage.create.button")
      }
    }

    assign(socket, storage_button: storage_button)
  end

  def update_storage_button(%{assigns: %{storage_endpoint: %{id: storage_endpoint_id}}} = socket) do
    storage_button = %{
      action: %{type: :redirect, to: ~p"/storage/#{storage_endpoint_id}/content"},
      face: %{
        type: :plain,
        icon: :forward,
        label: dgettext("eyra-assignment", "storage.goto.button")
      }
    }

    assign(socket, storage_button: storage_button)
  end

  defp update_logo(%{assigns: %{storage_endpoint: storage_endpoint}} = socket)
       when not is_nil(storage_endpoint) do
    logo = Storage.EndpointModel.asset_image_src(storage_endpoint, :logo)
    assign(socket, logo: logo)
  end

  defp update_logo(socket) do
    assign(socket, logo: nil)
  end

  defp update_body(%{assigns: %{storage_endpoint: storage_endpoint}} = socket)
       when is_nil(storage_endpoint) do
    assign(socket, body: dgettext("eyra-storage", "create.storage.body"))
  end

  defp update_body(socket) do
    assign(socket, body: dgettext("eyra-storage", "goto.storage.body"))
  end

  @impl true
  def handle_event(
        "create_storage",
        _payload,
        %{
          assigns: %{
            special_type: special_type,
            project_node: %{id: project_node_id} = project_node
          }
        } = socket
      ) do
    name = Storage.ServiceIds.translate(special_type)

    changeset =
      Storage.Public.prepare_endpoint(special_type, %{key: "project_node=#{project_node_id}"})

    create_item_result = Project.Assembly.create_item(changeset, name, project_node)

    case create_item_result do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket |> Frameworks.Pixel.Flash.push_error()}
    end
  end

  @impl true
  def handle_event("update", %{source: %{name: :type_selector}, status: special_type}, socket) do
    {
      :noreply,
      socket
      |> assign(special_type: special_type)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="border-grey4 border-2 rounded p-6">
        <div class="flex flex-row">
          <div class="flex-grow">
            <Text.body><%= @body %></Text.body>
            <.spacing value="S" />
            <.child name={:type_selector} fabric={@fabric} >
              <:footer>
                <.spacing value="S" />
              </:footer>
            </.child>
            <Button.dynamic_bar buttons={[@storage_button]} />
          </div>
          <div>
            <%= if @logo do %>
              <img src={@logo} alt="Storage logo" />
            <% end %>
          </div>
        </div>
      </div>
    """
  end
end
