defmodule Systems.Assignment.OnboardingConsentView do
  use CoreWeb.LiveForm

  alias Systems.{
    Consent
  }

  @impl true
  def update(
        %{id: id, revision: revision, user: user, create_signature?: create_signature?},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        revision: revision,
        user: user,
        create_signature?: create_signature?
      )
      |> update_clickwrap_view()
    }
  end

  defp update_clickwrap_view(
         %{assigns: %{revision: revision, user: user, create_signature?: create_signature?}} =
           socket
       ) do
    child =
      prepare_child(socket, :clickwrap_view, Consent.ClickWrapView, %{
        revision: revision,
        user: user,
        create_signature?: create_signature?
      })

    show_child(socket, child)
  end

  @impl true
  def handle_event("accept", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "accept")}
  end

  @impl true
  def handle_event("decline", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "decline")}
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
