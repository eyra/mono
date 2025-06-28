defmodule Systems.Manual.Builder.PublicPage do
  use Systems.Content.Composer, :live_website

  alias Systems.Manual

  @impl true
  def get_model(%{"id" => manual_id}, _session, _socket) do
    Manual.Public.get_manual!(manual_id, Manual.Model.preload_graph(:down))
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> compose_child(:manual_builder)
    }
  end

  @impl true
  def compose(:manual_builder, %{model: manual}) do
    %{
      module: Manual.Builder.View,
      params: %{manual: manual}
    }
  end

  def handle_view_model_updated(socket) do
    socket |> update_child(:manual_builder)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_website user={@current_user} user_agent={Browser.Ua.to_ua(@socket)} menus={@menus} modal={@modal} socket={@socket}>
      <:hero>
      </:hero>
      <div class="px-8 pt-8 w-full h-full">
        <Text.title3><%= @vm.title %></Text.title3>
        <.spacing value="M" />
        <.child name={:manual_builder} fabric={@fabric} />
      </div>
    </.live_website>
    """
  end
end
