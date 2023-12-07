defmodule Systems.Consent.SignatureView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import Frameworks.Pixel.Takeover

  @impl true
  def update(%{signature: signature}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(signature: signature)
      |> compose_element(:title)
      |> compose_element(:source)
    }
  end

  @impl true
  def compose(:title, _) do
    dgettext("eyra-consent", "signature.view.title")
  end

  def compose(:source, %{signature: %{revision: %{source: source}}}), do: source
  def compose(:source, _), do: ""

  # Events

  @impl true
  def handle_event("takeover_close", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "close")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.takeover title={@title} target={@myself} >
        <div class="wysiwig">
          <%= raw @source %>
        </div>
      </.takeover>
    </div>
    """
  end
end
