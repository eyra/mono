defmodule Systems.Feldspar.ToolForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, store: Systems.Feldspar.Public, accept: ~w(.zip)

  alias Systems.{
    Feldspar
  }

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        %{public_url: public_url, original_filename: original_filename}
      ) do
    socket
    |> save(entity, %{archive_ref: public_url, archive_name: original_filename})
  end

  @impl true
  def update(
        %{
          id: id,
          entity: entity
        },
        socket
      ) do
    label = dgettext("eyra-feldspar", "zip-select-label")
    placeholder = dgettext("eyra-feldspar", "zip-select-placeholder")
    select_button = dgettext("eyra-feldspar", "zip-select-file-button")
    replace_button = dgettext("eyra-feldspar", "zip-replace-file-button")

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
    {
      :noreply,
      socket
      |> handle_upload_error()
    }
  end

  defp handle_upload_error(socket) do
    if has_upload_error(socket) do
      if has_upload_error(socket, :too_large) do
        Frameworks.Pixel.Flash.push_error(socket, dgettext("eyra-feldspar", "zip-too-large"))
      else
        Frameworks.Pixel.Flash.push_error(socket)
      end
    end

    socket
  end

  defp has_upload_error(%{assigns: %{uploads: %{file: %{errors: [_ | _]}}}}), do: true
  defp has_upload_error(_), do: false

  defp has_upload_error(%{assigns: %{uploads: %{file: %{errors: errors}}}}, error_type) do
    Enum.find(errors, fn {_, type} -> type === error_type end) != nil
  end

  # Saving
  def save(socket, %Feldspar.ToolModel{} = entity, attrs) do
    changeset = Feldspar.ToolModel.changeset(entity, attrs)

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
        filename={@entity.archive_name}
        replace_button={@replace_button}
        select_button={@select_button}
        uploads={@uploads}
      />
    </div>
    """
  end
end
