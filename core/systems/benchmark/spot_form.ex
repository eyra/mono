defmodule Systems.Benchmark.SpotForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Benchmark
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, spot_id: spot_id},
        socket
      ) do
    spot = Benchmark.Public.get_spot!(spot_id)
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
      <Text.title2><%= dgettext("eyra-benchmark", "spot.form.title") %></Text.title2>
      <Text.body><%= dgettext("eyra-benchmark", "spot.form.description") %></Text.body>
      <.spacing value="XS" />
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:name} label_text={dgettext("eyra-benchmark", "spot.form.name")} />
      </.form>
    </div>
    """
  end
end
