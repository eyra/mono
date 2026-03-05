defmodule Systems.Storage.BuiltIn.EndpointForm do
  @moduledoc false
  use CoreWeb.LiveForm

  alias Systems.Storage.BuiltIn.EndpointModel, as: Model

  require Logger

  @impl true
  def update(%{model: model, key: key}, socket) do
    attrs =
      if Map.get(model, :key) == nil do
        %{key: key}
      else
        %{}
      end

    changeset =
      model
      |> Model.changeset(attrs)
      |> Model.validate()

    changeset =
      if model.id do
        Map.put(changeset, :action, :update)
      else
        Map.put(changeset, :action, :insert)
      end

    {
      :ok,
      send_event(socket, :parent, "update", %{changeset: changeset})
    }
  end

  @impl true
  def handle_event(_, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div/>
    """
  end
end
