defmodule Systems.Assignment.GdprForm do
  use CoreWeb, :live_component

  alias Systems.{
    Consent
  }

  @impl true
  def update(%{id: id, entity: entity}, socket) do

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity
      )
      |> update_consent_agreement()
    }
  end

  defp update_consent_agreement(%{assigns: %{entity: entity}} = socket) do

    revision = Consent.Public.latest_unlocked_revision_safe(entity)

    consent_revision_form = %{
      id: :consent_revision,
      module: Consent.RevisionForm,
      entity: revision
    }

    assign(socket, consent_revision_form: consent_revision_form)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2>Consent</Text.title2>
          <.live_component {@consent_revision_form} />
        </Area.content>
      </div>
    """
  end
end
