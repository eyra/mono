defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Components.WysiwygArea

  alias Systems.Content

  @impl true
  def update(%{id: id, entity: %{body: body} = entity}, socket) do
    form = to_form(%{"body" => body})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
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
        field: :body,
        visible: true
      }
    }
  end

  def handle_body_update(%{assigns: %{body: body, entity: entity}} = socket) do
    dbg("hitting handle_body_update")

    {
      socket
      |> save(entity, %{body: body})
    }
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
        <.form id={"#{@id}_agreement_form"} :let={form} for={@form} phx-change="save" phx-target={@myself} >
          <.child name={:wysiwyg_area} fabric={@fabric}/>
        </.form>
      </div>
    """
  end
end
