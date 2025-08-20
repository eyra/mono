defmodule Systems.Zircon.Screening.ImportView do
  use CoreWeb, :embedded_live_view
  use CoreWeb.FileUploader, accept: ~w(.ris)

  import Frameworks.Pixel.FileSelector, only: [file_selector: 1]
  import Phoenix.HTML, only: [raw: 1]

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Systems.Paper
  alias Systems.Zircon

  @impl true
  def file_upload_start(socket, {original_filename, _}) do
    Logger.info("File upload started: #{original_filename}")
    socket |> update_view_model()
  end

  @impl true
  def process_file(%{assigns: %{model: tool}} = socket, %{
        public_url: url,
        original_filename: filename
      }) do
    Logger.info("File uploaded: #{filename} at #{url}")

    # Check if there's an active import session and abort it before creating new file
    reference_files = Zircon.Public.list_reference_files(tool)

    Enum.each(reference_files, &abort_active_import_if_exists/1)

    # Create reference file immediately when file is uploaded so it persists across page refreshes
    _reference_file = Zircon.Public.insert_reference_file!(tool, filename, url)

    socket
    |> assign(filename: filename, url: url)
    |> update_view_model()
  end

  def get_model(:not_mounted_at_router, %{"tool" => tool}, _socket) do
    tool
  end

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"title" => title},
        socket
      ) do
    {
      :ok,
      socket
      |> init_file_uploader(:file)
      |> assign(title: title, paper_page_number: 0)
      |> update_file_selector()
    }
  end

  defp update_file_selector(
         %{assigns: %{vm: %{active_filename: filename, active_file_url: url}}} = socket
       ) do
    # Get initial filename from unprocessed reference files via existing view model
    socket
    |> assign(filename: filename, url: url)
  end

  def handle_view_model_updated(socket) do
    Logger.info("ImportView: handle_view_model_updated called - UI should update now")
    Logger.info("ImportView: PID receiving update: #{inspect(self())}")
    Logger.info("ImportView: Current model ID: #{socket.assigns.model.id}")

    # Just restore file selector state, the Observatory framework will handle the view model update
    # ViewBuilder determines the correct filename based on active session or latest uploaded file
    update_file_selector(socket)
  end

  defp abort_active_import_if_exists(ref_file) do
    if Paper.Public.has_active_import_for_reference_file?(ref_file.id) do
      Logger.info(
        "Aborting active import session for reference file #{ref_file.id} due to file replacement"
      )

      active_session = Paper.Public.get_active_import_session_for_reference_file(ref_file.id)

      if active_session do
        Paper.Public.abort_import_session!(active_session)
      end
    end
  end

  @impl true
  def handle_event("change", %{"_target" => ["file"]}, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "prepare_import",
        _params,
        %{assigns: %{model: %{id: tool_id} = tool, filename: filename}} = socket
      ) do
    paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool_id)

    # Find the uploaded reference file (created during file upload)
    reference_files = Zircon.Public.list_reference_files(tool)

    reference_file =
      reference_files
      |> Enum.find(fn ref_file ->
        ref_file.status == :uploaded and
          ref_file.file.name == filename
      end)

    case reference_file do
      nil ->
        # Fallback: create reference file if not found (shouldn't happen normally)
        Logger.warning("Reference file not found for #{filename}, creating new one")
        reference_file = Zircon.Public.insert_reference_file!(tool, filename)
        _import_session = Paper.Public.prepare_import_session!(reference_file, paper_set)

      reference_file ->
        # Use existing reference file
        _import_session = Paper.Public.prepare_import_session!(reference_file, paper_set)
    end

    # The view will be automatically updated via signals and ViewBuilder
    {:noreply, socket}
  end

  def handle_event(
        "commit_import",
        _params,
        %{assigns: %{vm: %{prompting_session_id: session_id}}} = socket
      ) do
    Logger.info("ImportView: commit_import clicked for session #{session_id}")
    Logger.info("ImportView: Socket PID: #{inspect(self())}")

    session = Paper.Public.get_import_session!(session_id)

    Logger.info(
      "ImportView: Retrieved session: #{inspect(Map.take(session, [:id, :phase, :status, :reference_file_id]))}"
    )

    Logger.info("ImportView: BEFORE commit_import_session! (blocking call)")
    updated_session = Paper.Public.commit_import_session!(session)
    Logger.info("ImportView: AFTER commit_import_session! - session completed")

    Logger.info(
      "ImportView: Updated session: #{inspect(Map.take(updated_session, [:id, :phase, :status]))}"
    )

    {:noreply, socket}
  end

  def handle_event(
        "show_details",
        _params,
        %{assigns: %{vm: %{prompting_session_id: session_id, modal_title: modal_title}}} = socket
      ) do
    # LiveNest expects a keyword list for session, which gets converted to string keys
    modal =
      LiveNest.Modal.prepare_live_view(
        "import-session-details",
        Systems.Zircon.Screening.ImportSessionView,
        session: [session_id: session_id, title: modal_title],
        style: :full
      )

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div data-testid="import-view">
        <Area.content>
          <Margin.y id={:page_top} />
          <div class="flex flex-col gap-8">
            <%= for {block_type, opts} <- @vm.stack do %>
              <%= render_block(block_type, assign(assigns, block_type, opts)) %>
            <% end %>
          </div>
        </Area.content>
      </div>
    """
  end

  # Block render functions

  def render_block(:header, assigns) do
    ~H"""
    <div data-testid="header-block">
      <div class="flex flex-row justify-between">
        <div>
          <div data-testid="import-title">
            <Text.title2 margin="none">
              <%= @header.title %>
              <span class="text-primary" data-testid="paper-count"><%= @header.paper_count %></span>
            </Text.title2>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render_block(:content, assigns) do
    ~H"""
    <div class="flex flex-col gap-8" data-testid="content-block">
      <div data-testid="paper-set-view">
        <LiveNest.HTML.element {Map.from_struct(@content.paper_set_view)} socket={@socket} />
      </div>
    </div>
    """
  end

  def render_block(:import_section, assigns) do
    ~H"""
    <div class="bg-grey6 rounded-md p-6" data-testid="import-section-block">
      <div class="flex flex-col gap-8">
        <%= for {block_type, opts} <- @import_section.stack do %>
          <%= render_block(block_type, assign(assigns, block_type, opts)) %>
        <% end %>
      </div>
    </div>
    """
  end

  def render_block(:import_file_selector, assigns) do
    ~H"""
    <div data-testid="import-file-selector-block">
      <div data-testid="file-selector">
        <.file_selector
          id="ris_file"
          uploads={@uploads}
          filename={@filename}
          placeholder={@import_file_selector.placeholder}
          select_button={@import_file_selector.select_button}
          replace_button={@import_file_selector.replace_button}
          background_color="bg-white"
        />
      </div>
    </div>
    """
  end

  def render_block(:import_buttons, assigns) do
    ~H"""
    <div class="flex flex-row gap-3" data-testid="import-buttons-block">
      <Button.dynamic action={%{type: :send, event: "prepare_import"}} face={@import_buttons.import_button_face} enabled?={@import_buttons.import_button_enabled} />
    </div>
    """
  end

  def render_block(:prompting_summary, assigns) do
    ~H"""
    <div data-testid="prompting-summary-block">
      <div class="flex flex-col gap-8">
        <div class="flex flex-row items-center">
          <div>
            <Text.body>
              <%= raw(@prompting_summary.message) %>
            </Text.body>
          </div>
          <%= if @prompting_summary.details_button do %>
            <div class="ml-4">
              <Button.dynamic {@prompting_summary.details_button} />
            </div>
          <% end %>
        </div>
        <%= if length(@prompting_summary.buttons) > 0 do %>
          <div class="flex flex-row gap-3">
            <Button.dynamic_bar buttons={@prompting_summary.buttons} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render_block(:processing_status, assigns) do
    ~H"""
    <div data-testid="processing-status-block">
      <div class="flex flex-row items-center gap-3">
        <%= if @processing_status.show_spinner do %>
          <Frameworks.Pixel.Spinner.static color="primary" />
        <% end %>
        <Text.body>
          <%= @processing_status.message %>
        </Text.body>
      </div>
    </div>
    """
  end
end
