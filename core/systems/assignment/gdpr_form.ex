defmodule Systems.Assignment.GdprForm do
  use CoreWeb, :live_component

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
    %{
      module: Consent.RevisionForm,
      params: %{entity: nil}
    }
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
  def compose(:confirmation_modal, %{entity: %{consent_agreement: consent_agreement}}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          body: dgettext("eyra-assignment", "gdpr_form.confirmation_modal.body"),
          consent_agreement: consent_agreement
        }
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :on},
        %{assigns: %{entity: %{auth_node: auth_node} = assignment}} = socket
      ) do
    consent_agreement = Consent.Public.prepare_agreement(auth_node)
    {:ok, _} = Assignment.Public.update_consent_agreement(assignment, consent_agreement)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("update", %{status: :off}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:confirmation_modal)
      |> show_modal(:confirmation_modal, :dialog)
    }
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :confirmation_modal}}, socket) do
    {:noreply,
     socket
     |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :confirmation_modal}},
        %{assigns: %{entity: assignment}} = socket
      ) do
    {:ok, _} = Assignment.Public.update_consent_agreement(assignment, nil)
    {:noreply, socket |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.child name={:switch} fabric={@fabric} />
        <.spacing value="S" />
        <.child name={:consent_revision_form} fabric={@fabric} />
      </div>
    """
  end
end
