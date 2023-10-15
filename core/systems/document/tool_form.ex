defmodule Systems.Document.ToolForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, ~w(.pdf)

  alias CoreWeb.Endpoint

  alias Systems.{
    Document
  }

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {local_relative_path, _local_full_path, remote_file}
      ) do
    ref = "#{Endpoint.url()}#{local_relative_path}"

    socket
    |> save(entity, %{ref: ref, name: remote_file})
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
      |> init_file_uploader(:pdf)
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
      <.form id={"#{@id}_document_tool_form"} for={%{}} phx-change="change" phx-target="" >
        <Text.form_field_label id="document_ref_label"><%= @label %></Text.form_field_label>
        <.spacing value="XXS" />
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @entity.name do %>
                <Text.body_large color="text-grey1"><%= @entity.name %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @entity.name do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.pdf.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.pdf.ref} />
            <% end %>
          </div>
          <div class="hidden">
            <.live_file_input upload={@uploads.pdf} />
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
