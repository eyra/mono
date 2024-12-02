defmodule Systems.Onyx.ImportForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.ris)

  import Systems.Onyx.HTML, only: [import_history: 1]
  alias CoreWeb.UI.Timestamp
  alias Systems.Onyx

  @impl true
  def file_upload_start(socket, {original_filename, _}) do
    socket
    |> create_tool_file(original_filename)
    |> update_tool_files()
    |> update_history_items()
  end

  @impl true
  def process_file(socket, {_path, url, _original_filename}) do
    socket
    |> update_tool_file(url)
    |> start_processing_tool_file()
    |> assign(tool_file: nil)
  end

  defp create_tool_file(%{assigns: %{tool: tool}} = socket, original_filename) do
    socket |> assign(tool_file: Onyx.Public.insert_tool_file!(tool, original_filename, nil))
  end

  defp update_tool_file(%{assigns: %{tool_file: tool_file}} = socket, url) do
    tool_file = Onyx.Public.update_tool_file!(tool_file, url)
    socket |> assign(tool_file: tool_file)
  end

  defp start_processing_tool_file(%{assigns: %{tool_file: tool_file}} = socket) do
    Onyx.Private.start_processing_ris_file(tool_file.id)
    socket
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
      |> update_history_items()
    }
  end

  defp update_history_items(%{assigns: %{tool_files: tool_files}} = socket) do
    {history_items, paper_ids} =
      Enum.reduce(tool_files, {[], MapSet.new([])}, fn tool_file, acc ->
        history_item(socket, tool_file, acc)
      end)

    socket
    |> assign(history_items: history_items)
    |> send_event(:parent, "update_paper_count", %{paper_count: MapSet.size(paper_ids)})
  end

  defp history_item(
         %{assigns: %{timezone: timezone}},
         %Onyx.ToolFileAssociation{
           status: :uploaded,
           file: %{name: name, inserted_at: inserted_at}
         },
         {history_items, paper_ids}
       ) do
    timestamp =
      inserted_at
      |> Timestamp.apply_timezone(timezone)
      |> Timestamp.format!()

    history_item = [timestamp, name <> "", "-", "-", "-", "-", :spinner_static]
    {history_items ++ [history_item], paper_ids}
  end

  defp history_item(
         %{assigns: %{timezone: timezone}},
         %Onyx.ToolFileAssociation{
           id: tool_file_id,
           file: %{name: name, inserted_at: inserted_at},
           associated_papers: associated_papers,
           associated_errors: associated_errors
         },
         {history_items, paper_ids}
       ) do
    associated_paper_ids =
      MapSet.new(Enum.to_list(Enum.map(associated_papers, &Onyx.PaperModel.citation(&1.paper))))

    new_paper_ids = MapSet.difference(associated_paper_ids, paper_ids)

    error_count = Enum.count(associated_errors)
    all_count = Enum.count(associated_papers)
    new_count = Enum.count(new_paper_ids)
    duplicate_count = all_count - new_count

    timestamp =
      inserted_at
      |> Timestamp.apply_timezone(timezone)
      |> Timestamp.format!()

    archive_button = %{
      action: %{type: :send, event: "archive_tool_file", item: tool_file_id},
      face: %{
        type: :icon,
        icon: :delete,
        color: :red
      }
    }

    history_item = [
      timestamp,
      name,
      error_count,
      all_count,
      duplicate_count,
      new_count,
      archive_button
    ]

    {history_items ++ [history_item], MapSet.union(paper_ids, new_paper_ids)}
  end

  def update_tool_files(%{assigns: %{tool: tool}} = socket) do
    assign(socket, tool_files: Onyx.Public.list_tool_files(tool))
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

  def handle_event("archive_tool_file", %{"item" => tool_file_id}, socket) do
    Onyx.Public.archive_tool_file!(String.to_integer(tool_file_id))

    {
      :noreply,
      socket
      |> update_tool_files()
      |> update_history_items()
    }
  end

  def handle_event("process_tool_file", %{"item" => _tool_file_id}, socket) do
    {:noreply, socket}
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
          <.import_history items={@history_items} />
        <% end %>
      </div>
    """
  end
end
