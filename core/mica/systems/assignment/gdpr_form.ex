defmodule Systems.Assignment.GdprForm do
  use MicaWeb, :live_component_fabric

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
      |> update_status()
      |> compose_child(:switch)
      |> compose_child(:consent_revision_form)
    }
  end

  def update_status(%{assigns: %{confirming_status_off: true}} = socket) do
    socket |> assign(status: :off)
  end

  def update_status(%{assigns: %{entity: assignment}} = socket) do
    status =
      if Assignment.Model.consent_on?(assignment) do
        :on
      else
        :off
      end

    socket |> assign(status: status)
  end

  @impl true
  def compose(:switch, %{status: status}) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "gdpr_form.on.label"),
        off_text: dgettext("eyra-assignment", "gdpr_form.off.label"),
        status: status
      }
    }
  end

  @impl true
  def compose(:consent_revision_form, %{entity: %{consent_agreement: agreement} = assignment}) do
    revision =
      if Assignment.Model.consent_on?(assignment) do
        Consent.Public.latest_revision(agreement)
      end

    %{
      module: Consent.RevisionForm,
      params: %{entity: revision}
    }
  end

  @impl true
  def compose(:confirmation_modal, %{entity: %{consent_agreement: consent_agreement}}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          consent_agreement: consent_agreement,
          body: dgettext("eyra-assignment", "gdpr_form.confirmation_modal.body")
        }
      }
    }
  end

  @impl true
  def handle_event("update", %{status: :on}, %{assigns: %{entity: assignment}} = socket) do
    {:ok, _} = Assignment.Public.enable_consent(assignment)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :off},
        %{assigns: %{entity: assignment}} = socket
      ) do
    revision = Consent.Public.latest_revision(assignment.consent_agreement)
    localized_default_text = dgettext("eyra-consent", "default.consent.text")

    {
      :noreply,
      socket
      |> handle_off_state(revision, revision.source == localized_default_text)
    }
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :confirmation_modal}}, socket) do
    {:noreply,
     socket
     |> update_switch(confirming_status_off: false)
     |> hide_modal(:confirmation_modal)}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :confirmation_modal}},
        %{assigns: %{entity: assignment}} = socket
      ) do
    {:ok, _} = Assignment.Public.disable_consent(assignment)

    {
      :noreply,
      socket
      |> assign(confirming_status_off: false)
      |> hide_modal(:confirmation_modal)
    }
  end

  defp handle_off_state(socket, %{source: source}, false) when not is_nil(source) do
    socket
    |> update_switch(confirming_status_off: true)
    |> compose_child(:confirmation_modal)
    |> show_modal(:confirmation_modal, :compact)
  end

  defp handle_off_state(socket, _, _) do
    {:ok, _} = Assignment.Public.disable_consent(socket.assigns.entity)
    socket
  end

  @impl true
  def handle_modal_closed(socket, :confirmation_modal) do
    update_switch(socket, confirming_status_off: false)
  end

  defp update_switch(socket, confirming_status_off: confirming_status_off) do
    socket
    |> assign(confirming_status_off: confirming_status_off)
    |> update_status()
    |> compose_child(:switch)
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
