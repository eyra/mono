defmodule Systems.Assignment.GdprForm do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel
  alias Systems.Assignment
  alias Systems.Consent

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity
      )
      |> compose_child(:switch)
      |> compose_child(:consent_revision_form)
    }
  end

  @impl true
  def compose(:switch, %{entity: %{consent_agreement: consent_agreement}}) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "gdpr_form.on.label"),
        off_text: dgettext("eyra-assignment", "gdpr_form.off.label"),
        status:
          if consent_agreement do
            :on
          else
            :off
          end
      }
    }
  end

  @impl true
  def compose(:consent_revision_form, %{entity: %{consent_agreement: nil}}) do
    nil
  end

  @impl true
  def compose(:consent_revision_form, %{entity: %{consent_agreement: consent_agreement}}) do
    %{
      module: Consent.RevisionForm,
      params: %{
        entity: Consent.Public.latest_revision(consent_agreement)
      }
    }
  end

  @impl true
  def handle_event(
        "switch",
        %{status: :on},
        %{assigns: %{entity: %{auth_node: auth_node} = assignment}} = socket
      ) do
    consent_agreement = Consent.Public.prepare_agreement(auth_node: auth_node)
    Assignment.Public.update_consent_agreement(assignment, consent_agreement)

    {
      :noreply,
      socket
      |> compose_child(:consent_revision_form)
    }
  end

  @impl true
  def handle_event("switch", %{status: :off}, %{assigns: %{entity: assignment}} = socket) do
    Assignment.Public.update_consent_agreement(assignment, nil)

    {
      :noreply,
      socket
      |> hide_child(:consent_revision_form)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.child id={:switch} fabric={@fabric} />
        <.spacing value="S" />
        <.child id={:consent_revision_form} fabric={@fabric} />
      </div>
    """
  end
end
