defmodule Systems.Benchmark.SpotForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Benchmark
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: spot},
        socket
      ) do
    changeset = Benchmark.SpotModel.changeset(spot, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: spot,
        changeset: changeset
      )
    }
  end

  # Handle Events
  @impl true
  def handle_event("close", _params, socket) do
    send(self(), %{module: __MODULE__, action: :update})
    {:noreply, socket}
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"spot_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Benchmark.SpotModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:name} label_text={dgettext("eyra-benchmark", "spot.form.name.label")} />
      </.form>
    </div>
    """
  end
end
