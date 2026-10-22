defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Content

  @impl true
  def update(%{id: id, entity: %{body: body} = entity}, socket) do
    original_form = to_form(%{"body" => body})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        original_form: original_form
      )
    }
  end

  @impl true
  def handle_wysiwyg_update(%{assigns: %{body: body, entity: entity}} = socket) do
    socket
    |> save(entity, %{body: body})
  end

  # Saving
  def save(socket, nil, _attrs) do
    socket
  end

  def save(socket, entity, attrs) do
    changeset = Content.PageModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id={"#{@id}_page_form"} :let={form} for={@original_form } phx-change="save_wysiwyg" phx-target={@myself} >
          <!-- always render wysiwyg te prevent scrollbar reset in LiveView -->
          <.wysiwyg_area form={form} field={:body} />
        </.form>
      </div>
    """
  end
end
