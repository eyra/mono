defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.Components.WysiwygArea

  alias Systems.Content
  alias Frameworks.Pixel.TrixPostProcessor

  @impl true
  def update(%{id: id, entity: %{body: body} = entity}, socket) do
    form_data = to_form(%{"body" => body})

    dbg(form_data)
    dbg("my id is: #{inspect(id)}")

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        form_data: form_data
      )
      |> compose_child(:wysiwyg_area)
    }
  end

  @impl true
  def update(%{id: id, entity: nil}, socket) do
    form = to_form(%{"body" => "?"})
    dbg("called update with entity: nil and id: #{inspect(id)}")
  end

  @impl true
  def compose(:wysiwyg_area, assigns) do
    %{
      module: Frameworks.Pixel.Components.WysiwygArea,
      params: %{
        form: assigns.form_data,
        field: :body,
        visible: true
      }
    }
  end

  def handle_body_update(%{assigns: %{body: body, entity: entity}} = socket) do
    dbg("=========HANDLE BODY UPDATE")
    dbg("body: #{inspect(body)}")
    dbg("=----------------------=")

    body =
      body
      |> TrixPostProcessor.add_target_blank()

    socket
    |> save(entity, %{body: body})
  end

  # Saving
  def save(socket, nil, _attrs) do
    socket
  end

  def save(socket, entity, attrs) do
    dbg("Saving entity: #{inspect(entity)} with attrs #{inspect(attrs)}")

    changeset = Content.PageModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id={"#{@id}_page_form"} :let={form} for={@form_data} phx-change="save" phx-target={@myself} >
          <.child name={:wysiwyg_area} fabric={@fabric}/>
        </.form>
      </div>
    """
  end
end
