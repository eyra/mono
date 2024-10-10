defmodule Systems.Consent.RevisionForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Components.WysiwygArea

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
        visible: true,
        form: form
      )
    }
  end

  @impl true
  def update(%{id: id, entity: nil}, socket) do
    form = to_form(%{"source" => "?"})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: nil,
        visible: false,
        form: form
      )
      |> compose_child(:wysiwyg_area)
    }
  end

  @impl true
  def compose(:wysiwyg_area, assigns) do
    %{
      module: Frameworks.Pixel.Components.WysiwygArea,
      params: %{
        form: assigns.form,
        field: :source
      }
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

  @impl true
  def handle_event(
        "save",
        _,
        %{assigns: %{entity: nil}} = socket
      ) do
    {
      :noreply,
      socket
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Consent.RevisionModel.changeset(entity, attrs)

    case Core.Persister.save(entity, changeset) do
      {:ok, entity} ->
        socket
        |> assign(entity: entity)

      {:error, changeset} ->
        socket
        |> handle_save_errors(changeset)
    end
  end

  def handle_body_update(%{assigns: %{body: body, entity: entity}} = socket) do
    dbg("called handle_body_update with: #{inspect(entity)} and body: #{inspect(body)}")
  end

  defp handle_save_errors(socket, %{errors: errors}) do
    handle_save_errors(socket, errors)
  end

  defp handle_save_errors(socket, [{_, {message, _}} | _]) do
    socket |> flash_persister_error(message)
  end

  defp handle_save_errors(socket, _) do
    socket |> flash_persister_error()
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id="agreement_form" :let={form} for={@form} phx-change="save" phx-target={@myself} >
          <!-- always render wyiwyg te prevent scrollbar reset in LiveView -->
          <.child name={:wysiwyg_area} fabric={@fabric}/>
        </.form>
      </div>
    """
  end
end
