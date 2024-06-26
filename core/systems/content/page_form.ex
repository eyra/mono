defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm

  alias Systems.Content

  @impl true
  def update(%{id: id, entity: nil}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: nil,
        visible: false,
        form: nil
      )
    }
  end

  @impl true
  def update(%{id: id, entity: %{body: body} = entity}, socket) do
    form = to_form(%{"body" => body})

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
  def handle_event(
        "save",
        %{"body_input" => body},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
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
          <.wysiwyg_area form={form} field={:body} visible={@visible}/>
        </.form>
      </div>
    """
  end
end
