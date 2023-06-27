defmodule Systems.DataDonation.DocumentTaskForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, ~w(.pdf)

  alias Systems.{
    DataDonation
  }

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_local_relative_path, local_full_path, remote_file}
      ) do
    socket
    |> save(entity, %{document_ref: local_full_path, document_name: remote_file})
  end

  @impl true
  def update(
        %{
          id: id,
          parent: parent,
          entity_id: entity_id
        },
        socket
      ) do
    placeholder = dgettext("eyra-data-donation", "pdf-select-placeholder")
    select_button = dgettext("eyra-data-donation", "pdf-select-file-button")
    replace_button = dgettext("eyra-data-donation", "pdf-replace-file-button")

    {
      :ok,
      socket
      |> assign(
        id: id,
        parent: parent,
        placeholder: placeholder,
        select_button: select_button,
        replace_button: replace_button,
        entity_id: entity_id
      )
      |> init_file_uploader(:pdf)
      |> update_entity()
    }
  end

  defp update_entity(%{assigns: %{entity_id: entity_id}} = socket) do
    entity = DataDonation.Public.get_document_task!(entity_id)
    assign(socket, entity: entity)
  end

  @impl true
  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  # Saving
  def save(socket, %DataDonation.DocumentTaskModel{} = entity, attrs) do
    changeset = DataDonation.DocumentTaskModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <Text.form_field_label id="document_ref_label"><%= @placeholder %></Text.form_field_label>
        <.spacing value="XXS" />
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @entity.document_name do %>
                <Text.body_large color="text-grey1"><%= @entity.document_name %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @entity.document_name do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.pdf.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.pdf.ref} />
            <% end %>
          </div>
          <%= live_file_input(@uploads.pdf, class: "hidden") %>
        </div>
      </.form>
    </div>
    """
  end
end
