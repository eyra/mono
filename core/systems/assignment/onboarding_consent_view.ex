defmodule Systems.Assignment.OnboardingConsentView do
  use CoreWeb.LiveForm

  alias Systems.{
    Consent
  }

  @impl true
  def update(
        %{id: id, revision: revision, user: user},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        revision: revision,
        user: user
      )
      |> update_title()
      |> compose_child(:clickwrap_view)
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "onboarding.consent.title")
    socket |> assign(title: title)
  end

  @impl true
  def compose(:clickwrap_view, %{revision: revision, user: user}) do
    %{
      module: Consent.ClickWrapView,
      params: %{
        revision: revision,
        user: user,
        accept_text: dgettext("eyra-consent", "click_wrap.accept.button"),
        decline_text: dgettext("eyra-consent", "click_wrap.decline.button"),
        validation_text: dgettext("eyra-consent", "click_wrap.consent.validation")
      }
    }
  end

  @impl true
  def handle_event("accept", %{source: %{name: :clickwrap_view}}, socket) do
    {:noreply, socket |> send_event(:parent, "accept")}
  end

  @impl true
  def handle_event("decline", %{source: %{name: :clickwrap_view}}, socket) do
    {:noreply, socket |> send_event(:parent, "decline")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Margin.y id={:page_top} />
        <Area.content>
          <Text.title2><%= @title %></Text.title2>
          <.child name={:clickwrap_view} fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
