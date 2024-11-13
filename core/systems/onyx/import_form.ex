defmodule Systems.Onyx.ImportForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.ris)

  import Systems.Onyx.HTML, only: [import_history: 1]

  alias Systems.Onyx

  @impl true
  def process_file(%{assigns: %{tool: tool}} = socket, {_path, url, original_filename}) do
    Onyx.Public.insert_tool_file!(tool, original_filename, url)
    update_tool_files(socket)
  end

  @impl true
  def update(%{tool: tool, timezone: timezone}, socket) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        timezone: timezone,
        file: nil
      )
      |> init_file_uploader(:file)
      |> update_import_button()
      |> update_tool_files()
    }
  end

  def update_tool_files(%{assigns: %{tool: tool}} = socket) do
    socket
    |> assign(tool_files: Onyx.Public.list_tool_files(tool))
  end

  def update_import_button(%{assigns: %{uploads: uploads}} = socket) do
    socket
    |> assign(
      import_button: %{
        label: dgettext("eyra-onyx", "import_form.button"),
        field: uploads.file.ref
      }
    )
  end

  def handle_event("change", %{"_target" => ["file"]}, socket) do
    {:noreply, socket}
  end

  def handle_event("delete_tool_file", %{"item" => item_id}, socket) do
    Onyx.Public.delete_tool_file!(String.to_integer(item_id))
    {:noreply, socket |> update_tool_files()}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full">
        <Text.body>
          <%= dgettext("eyra-onyx", "papers_form.description") %>
        </Text.body>
        <.spacing value="M" />
        <.form id={"#{@id}_file_selector_form"} for={%{}} phx-change="change" phx-target="" >
          <div class="flex flex-row">
            <div class="hidden">
              <.live_file_input upload={@uploads.file} />
            </div>
            <div class="flex-wrap">
              <Button.primary_label {@import_button} />
            </div>
          </div>
        </.form>
        <%= if Enum.count(@tool_files) > 0 do %>
          <.spacing value="L" />
          <Text.title3>
            <%= dgettext("eyra-onyx", "import_history.title") %>
          </Text.title3>
          <.import_history tool_files={@tool_files} timezone={@timezone} />
        <% end %>
      </div>
    """
  end
end
