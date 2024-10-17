defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Content

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
    }
  end

  @impl true
  def handle_wysiwyg_update(%{assigns: %{body: body, entity: entity}} = socket) do
    dbg("=========HANDLE BODY UPDATE")
    dbg("body: #{inspect(body)}")
    dbg("=----------------------=")

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
          <!-- always render wysiwyg te prevent scrollbar reset in LiveView -->
          <.wysiwyg_area form={form} field={:body} />
        </.form>
      </div>
    """
  end
end
