defmodule Systems.Promotion.WysiwygForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Promotion

  @impl true
  def update(
        %{id: id, entity: %Promotion.Model{} = entity, field_name: field_name} = assigns,
        socket
      )
      when is_atom(field_name) do
    field = Map.get(entity, field_name)
    form = to_form(%{Atom.to_string(field_name) => field})
    label_text = Map.get(assigns, :label_text, nil)
    label_color = Map.get(assigns, :label_color, "text-grey1")
    min_height = Map.get(assigns, :min_height, "min-h-wysiwyg-editor")
    max_height = Map.get(assigns, :max_height, "max-h-wysiwyg-editor")
    reserve_error_space = Map.get(assigns, :reserve_error_space, true)
    visible = Map.get(assigns, :visible, true)

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        visible: visible,
        form: form,
        field_name: field_name,
        label_text: label_text,
        label_color: label_color,
        min_height: min_height,
        max_height: max_height,
        reserve_error_space: reserve_error_space
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
        <.form id={"wysiwyg_form_#{@id}"} :let={form} for={@form} phx-change="save_wysiwyg" phx-target={@myself} >
          <!-- always render wysiwyg to prevent scrollbar reset in LiveView -->
          <.wysiwyg_area
            form={form}
            field={@field_name}
            label_text={@label_text}
            label_color={@label_color}
            min_height={@min_height}
            max_height={@max_height}
            visible={@visible}
            reserve_error_space={@reserve_error_space}
          />
        </.form>
      </div>
    """
  end
end
