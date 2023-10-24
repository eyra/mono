defmodule Systems.Assignment.OnboardingConsentView do
  use CoreWeb.LiveForm

  alias Systems.{
    Consent
  }

  @impl true
  def update(%{consent_clickwrap_view: :continue}, %{assigns: %{id: id}} = socket) do
    send(self(), {:onboarding_continue, id})

    {
      :ok,
      socket
    }
  end

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

  defp update_clickwrap_view(
         %{assigns: %{revision: revision, user: user, myself: myself}} = socket
       ) do
    clickwrap_view = %{
      id: :consent_clickwrap_view,
      module: Consent.ClickWrapView,
      revision: revision,
      user: user,
      target: myself
    }

    assign(socket, clickwrap_view: clickwrap_view)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Margin.y id={:page_top} />
        <Area.content>
          <Text.title2><%= dgettext("eyra-assignment", "onboarding.consent.title") %></Text.title2>
          <.live_component {@clickwrap_view} />
        </Area.content>
      </div>
    """
  end
end
