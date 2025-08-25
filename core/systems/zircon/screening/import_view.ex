defmodule Systems.Zircon.Screening.ImportView do
  use CoreWeb, :embedded_live_view
  use CoreWeb.FileUploader, accept: ~w(.ris)

  import Frameworks.Pixel.FileSelector, only: [file_selector: 1]

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.LoadingSpinner
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

    # Clean up any existing reference files (abort active imports and archive uploaded files)
    Zircon.Public.cleanup_reference_files_for_new_upload!(tool)

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
    Logger.debug(
      "ImportView.update_file_selector: filename=#{inspect(filename)}, url=#{inspect(url)}"
    )

    # Get filename from view model - will be nil when no active file
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
    session = Paper.Public.get_import_session!(session_id)
    _updated_session = Paper.Public.commit_import_session!(session)

    {:noreply, socket}
  end

  def handle_event(
        "show_warnings",
        _params,
        %{assigns: %{vm: %{prompting_session_id: session_id, modal_warnings_title: title}}} =
          socket
      ) do
    # Load the full session object with preloads needed by the view
    session = Paper.Public.get_import_session!(session_id, reference_file: :file)
    filename = session.reference_file.file.name

    modal =
      LiveNest.Modal.prepare_live_view(
        "import-session-warnings",
        Systems.Zircon.Screening.ImportSessionErrorsView,
        session: [session: session, title: title, header: filename],
        style: :full
      )

    {:noreply, socket |> present_modal(modal)}
  end

  def handle_event(
        "show_new_papers",
        _params,
        %{assigns: %{vm: %{prompting_session_id: session_id, modal_new_papers_title: title}}} =
          socket
      ) do
    # Load the full session object with preloads needed by the view
    session = Paper.Public.get_import_session!(session_id, reference_file: :file)
    filename = session.reference_file.file.name

    modal =
      LiveNest.Modal.prepare_live_view(
        "import-session-new-papers",
        Systems.Zircon.Screening.ImportSessionPapersView,
        session: [session: session, title: title, header: filename, filter: "new"],
        style: :full
      )

    {:noreply, socket |> present_modal(modal)}
  end

  def handle_event(
        "show_duplicates",
        _params,
        %{assigns: %{vm: %{prompting_session_id: session_id, modal_duplicates_title: title}}} =
          socket
      ) do
    # Load the full session object with preloads needed by the view
    session = Paper.Public.get_import_session!(session_id, reference_file: :file)
    filename = session.reference_file.file.name

    modal =
      LiveNest.Modal.prepare_live_view(
        "import-session-duplicates",
        Systems.Zircon.Screening.ImportSessionPapersView,
        session: [session: session, title: title, header: filename, filter: "duplicates"],
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
        <div class="flex flex-row items-center gap-3">
          <Text.body>
            <%= @prompting_summary.summary_text %>
          </Text.body>
          <%= if length(@prompting_summary.summary_buttons) > 0 do %>
            <div class="flex flex-row gap-3">
              <Button.dynamic_bar buttons={@prompting_summary.summary_buttons} />
            </div>
          <% end %>
        </div>
        <%= if length(@prompting_summary.action_buttons) > 0 do %>
          <div class="flex flex-row gap-3">
            <Button.dynamic_bar buttons={@prompting_summary.action_buttons} />
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
        <Text.body>
          <%= @processing_status.message %>
        </Text.body>
        <%= if @processing_status[:progress] do %>
          <LoadingSpinner.progress_spinner progress={@processing_status.progress} size={20} />
        <% else %>
          <%= if @processing_status.show_spinner do %>
            <Frameworks.Pixel.Spinner.static color="primary" />
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
