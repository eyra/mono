defmodule Systems.Consent.RevisionForm do
  @moduledoc false
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Consent

  @impl true
  def update(%{id: id, entity: %{source: source} = entity}, socket) do
    form = to_form(%{"source" => source})

    {
      :ok,
      assign(socket, id: id, entity: entity, visible: true, form: form)
    }
  end

  @impl true
  def update(%{id: id, entity: nil}, socket) do
    form = to_form(%{"source" => "?"})

    {
      :ok,
      assign(socket, id: id, entity: nil, visible: false, form: form)
    }
  end

  # Saving

  def save(socket, nil, _) do
    socket
  end

  def save(socket, entity, attrs) do
    changeset = Consent.RevisionModel.changeset(entity, attrs)

    case Core.Persister.save(entity, changeset) do
      {:ok, entity} ->
        socket
        |> assign(entity: entity)
        |> flash_persister_saved()

      {:error, changeset} ->
        handle_save_errors(socket, changeset)
    end
  end

  @impl true
  def handle_wysiwyg_update(%{assigns: %{source: source, entity: entity}} = socket) do
    save(socket, entity, %{source: source})
  end

  defp handle_save_errors(socket, %{errors: errors}) do
    handle_save_errors(socket, errors)
  end

  defp handle_save_errors(socket, [{_, {message, _}} | _]) do
    flash_persister_error(socket, message)
  end

  defp handle_save_errors(socket, _) do
    flash_persister_error(socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id="agreement_form" :let={form} for={@form} phx-change="save_wysiwyg" phx-target={@myself} >
          <!-- always render wysiwyg te prevent scrollbar reset in LiveView -->
          <.wysiwyg_area form={form} field={:source} visible={@visible}/>
        </.form>
      </div>
    """
  end
end
