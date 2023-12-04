defmodule Systems.Assignment.OnboardingConsentView do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Systems.{
    Consent
  }

  @impl true
  def update(%{id: id, revision: revision, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        revision: revision,
        user: user
      )
      |> update_clickwrap_view()
    }
  end

  defp update_clickwrap_view(%{assigns: %{revision: revision, user: user}} = socket) do
    child =
      prepare_child(socket, :clickwrap_view, Consent.ClickWrapView, %{
        revision: revision,
        user: user
      })

    show_child(socket, child)
  end

  @impl true
  def handle_event("continue", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "continue")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Margin.y id={:page_top} />
        <Area.content>
          <Text.title2><%= dgettext("eyra-assignment", "onboarding.consent.title") %></Text.title2>
          <.child name={:clickwrap_view} fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
