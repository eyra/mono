defmodule Systems.Storage.BuiltIn.EndpointForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  require Logger

  alias Systems.Storage.BuiltIn.EndpointModel, as: Model

  @impl true
  def update(%{model: model, key: key}, socket) do
    attrs =
      if Map.get(model, :key) != nil do
        %{}
      else
        %{key: key}
      end

    changeset =
      Model.changeset(model, attrs)
      |> Model.validate()

    changeset =
      if model.id do
        Map.put(changeset, :action, :update)
      else
        Map.put(changeset, :action, :insert)
      end

    {
      :ok,
      socket
      |> send_event(:parent, "update", %{changeset: changeset})
    }
  end

  @impl true
  def handle_event(event, payload, socket) do
    Logger.warn("Unexpected event #{event}: #{inspect(payload)}")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div/>
    """
  end
end
