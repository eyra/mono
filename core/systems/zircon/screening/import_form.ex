defmodule Systems.Zircon.Screening.ImportForm do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.ris)

  import Systems.Zircon.HTML, only: [import_history: 1]
  alias CoreWeb.UI.Timestamp

  alias Systems.Paper
  alias Systems.Zircon

  @impl true
  def file_upload_start(socket, {original_filename, _}) do
    socket
    |> create_reference_file(original_filename)
    |> update_reference_files()
    |> update_history_items()
  end

  @impl true
  def process_file(socket, %{public_url: public_url}) do
    socket
    |> update_reference_file(public_url)
    |> start_processing_reference_file()
    |> assign(reference_file: nil)
  end

  defp create_reference_file(%{assigns: %{tool: tool}} = socket, original_filename) do
    socket
    |> assign(reference_file: Zircon.Public.insert_reference_file!(tool, original_filename))
  end

  defp update_reference_file(%{assigns: %{reference_file: reference_file}} = socket, url) do
    reference_file = Paper.Public.update!(reference_file, url)
    socket |> assign(reference_file: reference_file)
  end

  defp start_processing_reference_file(%{assigns: %{reference_file: reference_file}} = socket) do
    Paper.Public.start_processing_reference_file(reference_file.id)
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
      |> update_reference_files()
      |> update_history_items()
    }
  end

  defp update_history_items(%{assigns: %{reference_files: reference_files}} = socket) do
    {history_items, paper_ids} =
      Enum.reduce(reference_files, {[], MapSet.new([])}, fn reference_file, acc ->
        history_item(socket, reference_file, acc)
      end)

    socket
    |> assign(history_items: history_items)
    |> send_event(:parent, "update_paper_count", %{paper_count: MapSet.size(paper_ids)})
  end

  defp history_item(
         %{assigns: %{timezone: timezone}},
         %Paper.ReferenceFileModel{
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
         %Paper.ReferenceFileModel{
           id: reference_file_id,
           file: %{name: name, inserted_at: inserted_at},
           papers: papers,
           errors: errors
         },
         {history_items, paper_ids}
       ) do
    associated_paper_ids =
      MapSet.new(Enum.to_list(Enum.map(papers, &Paper.Model.citation/1)))

    new_paper_ids = MapSet.difference(associated_paper_ids, paper_ids)

    error_count = Enum.count(errors)
    all_count = Enum.count(papers)
    new_count = Enum.count(new_paper_ids)
    duplicate_count = all_count - new_count

    timestamp =
      inserted_at
      |> Timestamp.apply_timezone(timezone)
      |> Timestamp.format!()

    archive_button = %{
      action: %{type: :send, event: "archive_reference_file", item: reference_file_id},
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

  def update_reference_files(%{assigns: %{tool: tool}} = socket) do
    reference_files = Zircon.Public.list_reference_files(tool)
    assign(socket, reference_files: reference_files)
  end

  def update_import_button(%{assigns: %{uploads: uploads}} = socket) do
    socket
    |> assign(
      import_button: %{
        action: %{type: :label, field: uploads.file.ref},
        face: %{type: :primary, label: dgettext("eyra-zircon", "import_form.button")}
      }
    )
  end

  def handle_event("change", %{"_target" => ["file"]}, socket) do
    {:noreply, socket}
  end

  def handle_event("archive_reference_file", %{"item" => reference_file_id}, socket) do
    Paper.Public.archive_reference_file!(String.to_integer(reference_file_id))

    {
      :noreply,
      socket
      |> update_reference_files()
      |> update_history_items()
    }
  end

  def handle_event("process_reference_file", %{"item" => _reference_file_id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full">
        <Text.body>
          <%= dgettext("eyra-zircon", "papers_form.description") %>
        </Text.body>
        <.spacing value="M" />
        <.form id={"#{@id}_file_selector_form"} for={%{}} phx-change="change" phx-target="" >
          <div class="flex flex-row">
            <div class="hidden">
              <.live_file_input upload={@uploads.file} />
            </div>
            <div class="flex-wrap">
              <Button.dynamic {@import_button} />
            </div>
          </div>
        </.form>
        <%= if Enum.count(@reference_files) > 0 do %>
          <.spacing value="L" />
          <Text.title3>
            <%= dgettext("eyra-zircon", "import_history.title") %>
          </Text.title3>
          <.import_history items={@history_items} />
        <% end %>
      </div>
    """
  end
end
