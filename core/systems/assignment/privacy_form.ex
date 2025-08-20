defmodule Systems.Assignment.PrivacyForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.pdf)

  import Frameworks.Pixel.FileSelector

  alias Systems.Assignment
  alias Systems.Content

  @impl true
  def process_file(socket, %{public_url: public_url, original_filename: original_filename}) do
    privacy_doc =
      %Content.FileModel{}
      |> Content.FileModel.changeset(%{name: original_filename, ref: public_url})

    socket
    |> assign(
      privacy_doc: privacy_doc,
      filename: original_filename
    )
    |> save()
  end

  @impl true
  def update(
        %{id: id, entity: %{privacy_doc: privacy_doc} = entity},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        privacy_doc: privacy_doc
      )
      |> update_filename()
      |> compose_child(:file_copy_view)
      |> init_file_uploader(:file)
    }
  end

  defp update_filename(%{assigns: %{entity: %{privacy_doc: nil}}} = socket) do
    assign(socket, filename: nil)
  end

  defp update_filename(%{assigns: %{entity: %{privacy_doc: %{name: name}}}} = socket) do
    assign(socket, filename: name)
  end

  @impl true
  def compose(:file_copy_view, %{privacy_doc: nil}) do
    nil
  end

  @impl true
  def compose(:file_copy_view, %{privacy_doc: privacy_doc}) do
    %{
      module: Content.FileCopyView,
      params: %{
        file: privacy_doc,
        annotation: dgettext("eyra-assignment", "privacy_doc.annotation")
      }
    }
  end

  # Saving
  def save(%{assigns: %{entity: entity, privacy_doc: privacy_doc}} = socket) do
    changeset =
      Assignment.Model.changeset(entity, %{})
      |> Ecto.Changeset.put_assoc(:privacy_doc, privacy_doc)

    save(socket, changeset)
  end

  @impl true
  def handle_event("change", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.file_selector
          id="privacy_doc"
          uploads={@uploads}
          filename={@filename}
          placeholder={dgettext("eyra-assignment", "privacy_doc.placeholder")}
          select_button={dgettext("eyra-assignment", "privacy_doc.select.button")}
          replace_button={dgettext("eyra-assignment", "privacy_doc.replace.button")}
        />
        <%= if get_child(@fabric, :file_copy_view) do %>
          <.spacing value="S" />
          <.child name={:file_copy_view} fabric={@fabric} />
        <% end %>
      </div>
    """
  end
end
