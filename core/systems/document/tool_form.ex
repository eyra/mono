defmodule Systems.Document.ToolForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.pdf)

  alias Systems.{
    Document
  }

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_path, url, original_filename}
      ) do
    socket
    |> save(entity, %{ref: url, name: original_filename})
  end

  @impl true
  def update(
        %{
          id: id,
          entity: entity
        },
        socket
      ) do
    label = dgettext("eyra-document", "pdf-select-label")
    placeholder = dgettext("eyra-document", "pdf-select-placeholder")
    select_button = dgettext("eyra-document", "pdf-select-file-button")
    replace_button = dgettext("eyra-document", "pdf-replace-file-button")

    {
      :ok,
      socket
      |> assign(
        id: id,
        label: label,
        placeholder: placeholder,
        select_button: select_button,
        replace_button: replace_button,
        entity: entity
      )
      |> init_file_uploader(:file)
    }
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  # Saving
  def save(socket, %Document.ToolModel{} = entity, attrs) do
    changeset = Document.ToolModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Frameworks.Pixel.Components.FileSelector.file_selector
        id={@id}
        label={@label}
        placeholder={@placeholder}
        filename={@entity.name}
        replace_button={@replace_button}
        select_button={@select_button}
        uploads={@uploads}
      />
    </div>
    """
  end
end
