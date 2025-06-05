defmodule Systems.Promotion.WysiwygForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Promotion

  @impl true
  def update(%{id: id, entity: %Promotion.Model{} = entity, field_name: field_name}, socket)
      when is_atom(field_name) do
    field = Map.get(entity, field_name)
    form = to_form(%{Atom.to_string(field_name) => field})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        visible: true,
        form: form,
        field_name: field_name
      )
    }
  end

  def save(socket, entity, attrs) do
    changeset = Promotion.Model.changeset(entity, :save, attrs)

    case Core.Persister.save(entity, changeset) do
      {:ok, entity} ->
        socket
        |> assign(entity: entity)
        |> flash_persister_saved()

      {:error, changeset} ->
        socket
        |> handle_save_errors(changeset)
    end
  end

  @impl true
  def handle_wysiwyg_update(%{assigns: %{field_name: field_name, entity: entity}} = socket) do
    field_content = Map.get(socket.assigns, field_name)
    attributes = Map.put(%{}, field_name, field_content)

    socket
    |> save(entity, attributes)
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
        <.form id="wysiwyg_form" :let={form} for={@form} phx-change="save_wysiwyg" phx-target={@myself} >
          <!-- always render wysiwyg te prevent scrollbar reset in LiveView -->
          <.wysiwyg_area form={form} field={@field_name} visible={@visible}/>
        </.form>
      </div>
    """
  end
end
