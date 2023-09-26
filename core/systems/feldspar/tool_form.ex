defmodule Systems.Feldspar.ToolForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, ~w(.zip)

  alias Systems.{
    Feldspar
  }

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_local_relative_path, local_full_path, remote_file}
      ) do
    socket
    |> save(entity, %{archive_ref: local_full_path, archive_name: remote_file})
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
    {:noreply, socket |> handle_upload_error()}
  end

  defp handle_upload_error(socket) do
    if has_upload_error(socket) do
      if has_upload_error(socket, :too_large) do
        Frameworks.Pixel.Flash.push_error(dgettext("eyra-feldspar", "zip-too-large"))
      else
        Frameworks.Pixel.Flash.push_error()
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
      <.form id="select_file_form" for={%{}} phx-change="change" phx-target="" >
        <Text.form_field_label id="archive_ref_label"><%= @label %></Text.form_field_label>
        <.spacing value="XXS" />
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @entity.archive_name do %>
                <Text.body_large color="text-grey1"><%= @entity.archive_name %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @entity.archive_name do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.file.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.file.ref} />
            <% end %>
          </div>
          <div class="hidden">
            <.live_file_input upload={@uploads.file} />
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
