defmodule Systems.Consent.RevisionForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Consent
  }

  @impl true
  def update(%{id: id, entity: %{source: source} = entity}, socket) do
    form = to_form(%{"source" => source})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        form: form
      )
    }
  end

  @impl true
  def handle_event(
        "save",
        %{"source_input" => source},
        %{assigns: %{entity: %{source: old_source} = entity}} = socket
      ) do
    {
      :noreply,
      if old_source == source do
        socket
      else
        save(socket, entity, %{source: source})
      end
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Consent.RevisionModel.changeset(entity, attrs)

    case Core.Persister.save(entity, changeset) do
      {:ok, entity} ->
        socket
        |> assign(entity: entity)
        |> flash_persister_saved()

      {:error, _} ->
        socket
        |> flash_persister_error(dgettext("eyra-consent", "consent-out-of-sync-error"))
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id="agreement_form" :let={form} for={@form} phx-change="save" phx-target={@myself} >
          <.wysiwyg_area form={form} field={:source} />
        </.form>
      </div>
    """
  end
end
